/**
 * 工具层 —— 移植自 Android 参考实现 ScheduleUtils.java
 * 变量与方法命名保持一致。
 */
import { ScheduleModels } from './ScheduleModels';

export namespace ScheduleUtils {

  export function parseWeeks(range: string | null): Array<number> {
    const weeks: Array<number> = [];
    if (range === null) {
      return weeks;
    }
    const parts = range.split(',');
    for (const raw of parts) {
      const part = raw.trim();
      if (part === '') {
        continue;
      }
      const bounds = part.split('-', 2);
      const start = parseInt(bounds[0].trim(), 10);
      const end = bounds.length === 1 ? start : parseInt(bounds[1].trim(), 10);
      for (let week = start; week <= end; week++) {
        weeks.push(week);
      }
    }
    return weeks;
  }

  export function isWeekInRange(week: number, range: string): boolean {
    return parseWeeks(range).includes(week);
  }

  export function matchesRepeatRule(week: number, rule: ScheduleModels.RepeatRule | null): boolean {
    if (rule !== null && rule === ScheduleModels.RepeatRule.ODD) {
      return week % 2 === 1;
    }
    if (rule !== null && rule === ScheduleModels.RepeatRule.EVEN) {
      return week % 2 === 0;
    }
    return true;
  }

  export function weekNumberForDate(date: Date, semester: ScheduleModels.Semester): number {
    const start = mondayOnOrBefore(parseLocalDate(semester.startDate));
    if (start === null) {
      return 1;
    }
    const diff = daysBetween(start, date);
    return diff < 0 ? 0 : Math.floor(diff / 7) + 1;
  }

  export function dateForWeekDay(semesterStart: Date, week: number, dayOfWeek: number): Date {
    const safeWeek = Math.max(1, week);
    const safeDay = Math.max(1, Math.min(7, dayOfWeek));
    const result = new Date(semesterStart);
    result.setDate(result.getDate() + (safeWeek - 1) * 7 + safeDay - 1);
    return result;
  }

  export function mondayOnOrBefore(date: Date | null): Date | null {
    if (date === null) {
      return null;
    }
    const result = new Date(date);
    const day = date.getDay() === 0 ? 7 : date.getDay();
    result.setDate(result.getDate() - (day - 1));
    return result;
  }

  export function isTimeSlotConflict(first: ScheduleModels.TimeSlot, second: ScheduleModels.TimeSlot): boolean {
    if (first.dayOfWeek !== second.dayOfWeek) {
      return false;
    }
    const firstWeeks = effectiveWeeks(first);
    const secondWeeks = effectiveWeeks(second);
    for (const week of firstWeeks) {
      if (!secondWeeks.includes(week)) {
        continue;
      }
      for (const section of first.classSections) {
        if (second.classSections.includes(section)) {
          return true;
        }
      }
    }
    return false;
  }

  export function findConflictDescription(candidate: ScheduleModels.Course, existing: Array<ScheduleModels.Course>,
    excludeId: string): string {
    for (const course of existing) {
      if (course.id === excludeId || course.semesterId !== candidate.semesterId) {
        continue;
      }
      for (const first of candidate.timeSlots) {
        for (const second of course.timeSlots) {
          if (isTimeSlotConflict(first, second)) {
            return `与「${course.name}」冲突`;
          }
        }
      }
    }
    return '';
  }

  export function formatSections(sections: Array<number>): string {
    const sorted = sections.slice().sort((a, b) => a - b);
    return sorted.join('、');
  }

  export function formatSlot(slot: ScheduleModels.TimeSlot): string {
    const prefix = `周${dayLabel(slot.dayOfWeek)} ${formatSections(slot.classSections)}节`;
    const range = slot.weekRange === null || slot.weekRange === '' ? '' : slot.weekRange;
    const rule = slot.repeatRule === null ? '' : slot.repeatRule.label;
    const ruleText = rule === '' || rule === '全部' ? '' : `（${rule}）`;
    const location = slot.location === null || slot.location === '' ? '' : ` ${slot.location}`;
    return `${prefix} ${range}${ruleText}${location}`.trim();
  }

  export function formatCourseTime(course: ScheduleModels.Course): string {
    if (course.timeSlots === null || course.timeSlots.length === 0) {
      return '';
    }
    const texts: Array<string> = [];
    for (const slot of course.timeSlots) {
      texts.push(formatSlot(slot));
    }
    return texts.join('；');
  }

  export function effectiveWeeks(slot: ScheduleModels.TimeSlot): Array<number> {
    const weeks = parseWeeks(slot.weekRange);
    const result: Array<number> = [];
    for (const week of weeks) {
      if (matchesRepeatRule(week, slot.repeatRule)) {
        result.push(week);
      }
    }
    return result;
  }

  export function dayLabel(dayOfWeek: number): string {
    const labels = ['一', '二', '三', '四', '五', '六', '日'];
    if (dayOfWeek >= 1 && dayOfWeek <= 7) {
      return labels[dayOfWeek - 1];
    }
    return `${dayOfWeek}`;
  }

  export function parseLocalDate(value: string): Date {
    const parts = value.split('-');
    const year = parseInt(parts[0], 10);
    const month = parseInt(parts[1], 10);
    const day = parseInt(parts[2], 10);
    return new Date(year, month - 1, day);
  }

  export function daysBetween(a: Date, b: Date): number {
    const ms = startOfDay(b).getTime() - startOfDay(a).getTime();
    return Math.round(ms / (24 * 60 * 60 * 1000));
  }

  export function startOfDay(date: Date): Date {
    return new Date(date.getFullYear(), date.getMonth(), date.getDate());
  }
}
