import { common } from '@kit.AbilityKit';
import { preferences } from '@kit.ArkData';
import { formProvider } from '@kit.FormKit';
import { Course, Semester } from './CourseModel';
import { WidgetDataBuilder, WidgetSnapshot } from './WidgetDataBuilder';
import { WidgetSnapshotStore } from './WidgetSnapshotStore';
import { WeekUtils } from './WeekUtils';

export class WidgetPusher {
  static async refresh(context: common.UIAbilityContext, courses: Course[], semesters: Semester[],
                       semesterIndex: number, balance: number): Promise<void> {
    try {
      const snaps: WidgetSnapshot[] = WidgetDataBuilder.buildAll(courses, semesters, semesterIndex,
        balance, new Date());
      const pairs: Array<[string, string]> = [];
      for (let i = 0; i < snaps.length; i++) {
        pairs.push([snaps[i].formName, snaps[i].json]);
      }
      await WidgetSnapshotStore.saveSnapshots(context, pairs);
      const notified: number = await formProvider.reloadAllForms(context);
      console.info(`WidgetPusher.refresh: snapshots=${pairs.length} forms=${notified}`);
    } catch (e) {
      console.error(`WidgetPusher.refresh error: ${e}`);
    }
  }

  static currentSemesterIndex(semesters: Semester[], now: Date): number {
    if (semesters.length === 0) {
      return 0;
    }
    let best: number = -1;
    let bestStart: string = '';
    for (let i = 0; i < semesters.length; i++) {
      const sem: Semester = semesters[i];
      if (sem.startDate.length === 0) {
        continue;
      }
      const week: number = WeekUtils.weekNumberForDate(now, sem.startDate);
      if (week >= 1 && week <= Math.max(1, sem.weekCount)) {
        if (best === -1 || sem.startDate > bestStart) {
          best = i;
          bestStart = sem.startDate;
        }
      }
    }
    return best >= 0 ? best : 0;
  }

  static async buildFromStore(context: common.Context, now: Date): Promise<WidgetSnapshot[]> {
    try {
      const pref: preferences.Preferences | undefined = await preferences.getPreferences(context, 'campus_private');
      if (pref === undefined) {
        return [];
      }
      const semesters: Semester[] = [];
      const courses: Course[] = [];
      const rawCourses: string = pref.getSync('courses', '') as string;
      if (rawCourses.length > 0) {
        const parsed: Record<string, Object> = JSON.parse(rawCourses) as Record<string, Object>;
        let semArr: Object[] = [];
        const rawSem: Object | undefined = parsed['semesters'];
        if (rawSem !== undefined && rawSem !== null) {
          semArr = rawSem as Object[];
        }
        for (let i = 0; i < semArr.length; i++) {
          semesters.push(Semester.fromJsObject(semArr[i] as Record<string, Object>));
        }
        let couArr: Object[] = [];
        const rawCou: Object | undefined = parsed['courses'];
        if (rawCou !== undefined && rawCou !== null) {
          couArr = rawCou as Object[];
        }
        for (let i = 0; i < couArr.length; i++) {
          courses.push(Course.fromRecord(couArr[i] as Record<string, Object>));
        }
      }
      let balance: number = -1;
      const rawBal: string = pref.getSync('electricity_balance', '') as string;
      if (rawBal.length > 0) {
        const parsedBal: number = parseFloat(rawBal);
        if (isFinite(parsedBal)) {
          balance = parsedBal;
        }
      }
      const semesterIndex: number = WidgetPusher.currentSemesterIndex(semesters, now);
      return WidgetDataBuilder.buildAll(courses, semesters, semesterIndex, balance, now);
    } catch (e) {
      console.error(`WidgetPusher.buildFromStore error: ${e}`);
      return [];
    }
  }

  static jsonFor(snaps: WidgetSnapshot[], formName: string): string {
    for (let i = 0; i < snaps.length; i++) {
      if (snaps[i].formName === formName) {
        return snaps[i].json;
      }
    }
    return '';
  }
}