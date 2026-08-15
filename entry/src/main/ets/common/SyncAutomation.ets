/**
 * 同步自动化组件 —— 对应 Android 参考实现 MainActivity 中的 WebView 自动化
 * 使用 Web 组件加载校方门户（SSO），通过 runJavaScript 注入 auto_collect.js，
 * 轮询结果并回调给业务层。
 * 说明：该自动化仅在用户本人凭据登录的用户本人学校门户会话内，
 *       提取用户本人的课表/成绩/电费数据，数据仅回传本机。
 */
import { webview } from '@kit.ArkWeb';
import { BusinessError } from '@kit.BasicServicesKit';
import { util } from '@kit.ArkTS';
import { DataStore, GradeItemData } from './DataStore';
import { CredentialCrypto } from './CredentialCrypto';
import { SyncAutomationBridge, SyncNotifier, SyncScheduler } from './SyncService';
import { ScheduleImport, RawSemester } from '../model/ScheduleImport';

export const EDUCATION_SSO = 'https://jwxt.nwpu.edu.cn/student/sso-login';
export const ELECTRICITY_HOME = 'https://yktapp.nwpu.edu.cn/plat/shouyeUser';
export const ELECTRICITY_SSO = 'https://yktapp.nwpu.edu.cn/berserker-auth/cas/login/supwisdom?targetUrl=https%3A%2F%2Fyktapp.nwpu.edu.cn%2Fplat';

export interface GradeRowJson {
  name: string;
  credits: number;
  score: number;
  semester: string;
}

@Component
export struct SyncAutomation {
  controller: webview.WebviewController = new webview.WebviewController();
  @State target: string = 'education';
  @State active: boolean = false;
  @State statusText: string = '';
  private autoCollectScript: string = '';
  private generation: number = 0;
  private attempts: number = 0;
  private lastNavigationTime: number = 0;
  private pollTimer: number = -1;

  aboutToAppear(): void {
    // 从 rawfile 加载脚本
    const context = this.getUIContext().getHostContext();
    if (context !== null && context !== undefined) {
      try {
        const mgr = context.resourceManager;
        const bytes: Uint8Array = mgr.getRawFileContentSync('auto_collect.js');
        this.autoCollectScript = new util.TextDecoder('utf-8').decodeToString(bytes);
      } catch (e) {
        this.autoCollectScript = '';
      }
    }
    SyncAutomationBridge.get().registerListener(() => {
      if (SyncAutomationBridge.get().state() === 'starting') {
        this.startSync();
      }
    });
  }

  aboutToDisappear(): void {
    this.stopPolling();
  }

  private startSync(): void {
    if (this.active) {
      return;
    }
    SyncAutomationBridge.get().consumePending();
    if (!DataStore.get().hasCredentials()) {
      SyncAutomationBridge.get().setState('idle');
      return;
    }
    this.active = true;
    this.attempts = 0;
    this.generation++;
    this.target = 'education';
    this.setStatus('正在加载教务门户…');
    this.controller.loadUrl(EDUCATION_SSO);
  }

  private startElectricity(): void {
    this.target = 'electricity';
    this.setStatus('正在加载一卡通门户…');
    this.controller.loadUrl(ELECTRICITY_SSO);
  }

  private setStatus(text: string): void {
    this.statusText = text;
    SyncAutomationBridge.get().setState(text);
  }

  private onPageFinished(): void {
    if (!this.active) {
      return;
    }
    const now = Date.now();
    if (now - this.lastNavigationTime < 1500) {
      return;
    }
    this.lastNavigationTime = now;
    this.runCollector();
  }

  private runCollector(): void {
    this.attempts++;
    if (this.attempts > 120) {
      this.setStatus('同步超时，请重试');
      this.finish();
      return;
    }
    CredentialCrypto.decrypt(DataStore.get().getPasswordEncrypted()).then((password: string) => {
      const username = DataStore.get().getUsername();
      const canAutofill = DataStore.get().getAutofillEnabled() && username !== '' && password !== '';
      const canFillSms = username !== '';
      const mode = this.target;
      const script = this.autoCollectScript
        .replace('__ALLOW_NAV__', 'true')
        .replace('__USERNAME__', this.jsString(username))
        .replace('__PASSWORD__', this.jsString(password))
        .replace('__SMS_CODE__', this.jsString(''))
        .replace('__CAN_AUTOFILL__', canAutofill ? 'true' : 'false')
        .replace('__CAN_FILL_SMS__', canFillSms ? 'true' : 'false')
        .replace('__MODE__', this.jsString(mode));
      try {
        this.controller.runJavaScript(script, (error: BusinessError, result: string) => {
          if (error !== null && error !== undefined) {
            this.poll();
            return;
          }
          this.handleResult(result);
        });
      } catch (e) {
        this.poll();
      }
    });
  }

  private poll(): void {
    if (this.pollTimer >= 0) {
      clearTimeout(this.pollTimer);
    }
    this.pollTimer = setTimeout(() => {
      this.runCollector();
    }, 2000);
  }

  private handleResult(result: string): void {
    if (result === null || result === undefined || result === '') {
      this.poll();
      return;
    }
    let phase = '';
    let payload: Record<string, Object> = {};
    try {
      const root = JSON.parse(result) as Record<string, Object>;
      phase = String(root['phase'] ?? '');
      const p = root['payload'];
      payload = p === undefined || p === null ? {} : (p as Record<string, Object>);
    } catch (e) {
      this.poll();
      return;
    }

    if (phase === 'credentials_error') {
      this.setStatus('账号或密码错误，请检查后重试');
      this.finish();
      return;
    }
    if (phase === 'credentials_required') {
      this.setStatus('请在登录页输入账号密码');
      this.poll();
      return;
    }
    if (phase === 'sms_required') {
      this.setStatus('需要短信验证码，请在页面中完成验证');
      this.poll();
      return;
    }
    if (phase === 'clicked' || phase === 'page' || phase === 'waiting') {
      this.poll();
      return;
    }
    if (phase === 'data') {
      if (this.target === 'education') {
        this.handleScheduleData(payload);
      }
      return;
    }
    if (phase === 'electricity_data') {
      this.handleElectricityData(payload);
      return;
    }
    this.poll();
  }

  private handleScheduleData(payload: Record<string, Object>): void {
    this.setStatus('正在解析课表…');
    const parsed = ScheduleImport.parsePayload(JSON.stringify({ data: payload }));
    if (parsed.semesters.length === 0 && parsed.courses.length === 0) {
      const rows = payload['rows'];
      if (rows !== null && rows !== undefined && rows instanceof Array) {
        this.handleGradeRows(rows as Array<Object>);
        return;
      }
      this.setStatus('未获取到课表数据');
      this.finish();
      return;
    }
    // 存储学期与课程
    const semesterId = `semester-${Date.now()}`;
    const dataSemester = parsed.semesters.length > 0 ? parsed.semesters[0].dataSemester : null;
    const semesterName = parsed.semesters.length > 0 ? parsed.semesters[0].name : '同步学期';
    const courses = ScheduleImport.convertToCourses(parsed.courses, semesterId, dataSemester);
    if (courses.length === 0) {
      this.setStatus('课表解析为空');
      this.finish();
      return;
    }
    const rawSemester = parsed.semesters.length > 0 ? parsed.semesters[0] :
      new RawSemester(semesterName, '');
    const imported = ScheduleImport.createImportedSemester(rawSemester, courses);
    const semesters = DataStore.get().getSemesters();
    semesters.push(imported);
    DataStore.get().setSemesters(semesters);
    DataStore.get().setSelectedSemesterId(imported.id);
    DataStore.get().setCourses(courses);
    SyncScheduler.get().recordSyncTime();
    this.setStatus('课表同步完成');
    this.finish();
    // 通知（课表变更）
    SyncNotifier.notifySyncResult([], false);
    // 同步完成后尝试电费
    this.startElectricity();
  }

  private handleGradeRows(rows: Array<Object>): void {
    const items: Array<GradeItemData> = [];
    for (const row of rows) {
      const obj = row as Record<string, Object>;
      const name = String(obj['name'] ?? '');
      const credits = Number(obj['credits'] ?? 0);
      const score = Number(obj['score'] ?? 0);
      const semester = String(obj['semester'] ?? '');
      if (name !== '') {
        items.push(new GradeItemData(name, credits, score, semester));
      }
    }
    if (items.length > 0) {
      const old = DataStore.get().getGradeItems();
      const newItems = old.concat(items);
      DataStore.get().setGradeItems(newItems);
      SyncScheduler.get().recordSyncTime();
      SyncNotifier.notifySyncResult([], true);
    }
    this.setStatus('成绩同步完成');
    this.finish();
  }

  private handleElectricityData(payload: Record<string, Object>): void {
    const balance = payload['balance'];
    if (balance !== undefined && balance !== null) {
      const text = `${Number(balance).toFixed(2)}`;
      DataStore.get().setElectricityBalance(text);
      const threshold = DataStore.get().getElectricityThreshold();
      if (DataStore.get().getElectricityReminderEnabled() && Number(balance) <= threshold) {
        SyncNotifier.notifyElectricityLow(text);
      }
      this.setStatus(`电费余额 ${text} 元`);
    } else {
      this.setStatus('电费数据获取失败');
    }
    this.finish();
  }

  private finish(): void {
    this.active = false;
    this.stopPolling();
    setTimeout(() => {
      if (!this.active) {
        SyncAutomationBridge.get().setState('idle');
      }
    }, 1500);
  }

  private stopPolling(): void {
    if (this.pollTimer >= 0) {
      clearTimeout(this.pollTimer);
      this.pollTimer = -1;
    }
  }

  private jsString(value: string): string {
    return `"${value.replace(/\\/g, '\\\\').replace(/"/g, '\\"')}"`;
  }

  build() {
    Web({ src: 'about:blank', controller: this.controller })
      .javaScriptAccess(true)
      .domStorageAccess(true)
      .fileAccess(true)
      .width('0%')
      .height('0%')
      .position({ x: -100, y: -100 })
      .onPageEnd(() => {
        this.onPageFinished();
      })
      .onErrorReceive(() => {
        if (this.active) {
          this.setStatus('页面加载失败，请检查网络');
          this.finish();
        }
      })
  }
}
