/**
 * 存储层 —— 移植自 Android 参考实现 ScheduleStorage.java
 * 基于 @ohos.data.preferences，key 名称与 Java 版本保持一致。
 */
import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { ScheduleModels } from './ScheduleModels';

export class ScheduleStorage {
  static readonly KEY_SEMESTERS = 'schedule_semesters';
  static readonly KEY_COURSES = 'schedule_courses';
  static readonly KEY_SELECTED_SEMESTER = 'schedule_selected_semester';
  static readonly KEY_THEME_COLOR = 'schedule_theme_color';
  static readonly KEY_DARK_MODE = 'schedule_dark_mode';
  static readonly STORE_NAME = 'campus_preferences';

  private static instance: ScheduleStorage | null = null;
  private pref: preferences.Preferences | null = null;

  static get(): ScheduleStorage {
    if (ScheduleStorage.instance === null) {
      ScheduleStorage.instance = new ScheduleStorage();
    }
    return ScheduleStorage.instance;
  }

  async init(context: common.Context): Promise<void> {
    if (this.pref !== null) {
      return;
    }
    const options: preferences.Options = { name: ScheduleStorage.STORE_NAME };
    this.pref = await preferences.getPreferences(context, options);
  }

  private requirePref(): preferences.Preferences {
    if (this.pref === null) {
      throw new Error('ScheduleStorage not initialized');
    }
    return this.pref;
  }

  // ---- 学期 ----
  async loadSemesters(): Promise<Array<ScheduleModels.Semester>> {
    const raw = await this.getString(ScheduleStorage.KEY_SEMESTERS, '');
    const semesters: Array<ScheduleModels.Semester> = [];
    if (raw === '') {
      return semesters;
    }
    try {
      const array = JSON.parse(raw) as Array<Object>;
      for (const item of array) {
        semesters.push(ScheduleModels.Semester.from(item as Record<string, Object>));
      }
    } catch (e) {
      // 忽略损坏数据
    }
    return semesters;
  }

  async saveSemesters(semesters: Array<ScheduleModels.Semester>): Promise<void> {
    const array: Array<Object> = [];
    for (const semester of semesters) {
      array.push(semester.json());
    }
    await this.putString(ScheduleStorage.KEY_SEMESTERS, JSON.stringify(array));
  }

  // ---- 课程 ----
  async loadCourses(): Promise<Array<ScheduleModels.Course>> {
    const raw = await this.getString(ScheduleStorage.KEY_COURSES, '');
    const courses: Array<ScheduleModels.Course> = [];
    if (raw === '') {
      return courses;
    }
    try {
      const array = JSON.parse(raw) as Array<Object>;
      for (const item of array) {
        courses.push(ScheduleModels.Course.from(item as Record<string, Object>));
      }
    } catch (e) {
      // 忽略损坏数据
    }
    return courses;
  }

  async saveCourses(courses: Array<ScheduleModels.Course>): Promise<void> {
    const array: Array<Object> = [];
    for (const course of courses) {
      array.push(course.json());
    }
    await this.putString(ScheduleStorage.KEY_COURSES, JSON.stringify(array));
  }

  // ---- 选中学期 ----
  async loadSelectedSemesterId(): Promise<string> {
    return this.getString(ScheduleStorage.KEY_SELECTED_SEMESTER, '');
  }

  async saveSelectedSemesterId(id: string): Promise<void> {
    await this.putString(ScheduleStorage.KEY_SELECTED_SEMESTER, id);
  }

  // ---- 主题色 ----
  async loadThemeColor(): Promise<string> {
    const value = await this.getString(ScheduleStorage.KEY_THEME_COLOR, '');
    return value === '' ? ScheduleModels.DEFAULT_THEME_COLOR : value;
  }

  async saveThemeColor(color: string): Promise<void> {
    await this.putString(ScheduleStorage.KEY_THEME_COLOR, color);
  }

  // ---- 深色模式 ----
  async loadDarkMode(): Promise<boolean> {
    return this.getBoolean(ScheduleStorage.KEY_DARK_MODE, false);
  }

  async saveDarkMode(enabled: boolean): Promise<void> {
    await this.putBoolean(ScheduleStorage.KEY_DARK_MODE, enabled);
  }

  // ---- 通用偏好（同步开关/间隔/凭据等） ----
  async getString(key: string, def: string): Promise<string> {
    try {
      const value = await this.requirePref().get(key, def);
      return value as string;
    } catch (e) {
      return def;
    }
  }

  async putString(key: string, value: string): Promise<void> {
    try {
      await this.requirePref().put(key, value);
      await this.requirePref().flush();
    } catch (e) {
      // 忽略写入失败
    }
  }

  async getBoolean(key: string, def: boolean): Promise<boolean> {
    try {
      const value = await this.requirePref().get(key, def);
      return value as boolean;
    } catch (e) {
      return def;
    }
  }

  async putBoolean(key: string, value: boolean): Promise<void> {
    try {
      await this.requirePref().put(key, value);
      await this.requirePref().flush();
    } catch (e) {
      // 忽略写入失败
    }
  }

  async getNumber(key: string, def: number): Promise<number> {
    try {
      const value = await this.requirePref().get(key, def);
      return value as number;
    } catch (e) {
      return def;
    }
  }

  async putNumber(key: string, value: number): Promise<void> {
    try {
      await this.requirePref().put(key, value);
      await this.requirePref().flush();
    } catch (e) {
      // 忽略写入失败
    }
  }
}
