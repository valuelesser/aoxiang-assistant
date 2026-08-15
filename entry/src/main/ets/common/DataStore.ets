/**
 * 全局数据仓库（单例）
 * - 负责在启动时从 ScheduleStorage 加载全部数据并写入 AppStorage
 * - 提供 getter/setter，任何修改立即持久化
 * - 页面通过 @StorageLink('xxx') 与 AppStorage 双向绑定
 */
import { common } from '@kit.AbilityKit';
import { ScheduleModels } from '../model/ScheduleModels';
import { ScheduleStorage } from '../model/ScheduleStorage';

export class DataStore {
  static readonly KEY_SEMESTERS = 'semesters';
  static readonly KEY_COURSES = 'courses';
  static readonly KEY_SELECTED_SEMESTER = 'selectedSemesterId';
  static readonly KEY_THEME_COLOR = 'themeColor';
  static readonly KEY_DARK_MODE = 'darkMode';
  static readonly KEY_SYNC_ENABLED = 'syncEnabled';
  static readonly KEY_SYNC_INTERVAL = 'syncIntervalMinutes';
  static readonly KEY_SYNC_LAST_TIME = 'syncLastTime';
  static readonly KEY_NOTIFY_ENABLED = 'notifyEnabled';
  static readonly KEY_ELECTRICITY_REMINDER = 'electricityReminderEnabled';
  static readonly KEY_ELECTRICITY_THRESHOLD = 'electricityThreshold';
  static readonly KEY_USERNAME = 'username';
  static readonly KEY_PASSWORD_ENCRYPTED = 'passwordEncrypted';
  static readonly KEY_AUTOFILL_ENABLED = 'autofillEnabled';
  static readonly KEY_GRADES = 'grades';
  static readonly KEY_ELECTRICITY = 'electricityBalance';
  static readonly KEY_SCHOOL_ID = 'schoolId';

  private static instance: DataStore | null = null;
  private storage: ScheduleStorage = ScheduleStorage.get();
  private context: common.UIAbilityContext | null = null;

  static get(): DataStore {
    if (DataStore.instance === null) {
      DataStore.instance = new DataStore();
    }
    return DataStore.instance;
  }

  async init(context: common.UIAbilityContext): Promise<void> {
    this.context = context;
    await this.storage.init(context);
    const semesters = await this.storage.loadSemesters();
    const courses = await this.storage.loadCourses();
    let selectedId = await this.storage.loadSelectedSemesterId();
    if (selectedId === '' && semesters.length > 0) {
      selectedId = semesters[0].id;
    }
    const themeColor = await this.storage.loadThemeColor();
    const darkMode = await this.storage.loadDarkMode();
    const syncEnabled = await this.storage.getBoolean(DataStore.KEY_SYNC_ENABLED, false);
    const syncInterval = await this.storage.getNumber(DataStore.KEY_SYNC_INTERVAL, 720);
    const syncLastTime = await this.storage.getString(DataStore.KEY_SYNC_LAST_TIME, '');
    const notifyEnabled = await this.storage.getBoolean(DataStore.KEY_NOTIFY_ENABLED, true);
    const electricityReminder = await this.storage.getBoolean(DataStore.KEY_ELECTRICITY_REMINDER, true);
    const electricityThreshold = await this.storage.getNumber(DataStore.KEY_ELECTRICITY_THRESHOLD, 10);
    const username = await this.storage.getString(DataStore.KEY_USERNAME, '');
    const passwordEncrypted = await this.storage.getString(DataStore.KEY_PASSWORD_ENCRYPTED, '');
    const autofillEnabled = await this.storage.getBoolean(DataStore.KEY_AUTOFILL_ENABLED, false);
    const grades = await this.storage.getString(DataStore.KEY_GRADES, '[]');
    const electricity = await this.storage.getString(DataStore.KEY_ELECTRICITY, '');
    const schoolId = await this.storage.getString(DataStore.KEY_SCHOOL_ID, '');

    AppStorage.setOrCreate(DataStore.KEY_SEMESTERS, semesters);
    AppStorage.setOrCreate(DataStore.KEY_COURSES, courses);
    AppStorage.setOrCreate(DataStore.KEY_SELECTED_SEMESTER, selectedId);
    AppStorage.setOrCreate(DataStore.KEY_THEME_COLOR, themeColor);
    AppStorage.setOrCreate(DataStore.KEY_DARK_MODE, darkMode);
    AppStorage.setOrCreate(DataStore.KEY_SYNC_ENABLED, syncEnabled);
    AppStorage.setOrCreate(DataStore.KEY_SYNC_INTERVAL, syncInterval);
    AppStorage.setOrCreate(DataStore.KEY_SYNC_LAST_TIME, syncLastTime);
    AppStorage.setOrCreate(DataStore.KEY_NOTIFY_ENABLED, notifyEnabled);
    AppStorage.setOrCreate(DataStore.KEY_ELECTRICITY_REMINDER, electricityReminder);
    AppStorage.setOrCreate(DataStore.KEY_ELECTRICITY_THRESHOLD, electricityThreshold);
    AppStorage.setOrCreate(DataStore.KEY_USERNAME, username);
    AppStorage.setOrCreate(DataStore.KEY_PASSWORD_ENCRYPTED, passwordEncrypted);
    AppStorage.setOrCreate(DataStore.KEY_AUTOFILL_ENABLED, autofillEnabled);
    AppStorage.setOrCreate(DataStore.KEY_GRADES, grades);
    AppStorage.setOrCreate(DataStore.KEY_ELECTRICITY, electricity);
    AppStorage.setOrCreate(DataStore.KEY_SCHOOL_ID, schoolId);
  }

  // ---- 学期 ----
  getSemesters(): Array<ScheduleModels.Semester> {
    return AppStorage.get<Array<ScheduleModels.Semester>>(DataStore.KEY_SEMESTERS) ?? [];
  }

  setSemesters(semesters: Array<ScheduleModels.Semester>): void {
    AppStorage.setOrCreate<Array<ScheduleModels.Semester>>(DataStore.KEY_SEMESTERS, semesters);
    this.storage.saveSemesters(semesters);
  }

  // ---- 课程 ----
  getCourses(): Array<ScheduleModels.Course> {
    return AppStorage.get<Array<ScheduleModels.Course>>(DataStore.KEY_COURSES) ?? [];
  }

  setCourses(courses: Array<ScheduleModels.Course>): void {
    AppStorage.setOrCreate<Array<ScheduleModels.Course>>(DataStore.KEY_COURSES, courses);
    this.storage.saveCourses(courses);
  }

  // ---- 选中学期 ----
  getSelectedSemesterId(): string {
    return AppStorage.get<string>(DataStore.KEY_SELECTED_SEMESTER) ?? '';
  }

  setSelectedSemesterId(id: string): void {
    AppStorage.setOrCreate<string>(DataStore.KEY_SELECTED_SEMESTER, id);
    this.storage.saveSelectedSemesterId(id);
  }

  getSelectedSemester(): ScheduleModels.Semester | null {
    const semesters = this.getSemesters();
    const id = this.getSelectedSemesterId();
    for (const semester of semesters) {
      if (semester.id === id) {
        return semester;
      }
    }
    return semesters.length > 0 ? semesters[0] : null;
  }

  // ---- 主题色 ----
  getThemeColor(): string {
    return AppStorage.get<string>(DataStore.KEY_THEME_COLOR) ?? ScheduleModels.DEFAULT_THEME_COLOR;
  }

  setThemeColor(color: string): void {
    AppStorage.setOrCreate<string>(DataStore.KEY_THEME_COLOR, color);
    this.storage.saveThemeColor(color);
  }

  // ---- 深色模式 ----
  getDarkMode(): boolean {
    return AppStorage.get<boolean>(DataStore.KEY_DARK_MODE) ?? false;
  }

  setDarkMode(enabled: boolean): void {
    AppStorage.setOrCreate<boolean>(DataStore.KEY_DARK_MODE, enabled);
    this.storage.saveDarkMode(enabled);
  }

  // ---- 同步设置 ----
  getSyncEnabled(): boolean {
    return AppStorage.get<boolean>(DataStore.KEY_SYNC_ENABLED) ?? false;
  }

  setSyncEnabled(enabled: boolean): void {
    AppStorage.setOrCreate<boolean>(DataStore.KEY_SYNC_ENABLED, enabled);
    this.storage.putBoolean(DataStore.KEY_SYNC_ENABLED, enabled);
  }

  getSyncInterval(): number {
    return AppStorage.get<number>(DataStore.KEY_SYNC_INTERVAL) ?? 720;
  }

  setSyncInterval(minutes: number): void {
    AppStorage.setOrCreate<number>(DataStore.KEY_SYNC_INTERVAL, minutes);
    this.storage.putNumber(DataStore.KEY_SYNC_INTERVAL, minutes);
  }

  getSyncLastTime(): string {
    return AppStorage.get<string>(DataStore.KEY_SYNC_LAST_TIME) ?? '';
  }

  setSyncLastTime(value: string): void {
    AppStorage.setOrCreate<string>(DataStore.KEY_SYNC_LAST_TIME, value);
    this.storage.putString(DataStore.KEY_SYNC_LAST_TIME, value);
  }

  // ---- 通知设置 ----
  getNotifyEnabled(): boolean {
    return AppStorage.get<boolean>(DataStore.KEY_NOTIFY_ENABLED) ?? true;
  }

  setNotifyEnabled(enabled: boolean): void {
    AppStorage.setOrCreate<boolean>(DataStore.KEY_NOTIFY_ENABLED, enabled);
    this.storage.putBoolean(DataStore.KEY_NOTIFY_ENABLED, enabled);
  }

  // ---- 电费提醒 ----
  getElectricityReminderEnabled(): boolean {
    return AppStorage.get<boolean>(DataStore.KEY_ELECTRICITY_REMINDER) ?? true;
  }

  setElectricityReminderEnabled(enabled: boolean): void {
    AppStorage.setOrCreate<boolean>(DataStore.KEY_ELECTRICITY_REMINDER, enabled);
    this.storage.putBoolean(DataStore.KEY_ELECTRICITY_REMINDER, enabled);
  }

  getElectricityThreshold(): number {
    return AppStorage.get<number>(DataStore.KEY_ELECTRICITY_THRESHOLD) ?? 10;
  }

  setElectricityThreshold(value: number): void {
    AppStorage.setOrCreate<number>(DataStore.KEY_ELECTRICITY_THRESHOLD, value);
    this.storage.putNumber(DataStore.KEY_ELECTRICITY_THRESHOLD, value);
  }

  // ---- 凭据（密码为密文存储） ----
  getUsername(): string {
    return AppStorage.get<string>(DataStore.KEY_USERNAME) ?? '';
  }

  setUsername(username: string): void {
    AppStorage.setOrCreate<string>(DataStore.KEY_USERNAME, username);
    this.storage.putString(DataStore.KEY_USERNAME, username);
  }

  getPasswordEncrypted(): string {
    return AppStorage.get<string>(DataStore.KEY_PASSWORD_ENCRYPTED) ?? '';
  }

  setPasswordEncrypted(encrypted: string): void {
    AppStorage.setOrCreate<string>(DataStore.KEY_PASSWORD_ENCRYPTED, encrypted);
    this.storage.putString(DataStore.KEY_PASSWORD_ENCRYPTED, encrypted);
  }

  getAutofillEnabled(): boolean {
    return AppStorage.get<boolean>(DataStore.KEY_AUTOFILL_ENABLED) ?? false;
  }

  setAutofillEnabled(enabled: boolean): void {
    AppStorage.setOrCreate<boolean>(DataStore.KEY_AUTOFILL_ENABLED, enabled);
    this.storage.putBoolean(DataStore.KEY_AUTOFILL_ENABLED, enabled);
  }

  hasCredentials(): boolean {
    return this.getUsername() !== '' && this.getPasswordEncrypted() !== '';
  }

  // ---- 成绩数据（JSON 字符串存储，由 SyncService 写入） ----
  getGradeItems(): Array<GradeItemData> {
    const raw = AppStorage.get<string>(DataStore.KEY_GRADES) ?? '[]';
    const items: Array<GradeItemData> = [];
    try {
      const array = JSON.parse(raw) as Array<Object>;
      for (const item of array) {
        const obj = item as Record<string, Object>;
        items.push(new GradeItemData(
          String(obj['name'] ?? ''),
          Number(obj['credits'] ?? 0),
          Number(obj['score'] ?? 0),
          String(obj['semester'] ?? '')
        ));
      }
    } catch (e) {
      // 忽略损坏数据
    }
    return items;
  }

  setGradeItems(items: Array<GradeItemData>): void {
    const array: Array<GradeItemJson> = [];
    for (const item of items) {
      const json: GradeItemJson = {
        name: item.name,
        credits: item.credits,
        score: item.score,
        semester: item.semester
      };
      array.push(json);
    }
    AppStorage.setOrCreate<string>(DataStore.KEY_GRADES, JSON.stringify(array));
    this.storage.putString(DataStore.KEY_GRADES, JSON.stringify(array));
  }

  // ---- 电费余额 ----
  getElectricityBalance(): string {
    return AppStorage.get<string>(DataStore.KEY_ELECTRICITY) ?? '';
  }

  setElectricityBalance(value: string): void {
    AppStorage.setOrCreate<string>(DataStore.KEY_ELECTRICITY, value);
    this.storage.putString(DataStore.KEY_ELECTRICITY, value);
  }

  // ---- 学校标识 ----
  getSchoolId(): string {
    return AppStorage.get<string>(DataStore.KEY_SCHOOL_ID) ?? '';
  }

  setSchoolId(schoolId: string): void {
    AppStorage.setOrCreate<string>(DataStore.KEY_SCHOOL_ID, schoolId);
    this.storage.putString(DataStore.KEY_SCHOOL_ID, schoolId);
  }
}

export class GradeItemData {
  name: string;
  credits: number;
  score: number;
  semester: string;

  constructor(name: string, credits: number, score: number, semester: string) {
    this.name = name;
    this.credits = credits;
    this.score = score;
    this.semester = semester;
  }
}

export interface GradeItemJson {
  name: string;
  credits: number;
  score: number;
  semester: string;
}
