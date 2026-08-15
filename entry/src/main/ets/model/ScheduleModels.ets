/**
 * 数据模型层 —— 移植自 Android 参考实现 ScheduleModels.java
 * 变量命名与 Java 版本保持一致。
 * 以命名空间形式导出，供页面以 ScheduleModels.Semester 等方式引用。
 */

export namespace ScheduleModels {

  export interface SectionTimeJson {
    start: string;
    end: string;
  }

  export interface TimeSlotJson {
    weekRange: string;
    repeatRule: string;
    dayOfWeek: number;
    sections: Array<number>;
    teacher: string | null;
    location: string | null;
  }

  export interface SemesterJson {
    id: string;
    name: string;
    startDate: string;
    endDate: string;
    weekCount: number;
    sectionCount: number;
    sectionTimes: Array<SectionTimeJson>;
  }

  export interface CourseJson {
    id: string;
    name: string;
    semesterId: string;
    timeSlots: Array<TimeSlotJson>;
    code: string | null;
    location: string | null;
    credits: number | null;
    teacher: string | null;
    assessmentMethod: string | null;
    notes: string | null;
    color: string | null;
  }

  export class RepeatRule {
    static readonly ALL: RepeatRule = new RepeatRule('', '全部');
    static readonly ODD: RepeatRule = new RepeatRule('仅单周', '单周');
    static readonly EVEN: RepeatRule = new RepeatRule('仅双周', '双周');

    readonly storedValue: string;
    readonly label: string;

    constructor(storedValue: string, label: string) {
      this.storedValue = storedValue;
      this.label = label;
    }

    static fromStoredValue(value: string): RepeatRule {
      if (RepeatRule.ODD.storedValue === value) {
        return RepeatRule.ODD;
      }
      if (RepeatRule.EVEN.storedValue === value) {
        return RepeatRule.EVEN;
      }
      return RepeatRule.ALL;
    }
  }

  export class AssessmentMethod {
    static readonly EXAM: AssessmentMethod = new AssessmentMethod('考试');
    static readonly INSPECTION: AssessmentMethod = new AssessmentMethod('考察');
    static readonly PNP: AssessmentMethod = new AssessmentMethod('PnP');

    readonly label: string;

    constructor(label: string) {
      this.label = label;
    }

    static fromLabel(value: string): AssessmentMethod | null {
      if (AssessmentMethod.EXAM.label === value) {
        return AssessmentMethod.EXAM;
      }
      if (AssessmentMethod.INSPECTION.label === value) {
        return AssessmentMethod.INSPECTION;
      }
      if (AssessmentMethod.PNP.label === value) {
        return AssessmentMethod.PNP;
      }
      return null;
    }
  }

  export class SectionTime {
    start: string;
    end: string;

    constructor(start: string, end: string) {
      this.start = start;
      this.end = end;
    }

    json(): SectionTimeJson {
      return { start: this.start, end: this.end };
    }

    static from(o: Record<string, Object>): SectionTime {
      return new SectionTime(optString(o, 'start', ''), optString(o, 'end', ''));
    }
  }

  export class TimeSlot {
    weekRange: string;
    repeatRule: RepeatRule;
    dayOfWeek: number;
    classSections: Array<number>;
    teacher: string | null;
    location: string | null;

    constructor(weekRange: string, repeatRule: RepeatRule | null, dayOfWeek: number, classSections: Array<number>,
      teacher: string | null, location: string | null) {
      this.weekRange = weekRange;
      this.repeatRule = repeatRule === null ? RepeatRule.ALL : repeatRule;
      this.dayOfWeek = dayOfWeek;
      this.classSections = classSections.slice();
      this.teacher = teacher;
      this.location = location;
    }

    json(): TimeSlotJson {
      const sections: Array<number> = this.classSections.slice();
      return {
        weekRange: this.weekRange,
        repeatRule: this.repeatRule.storedValue,
        dayOfWeek: this.dayOfWeek,
        sections: sections,
        teacher: this.teacher,
        location: this.location
      };
    }

    static from(o: Record<string, Object>): TimeSlot {
      const sections: Array<number> = [];
      const rawSections = optArray(o, 'sections');
      for (const item of rawSections) {
        const n = Number(item);
        if (!Number.isNaN(n)) {
          sections.push(Math.trunc(n));
        }
      }
      if (sections.length === 0) {
        sections.push(1);
      }
      return new TimeSlot(
        optString(o, 'weekRange', '1-16'),
        RepeatRule.fromStoredValue(optString(o, 'repeatRule', '')),
        optInt(o, 'dayOfWeek', 1),
        sections,
        optNullableString(o, 'teacher'),
        optNullableString(o, 'location')
      );
    }
  }

  export class Semester {
    id: string;
    name: string;
    startDate: string;
    endDate: string;
    weekCount: number;
    sectionCount: number;
    sectionTimes: Array<SectionTime>;

    constructor(id: string, name: string, startDate: string, endDate: string, weekCount: number, sectionCount: number,
      sectionTimes: Array<SectionTime>) {
      this.id = id;
      this.name = name;
      this.startDate = startDate;
      this.endDate = endDate;
      this.weekCount = weekCount;
      this.sectionCount = sectionCount;
      this.sectionTimes = sectionTimes.slice();
    }

    json(): SemesterJson {
      const times: Array<SectionTimeJson> = [];
      for (const time of this.sectionTimes) {
        times.push(time.json());
      }
      return {
        id: this.id,
        name: this.name,
        startDate: this.startDate,
        endDate: this.endDate,
        weekCount: this.weekCount,
        sectionCount: this.sectionCount,
        sectionTimes: times
      };
    }

    static from(o: Record<string, Object>): Semester {
      const sectionTimes: Array<SectionTime> = [];
      const rawTimes = optArray(o, 'sectionTimes');
      for (const item of rawTimes) {
        sectionTimes.push(SectionTime.from(item));
      }
      let sectionCount = Math.max(1, optInt(o, 'sectionCount', 13));
      let times = sectionTimes;
      if (times.length === 0) {
        times = buildDefaultSectionTimes(sectionCount);
      }
      return new Semester(
        optString(o, 'id', 'semester-default'),
        optString(o, 'name', '学期'),
        optString(o, 'startDate', todayString()),
        optString(o, 'endDate', todayPlusWeeksString(19)),
        Math.max(1, optInt(o, 'weekCount', 20)),
        sectionCount,
        times
      );
    }
  }

  export class Course {
    id: string;
    name: string;
    semesterId: string;
    timeSlots: Array<TimeSlot>;
    code: string | null;
    location: string | null;
    credits: number | null;
    teacher: string | null;
    assessmentMethod: AssessmentMethod | null;
    notes: string | null;
    color: string | null;

    constructor(id: string, name: string, semesterId: string, timeSlots: Array<TimeSlot>) {
      this.id = id;
      this.name = name;
      this.semesterId = semesterId;
      this.timeSlots = timeSlots.slice();
      this.code = null;
      this.location = null;
      this.credits = null;
      this.teacher = null;
      this.assessmentMethod = null;
      this.notes = null;
      this.color = null;
    }

    json(): CourseJson {
      const slots: Array<TimeSlotJson> = [];
      for (const slot of this.timeSlots) {
        slots.push(slot.json());
      }
      const method = this.assessmentMethod === null ? null : this.assessmentMethod.label;
      return {
        id: this.id,
        name: this.name,
        semesterId: this.semesterId,
        timeSlots: slots,
        code: this.code,
        location: this.location,
        credits: this.credits,
        teacher: this.teacher,
        assessmentMethod: method,
        notes: this.notes,
        color: this.color
      };
    }

    static from(o: Record<string, Object>): Course {
      const slots: Array<TimeSlot> = [];
      const rawSlots = optArray(o, 'timeSlots');
      for (const item of rawSlots) {
        slots.push(TimeSlot.from(item));
      }
      if (slots.length === 0) {
        slots.push(new TimeSlot('1-16', RepeatRule.ALL, 1, [1, 2], null, null));
      }
      const course = new Course(
        optString(o, 'id', `course-${Date.now()}`),
        optString(o, 'name', '课程'),
        optString(o, 'semesterId', 'semester-default'),
        slots
      );
      course.code = optNullableString(o, 'code');
      course.location = optNullableString(o, 'location');
      course.credits = optNullableNumber(o, 'credits');
      course.teacher = optNullableString(o, 'teacher');
      const methodLabel = optNullableString(o, 'assessmentMethod');
      course.assessmentMethod = methodLabel === null ? null : AssessmentMethod.fromLabel(methodLabel);
      course.notes = optNullableString(o, 'notes');
      course.color = optNullableString(o, 'color');
      return course;
    }
  }

  export const DEFAULT_THEME_COLOR = '#2F80ED';
  export const PRESET_COLORS: Array<string> = [
    '#E53935',
    '#1E88E5',
    '#43A047',
    '#FB8C00',
    '#8E24AA',
    '#00ACC1',
    '#FFB300',
    '#3949AB'
  ];

  export function buildDefaultSectionTimes(count: number): Array<SectionTime> {
    const standard: Array<Array<string>> = [
      ['08:30', '09:15'],
      ['09:25', '10:10'],
      ['10:30', '11:15'],
      ['11:25', '12:10'],
      ['12:20', '13:05'],
      ['13:05', '13:50'],
      ['14:00', '14:45'],
      ['14:55', '15:40'],
      ['16:00', '16:45'],
      ['16:55', '17:40'],
      ['19:00', '19:45'],
      ['19:55', '20:40'],
      ['20:40', '21:25']
    ];
    const times: Array<SectionTime> = [];
    const total = Math.max(1, count);
    for (let i = 0; i < total; i++) {
      if (i < standard.length) {
        times.push(new SectionTime(standard[i][0], standard[i][1]));
      } else {
        const hour = 8 + i;
        const start = `${pad2(hour)}:00`;
        const end = `${pad2(hour + 1)}:00`;
        times.push(new SectionTime(start, end));
      }
    }
    return times;
  }

  // ---- JSON 安全读取工具（对应 Java org.json 的 optString/optInt 语义） ----
  export function optString(o: Record<string, Object>, key: string, def: string): string {
    const v = o[key];
    if (v === undefined || v === null) {
      return def;
    }
    return `${v}`;
  }

  export function optNullableString(o: Record<string, Object>, key: string): string | null {
    const v = o[key];
    if (v === undefined || v === null) {
      return null;
    }
    return `${v}`;
  }

  export function optInt(o: Record<string, Object>, key: string, def: number): number {
    const v = o[key];
    if (v === undefined || v === null) {
      return def;
    }
    const n = Number(v);
    return Number.isNaN(n) ? def : Math.trunc(n);
  }

  export function optNullableNumber(o: Record<string, Object>, key: string): number | null {
    const v = o[key];
    if (v === undefined || v === null) {
      return null;
    }
    const n = Number(v);
    return Number.isNaN(n) ? null : n;
  }

  export function optArray(o: Record<string, Object>, key: string): Array<Record<string, Object>> {
    const v = o[key];
    if (v === undefined || v === null) {
      return [];
    }
    if (!(v instanceof Array)) {
      return [];
    }
    const raw = v as Array<Object>;
    const result: Array<Record<string, Object>> = [];
    for (const item of raw) {
      result.push(item as Record<string, Object>);
    }
    return result;
  }

  function todayString(): string {
    return formatDate(new Date());
  }

  function todayPlusWeeksString(weeks: number): string {
    const now = new Date();
    now.setDate(now.getDate() + weeks * 7);
    return formatDate(now);
  }

  function formatDate(date: Date): string {
    return `${date.getFullYear()}-${pad2(date.getMonth() + 1)}-${pad2(date.getDate())}`;
  }

  function pad2(value: number): string {
    return value < 10 ? `0${value}` : `${value}`;
  }
}
