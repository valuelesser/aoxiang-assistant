/**
 * 同步服务 —— 对应 Android 参考实现 SyncService
 * 职责：
 *   1. 定时同步调度（reminderAgentManager 代理提醒）
 *   2. 变更通知（notificationManager）
 *   3. 同步状态管理（SyncScheduler 供页面/能力调用）
 * 说明：Web 自动化同步实际由 SyncAutomation 组件（含 Web 组件）执行，
 *       本服务负责调度、状态记录与结果回调。
 */
import { common } from '@kit.AbilityKit';
import { reminderAgentManager } from '@kit.BackgroundTasksKit';
import { notificationManager } from '@kit.NotificationKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { DataStore } from './DataStore';
import { UpdateDiff, UpdateDiffItem } from '../model/UpdateDiff';

export class SyncScheduler {
  private static instance: SyncScheduler | null = null;

  static get(): SyncScheduler {
    if (SyncScheduler.instance === null) {
      SyncScheduler.instance = new SyncScheduler();
    }
    return SyncScheduler.instance;
  }

  /** 注册/更新定时同步（intervalMinutes <= 0 表示关闭） */
  schedule(context: common.UIAbilityContext | common.Context | undefined, enabled: boolean,
    intervalMinutes: number): void {
    if (context === undefined) {
      return;
    }
    reminderAgentManager.cancelAllReminders().then(() => {
      if (!enabled || intervalMinutes <= 0) {
        return;
      }
      const seconds = intervalMinutes * 60;
      const timer: reminderAgentManager.ReminderRequestTimer = {
        reminderType: reminderAgentManager.ReminderType.REMINDER_TYPE_TIMER,
        triggerTimeInSeconds: seconds,
        title: '翱翔助手',
        content: '到时间同步课表/成绩了',
        notificationId: 1001
      };
      reminderAgentManager.publishReminder(timer).then(() => {
        // 注册成功
      }).catch((err: BusinessError) => {
        // 权限未授予等场景下静默失败
      });
    }).catch((err: BusinessError) => {
      // ignore
    });
  }

  /** 立即同步：通过回调返回状态（实际自动化由 UI 层 SyncAutomation 执行） */
  syncNow(context: common.Context | undefined, callback: (message: string) => void): void {
    if (context === undefined) {
      callback('无法获取上下文');
      return;
    }
    // 触发页面内 SyncAutomation 组件执行（由页面注册回调）
    const state = SyncAutomationBridge.get().state();
    if (state === 'idle') {
      callback('同步已在后台开始，请稍候');
      SyncAutomationBridge.get().requestStart(context);
    } else {
      callback(`同步正在进行（${state}）`);
    }
  }

  /** 记录同步时间 */
  recordSyncTime(): void {
    const now = new Date();
    const text = `${now.getFullYear()}-${this.pad2(now.getMonth() + 1)}-${this.pad2(now.getDate())} ` +
      `${this.pad2(now.getHours())}:${this.pad2(now.getMinutes())}`;
    DataStore.get().setSyncLastTime(text);
  }

  private pad2(value: number): string {
    return value < 10 ? `0${value}` : `${value}`;
  }
}

/**
 * 同步自动化桥：协调 UI 层的 SyncAutomation 组件与业务层的 SyncScheduler。
 * 页面（Index）在 build 中挂载 SyncAutomation（Web 组件隐藏置于页面内），
 * 其 controller 通过本桥启动/汇报状态。
 */
export class SyncAutomationBridge {
  private static instance: SyncAutomationBridge | null = null;
  private currentState: string = 'idle';
  private pendingContext: common.Context | null = null;
  private onStateChange: (() => void) | null = null;

  static get(): SyncAutomationBridge {
    if (SyncAutomationBridge.instance === null) {
      SyncAutomationBridge.instance = new SyncAutomationBridge();
    }
    return SyncAutomationBridge.instance;
  }

  state(): string {
    return this.currentState;
  }

  setState(state: string): void {
    this.currentState = state;
    if (this.onStateChange !== null) {
      this.onStateChange();
    }
  }

  registerListener(listener: () => void): void {
    this.onStateChange = listener;
  }

  requestStart(context: common.Context): void {
    this.pendingContext = context;
    this.setState('starting');
  }

  consumePending(): common.Context | null {
    const ctx = this.pendingContext;
    this.pendingContext = null;
    return ctx;
  }
}

/** 变更通知辅助（对应 Android 版同步完成后的系统通知） */
export class SyncNotifier {
  static async notifySyncResult(courseNames: Array<string>, grades: boolean): Promise<void> {
    try {
      const enabled = DataStore.get().getNotifyEnabled();
      if (!enabled) {
        return;
      }
      const title = '翱翔助手';
      const content = UpdateDiff.notificationText(courseNames, grades);
      const request: notificationManager.NotificationRequest = {
        id: 1002,
        content: {
          notificationContentType: notificationManager.ContentType.NOTIFICATION_CONTENT_BASIC_TEXT,
          normal: {
            title: title,
            text: content
          }
        }
      };
      await notificationManager.publish(request);
    } catch (e) {
      // 通知发布失败不影响主流程
    }
  }

  static async notifyElectricityLow(balance: string): Promise<void> {
    try {
      const request: notificationManager.NotificationRequest = {
        id: 1003,
        content: {
          notificationContentType: notificationManager.ContentType.NOTIFICATION_CONTENT_BASIC_TEXT,
          normal: {
            title: '电费提醒',
            text: `宿舍电费余额 ${balance} 元，请及时充值`
          }
        }
      };
      await notificationManager.publish(request);
    } catch (e) {
      // ignore
    }
  }
}

/** 供 UI 层使用的同步结果解析：基于 UpdateDiff 生成通知文案 */
export function buildUpdateNotification(before: Array<UpdateDiffItem>, after: Array<UpdateDiffItem>,
  grades: boolean): string {
  const names = UpdateDiff.changedNames(before, after);
  return UpdateDiff.notificationText(names, grades);
}
