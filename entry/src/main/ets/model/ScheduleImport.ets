/**
 * 课表导入解析 —— 移植自 Android 参考实现 ScheduleImport.java
 * 命名、正则与解析逻辑保持一致。
 */
import { ScheduleModels } from './ScheduleModels';
import { ScheduleUtils } from './ScheduleUtils';

export class RawSemester {
  name: string;
  dataSemester: string;

  constructor(name: string, dataSemester: string) {
    this.name = name;
    this.dataSemester = dataSemester;
  }
}

export class RawCourse {
  name: string = '';
  code: string | null = null;
  credits: number | null = null;
  teacher: string | null = null;
  assessmentMethod: string | null = null;
  scheduleText: string | null = null;
  location: string | null = null;
  dataSemester: string | null = null;
}

export class ParsedData {
  semesters: Array<RawSemester> = [];
  courses: Array<RawCourse> = [];
}

const DAY_MAP: Map<string, number> = new Map([
  ['周一', 1], ['星期二', 2], ['周二', 2], ['周三', 3], ['周四', 4], ['周五', 5], ['周六', 6], ['周日', 7]
]);

const CHINESE_NUMBERS: Map<string, number> = new Map([
  ['一', 1], ['二', 2], ['三', 3], ['四', 4], ['五', 5], ['六', 6], ['七', 7], ['八', 8], ['九', 9],
  ['十', 10], ['十一', 11], ['十二', 12], ['十三', 13], ['十四', 14], ['十五', 15], ['十六', 16],
  ['十七', 17], ['十八', 18], ['十九', 19], ['二十', 20]
]);

const ONLINE_KEYWORDS = ['网络', '在线', '线上', 'MOOC', '慕课', '超星', '雨课堂', '学习通', '智慧树'];

export class ScheduleImport {
  static parsePayload(raw: string): ParsedData {
    const result = new ParsedData();
    if (raw === null || raw === '') {
      return result;
    }
    try {
      const root = JSON.parse(raw) as Record<string, Object>;
      const data = root['data'] as Record<string, Object>;
      const rawSemesters = optArray(data, 'semesters');
      for (const item of rawSemesters) {
        const obj = item as Record<string, Object>;
        result.semesters.push(new RawSemester(
          optString(obj, 'name', ''),
          optString(obj, 'dataSemester', '')
        ));
      }
      const rawCourses = optArray(data, 'courses');
      for (const item of rawCourses) {
        const obj = item as Record<string, Object>;
        const course = new RawCourse();
        course.name = optString(obj, 'name', '');
        course.code = optNullableString(obj, 'code');
        course.credits = optNullableNumber(obj, 'credits');
        course.teacher = optNullableString(obj, 'teacher');
        course.assessmentMethod = optNullableString(obj, 'assessmentMethod');
        course.scheduleText = optNullableString(obj, 'scheduleText');
        course.location = optNullableString(obj, 'location');
        course.dataSemester = optNullableString(obj, 'dataSemester');
        result.courses.push(course);
      }
    } catch (e) {
      // 解析失败返回空结构
    }
    return result;
  }

  static convertToCourses(courses: Array<RawCourse>, semesterId: string, dataSemester: string | null):
    Array<ScheduleModels.Course> {
    const grouped: Map<string, ScheduleModels.Course> = new Map();
    let colorIndex = 0;
    for (const raw of courses) {
      if (raw.dataSemester !== null && dataSemester !== null && raw.dataSemester !== dataSemester) {
        continue;
      }
      const name = raw.name === null ? '' : raw.name.trim();
      if (name === '') {
        continue;
      }
      const timeSlots = parseScheduleText(raw.scheduleText);
      if (timeSlots.length === 0) {
        continue;
      }
      const key = `${name}|${semesterId}`;
      let course = grouped.get(key);
      if (course === undefined) {
        course = new ScheduleModels.Course(`course-${Date.now()}-${colorIndex}`, name, semesterId, timeSlots);
        grouped.set(key, course);
      } else {
        for (const slot of timeSlots) {
          course.timeSlots.push(slot);
        }
      }
      const teacher = mergeTeachers(raw.teacher);
      course.code = emptyToNull(raw.code);
      course.credits = raw.credits;
      course.teacher = teacher;
      course.assessmentMethod = parseAssessment(raw.assessmentMethod);
      course.location = emptyToNull(raw.location);
      course.color = ScheduleModels.PRESET_COLORS[colorIndex % ScheduleModels.PRESET_COLORS.length];
      colorIndex++;
    }
    return Array.from(grouped.values());
  }

  static createImportedSemester(raw: RawSemester, courses: Array<ScheduleModels.Course>): ScheduleModels.Semester {
    const maxWeek = Math.max(20, calculateMaxWeek(courses));
    const now = new Date();
    const year = now.getFullYear();
    let month = 9;
    if (raw.dataSemester !== null) {
      const matcher = raw.dataSemester.match(/(\d{4})-(\d{1,2})/);
      if (matcher !== null) {
        const m = parseInt(matcher[2], 10);
        if (m >= 1 && m <= 8) {
          month = 2;
        }
      }
    }
    const start = new Date(year, month - 1, 1);
    const end = new Date(start);
    end.setDate(end.getDate() + maxWeek * 7 - 1);
    return new ScheduleModels.Semester(
      `semester-${Date.now()}`,
      raw.name === null ? '' : raw.name,
      formatDate(start),
      formatDate(end),
      maxWeek,
      13,
      ScheduleModels.buildDefaultSectionTimes(13)
    );
  }
}

function parseScheduleText(value: string | null): Array<ScheduleModels.TimeSlot> {
  const slots: Array<ScheduleModels.TimeSlot> = [];
  if (value === null || value.trim() === '') {
    return slots;
  }
  const cleaned = value.replace(/<[^>]+>/g, ' ').replace(/&nbsp;/g, ' ').replace(/\s+/g, ' ').trim();
  const segments = cleaned.split(/[;；]/);
  for (const rawSegment of segments) {
    const segment = rawSegment.trim();
    if (segment === '' || containsAny(segment, ONLINE_KEYWORDS)) {
      continue;
    }
    const day = parseDayOfWeek(segment);
    if (day === null) {
      continue;
    }
    const dayPosition = findDayPosition(segment);
    const weekPart = dayPosition >= 0 ? segment.substring(0, dayPosition) : segment;
    const restPart = dayPosition >= 0 ? segment.substring(dayPosition) : segment;
    const sections = parseSections(restPart);
    if (sections.length === 0) {
      continue;
    }
    const rule = parseRepeatRule(segment);
    const weekRanges = extractWeekRanges(weekPart);
    for (const weekRange of weekRanges) {
      slots.push(new ScheduleModels.TimeSlot(weekRange, rule, day, sections, null, null));
    }
  }
  return mergeSlots(slots);
}

function mergeSlots(slots: Array<ScheduleModels.TimeSlot>): Array<ScheduleModels.TimeSlot> {
  const grouped: Map<string, Array<ScheduleModels.TimeSlot>> = new Map();
  for (const slot of slots) {
    const key = `${slot.repeatRule.storedValue}|${slot.dayOfWeek}|${slot.classSections.join(',')}|${slot.teacher}|${slot.location}`;
    let group = grouped.get(key);
    if (group === undefined) {
      group = [];
      grouped.set(key, group);
    }
    group.push(slot);
  }
  const merged: Array<ScheduleModels.TimeSlot> = [];
  for (const group of grouped.values()) {
    const intervals: Array<Array<number>> = [];
    for (const slot of group) {
      const weeks = ScheduleUtils.parseWeeks(slot.weekRange);
      if (weeks.length === 0) {
        continue;
      }
      intervals.push([Math.min(...weeks), Math.max(...weeks)]);
    }
    intervals.sort((a, b) => a[0] - b[0]);
    const mergedIntervals: Array<Array<number>> = [];
    for (const interval of intervals) {
      if (mergedIntervals.length === 0) {
        mergedIntervals.push(interval);
        continue;
      }
      const last = mergedIntervals[mergedIntervals.length - 1];
      if (interval[0] <= last[1] + 1) {
        last[1] = Math.max(last[1], interval[1]);
      } else {
        mergedIntervals.push(interval);
      }
    }
    for (const interval of mergedIntervals) {
      merged.push(new ScheduleModels.TimeSlot(
        interval[0] === interval[1] ? `${interval[0]}` : `${interval[0]}-${interval[1]}`,
        group[0].repeatRule,
        group[0].dayOfWeek,
        group[0].classSections,
        group[0].teacher,
        group[0].location
      ));
    }
  }
  return merged;
}

function parseSections(text: string): Array<number> {
  let m = text.match(CHINESE_SECTION_RANGE);
  if (m !== null) {
    return range(chineseNumber(m[1]), chineseNumber(m[2] === undefined ? m[1] : m[2]));
  }
  m = text.match(ARABIC_SECTION_RANGE_A);
  if (m !== null) {
    return range(parseInt10(m[1]), parseInt10(m[2]));
  }
  m = text.match(ARABIC_SECTION_RANGE_B);
  if (m !== null) {
    return range(parseInt10(m[1]), parseInt10(m[2]));
  }
  m = text.match(ARABIC_SECTION_LIST);
  if (m !== null) {
    return parseCsv(m[1]);
  }
  m = text.match(ARABIC_SECTION_LIST_B);
  if (m !== null) {
    return parseCsv(m[1]);
  }
  m = text.match(CHINESE_SECTION_SINGLE);
  if (m !== null) {
    return [chineseNumber(m[1])];
  }
  m = text.match(ARABIC_SECTION_SINGLE);
  if (m !== null) {
    return [parseInt10(m[1])];
  }
  m = text.match(ARABIC_SECTION_SINGLE_B);
  if (m !== null) {
    return [parseInt10(m[1])];
  }
  return [];
}

function parseRepeatRule(text: string): ScheduleModels.RepeatRule {
  if (text.includes('单周') || text.includes('(单)') || text.includes('（单）')) {
    return ScheduleModels.RepeatRule.ODD;
  }
  if (text.includes('双周') || text.includes('(双)') || text.includes('（双）')) {
    return ScheduleModels.RepeatRule.EVEN;
  }
  return ScheduleModels.RepeatRule.ALL;
}

function extractWeekRanges(text: string): Array<string> {
  let converted = text;
  for (const entry of CHINESE_NUMBERS.entries()) {
    converted = converted.replace(`第${entry[0]}周`, `${entry[1]}`);
  }
  converted = converted.replace(/周/g, '').trim();
  if (converted === '') {
    return ['1-16'];
  }
  const ranges: Array<string> = [];
  for (const raw of converted.split(/[,，、]/)) {
    const part = raw.trim();
    const rangeMatcher = part.match(WEEK_RANGE);
    if (rangeMatcher !== null) {
      const start = parseInt10(rangeMatcher[1]);
      const end = parseInt10(rangeMatcher[2]);
      if (start > 0 && end >= start) {
        ranges.push(start === end ? `${start}` : `${start}-${end}`);
      }
      continue;
    }
    const singleMatcher = part.match(WEEK_SINGLE);
    if (singleMatcher !== null) {
      const week = parseInt10(singleMatcher[1]);
      if (week > 0) {
        ranges.push(`${week}`);
      }
    }
  }
  return ranges.length === 0 ? ['1-16'] : ranges;
}

function parseDayOfWeek(text: string): number | null {
  for (const entry of DAY_MAP.entries()) {
    if (text.includes(entry[0])) {
      return entry[1];
    }
  }
  return null;
}

function findDayPosition(text: string): number {
  let index = -1;
  for (const key of DAY_MAP.keys()) {
    const found = text.indexOf(key);
    if (found >= 0 && (index < 0 || found < index)) {
      index = found;
    }
  }
  return index;
}

function calculateMaxWeek(courses: Array<ScheduleModels.Course>): number {
  let max = 0;
  for (const course of courses) {
    for (const slot of course.timeSlots) {
      for (const week of ScheduleUtils.parseWeeks(slot.weekRange)) {
        max = Math.max(max, week);
      }
    }
  }
  return max;
}

function parseAssessment(value: string | null): ScheduleModels.AssessmentMethod | null {
  if (value === null) {
    return null;
  }
  if (value.includes('考试')) {
    return ScheduleModels.AssessmentMethod.EXAM;
  }
  if (value.includes('考察')) {
    return ScheduleModels.AssessmentMethod.INSPECTION;
  }
  if (value.includes('PnP')) {
    return ScheduleModels.AssessmentMethod.PNP;
  }
  return null;
}

function mergeTeachers(value: string | null): string {
  const out: Array<string> = [];
  if (value !== null) {
    for (const name of value.split(/[,，、;/；|｜\s]+/)) {
      const trimmed = name.trim();
      if (trimmed !== '' && !isTeacherMetadata(trimmed) && !out.includes(trimmed)) {
        out.push(trimmed);
      }
    }
  }
  return out.join('、');
}

function isTeacherMetadata(value: string): boolean {
  return /校区|教师另行安排场地|(?:上课|授课|任课)教师/.test(value);
}

function containsAny(text: string, keywords: Array<string>): boolean {
  for (const keyword of keywords) {
    if (text.includes(keyword)) {
      return true;
    }
  }
  return false;
}

function emptyToNull(value: string | null): string | null {
  if (value === null) {
    return null;
  }
  const trimmed = value.trim();
  return trimmed === '' ? null : trimmed;
}

function parseCsv(value: string): Array<number> {
  const result: Array<number> = [];
  for (const raw of value.split(',')) {
    const n = parseInt10(raw);
    if (n > 0) {
      result.push(n);
    }
  }
  return result;
}

function chineseNumber(value: string): number {
  const direct = CHINESE_NUMBERS.get(value);
  if (direct !== undefined) {
    return direct;
  }
  let result = 0;
  const tenIndex = value.indexOf('十');
  if (tenIndex < 0) {
    return 0;
  }
  if (tenIndex === 0) {
    result = 10;
  } else {
    const tens = CHINESE_NUMBERS.get(value.substring(0, tenIndex));
    result = (tens === undefined ? 1 : tens) * 10;
  }
  if (tenIndex < value.length - 1) {
    const ones = CHINESE_NUMBERS.get(value.substring(tenIndex + 1));
    result += ones === undefined ? 0 : ones;
  }
  return result;
}

function range(start: number, end: number): Array<number> {
  const result: Array<number> = [];
  for (let i = start; i <= end; i++) {
    result.push(i);
  }
  return result;
}

function parseInt10(value: string): number {
  return parseInt(value, 10);
}

// ---- 正则常量（与 Java 版本 Pattern 一致） ----
const CHINESE_SECTION_RANGE = new RegExp(`第(十一|十二|十三|十四|十五|十六|十七|十八|十九|二十|一|二|三|四|五|六|七|八|九|十)(?:[~至-](十一|十二|十三|十四|十五|十六|十七|十八|十九|二十|一|二|三|四|五|六|七|八|九|十))?节`);
const ARABIC_SECTION_RANGE_A = new RegExp('第(\\d+)[~至-](\\d+)节');
const ARABIC_SECTION_RANGE_B = new RegExp('(\\d+)[节~至\\-](\\d+)节');
const ARABIC_SECTION_LIST = new RegExp('第((?:\\d+,)*\\d+)节');
const ARABIC_SECTION_LIST_B = new RegExp('((?:\\d+,)*\\d+)节');
const CHINESE_SECTION_SINGLE = new RegExp('第(十一|十二|十三|十四|十五|十六|十七|十八|十九|二十|一|二|三|四|五|六|七|八|九|十)节');
const ARABIC_SECTION_SINGLE = new RegExp('第(\\d+)节');
const ARABIC_SECTION_SINGLE_B = new RegExp('(\\d+)节');
const WEEK_RANGE = new RegExp('(\\d+)\\s*-\\s*(\\d+)');
const WEEK_SINGLE = new RegExp('(\\d+)');

function optString(o: Record<string, Object>, key: string, def: string): string {
  const v = o[key];
  if (v === undefined || v === null) {
    return def;
  }
  return `${v}`;
}

function optNullableString(o: Record<string, Object>, key: string): string | null {
  const v = o[key];
  if (v === undefined || v === null) {
    return null;
  }
  return `${v}`;
}

function optNullableNumber(o: Record<string, Object>, key: string): number | null {
  const v = o[key];
  if (v === undefined || v === null) {
    return null;
  }
  const n = Number(v);
  return Number.isNaN(n) ? null : n;
}

function optArray(o: Record<string, Object>, key: string): Array<Record<string, Object>> {
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

function formatDate(date: Date): string {
  return `${date.getFullYear()}-${pad2(date.getMonth() + 1)}-${pad2(date.getDate())}`;
}

function pad2(value: number): string {
  return value < 10 ? `0${value}` : `${value}`;
}
