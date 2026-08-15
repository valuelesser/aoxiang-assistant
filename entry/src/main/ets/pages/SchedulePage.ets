/**
 * 课表页 —— 对应 Android 参考实现 ScheduleFragment
 * 周视图 + 月历 + 周次切换 + 课程详情弹窗
 */
import { DataStore } from '../common/DataStore';
import { ScheduleModels } from '../model/ScheduleModels';
import { ScheduleUtils } from '../model/ScheduleUtils';

@Component
export struct SchedulePage {
  @StorageLink('themeColor') themeColor: string = '#2F80ED';
  @State displayDate: Date = new Date();
  @State showCalendar: boolean = false;
  @State selectedCourse: ScheduleModels.Course | null = null;

  aboutToAppear(): void {
    this.displayDate = new Date();
  }

  private currentWeek(): number {
    const semester = DataStore.get().getSelectedSemester();
    if (semester === null) {
      return 1;
    }
    const week = ScheduleUtils.weekNumberForDate(this.displayDate, semester);
    return week <= 0 ? 1 : week;
  }

  private semesterName(): string {
    const semester = DataStore.get().getSelectedSemester();
    return semester === null ? '未设置学期' : semester.name;
  }

  private weekDates(): Array<Date> {
    const monday = ScheduleUtils.mondayOnOrBefore(this.displayDate);
    if (monday === null) {
      return [];
    }
    const dates: Array<Date> = [];
    for (let i = 0; i < 7; i++) {
      const d = new Date(monday);
      d.setDate(d.getDate() + i);
      dates.push(d);
    }
    return dates;
  }

  private coursesForDay(dayOfWeek: number, week: number): Array<ScheduleModels.Course> {
    const courses = DataStore.get().getCourses();
    const semesterId = DataStore.get().getSelectedSemesterId();
    const result: Array<ScheduleModels.Course> = [];
    for (const course of courses) {
      if (course.semesterId !== semesterId) {
        continue;
      }
      for (const slot of course.timeSlots) {
        if (slot.dayOfWeek === dayOfWeek &&
          ScheduleUtils.matchesRepeatRule(week, slot.repeatRule) &&
          ScheduleUtils.isWeekInRange(week, slot.weekRange)) {
          result.push(course);
          break;
        }
      }
    }
    result.sort((a: ScheduleModels.Course, b: ScheduleModels.Course) => {
      return this.earliestSection(a, dayOfWeek) - this.earliestSection(b, dayOfWeek);
    });
    return result;
  }

  private earliestSection(course: ScheduleModels.Course, dayOfWeek: number): number {
    let min = 99;
    for (const slot of course.timeSlots) {
      if (slot.dayOfWeek === dayOfWeek) {
        for (const section of slot.classSections) {
          min = Math.min(min, section);
        }
      }
    }
    return min;
  }

  private sectionRange(course: ScheduleModels.Course, dayOfWeek: number): string {
    let sections: Array<number> = [];
    for (const slot of course.timeSlots) {
      if (slot.dayOfWeek === dayOfWeek) {
        sections = sections.concat(slot.classSections);
      }
    }
    sections.sort((a, b) => a - b);
    return `${sections[0]}-${sections[sections.length - 1]}节`;
  }

  private slotLocation(course: ScheduleModels.Course, dayOfWeek: number): string {
    for (const slot of course.timeSlots) {
      if (slot.dayOfWeek === dayOfWeek && slot.location !== null && slot.location !== '') {
        return slot.location;
      }
    }
    return '';
  }

  build() {
    Column() {
      // 顶部：学期名 + 周次切换
      Row() {
        Image($r('app.media.ic_arrow_back'))
          .width(16)
          .height(16)
          .opacity(0)
        Column({ space: 2 }) {
          Text(this.semesterName())
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor('#1A1A1A')
          Text(`第 ${this.currentWeek()} 周`)
            .fontSize(12)
            .fontColor(this.themeColor)
        }

        Blank()

        Row({ space: 8 }) {
          Image($r('app.media.ic_arrow_back'))
            .width(22)
            .height(22)
            .fillColor('#4A4A4A')
            .onClick(() => {
              this.shiftWeek(-1);
            })
          Text(`${this.currentWeek()}`)
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor('#1A1A1A')
          Image($r('app.media.ic_arrow_back'))
            .width(22)
            .height(22)
            .fillColor('#4A4A4A')
            .rotate({ angle: 180 })
            .onClick(() => {
              this.shiftWeek(1);
            })
        }
        .padding({ left: 8, right: 8, top: 4, bottom: 4 })
        .backgroundColor(Color.White)
        .borderRadius(20)
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 8 })

      // 星期头部 + 月历开关
      Row() {
        ForEach(this.weekDates(), (date: Date) => {
          this.WeekHeader(date)
        }, (date: Date) => date.getTime().toString())
      }
      .width('100%')
      .padding({ left: 8, right: 8 })

      if (this.showCalendar) {
        this.MonthCalendar()
      }

      // 课表主体
      Scroll() {
        Row() {
          // 节次列
          Column() {
            ForEach(this.sectionLabels(), (label: string, index: number) => {
              Text(label)
                .fontSize(10)
                .fontColor('#8A8A8E')
                .width(28)
                .height(52)
                .textAlign(TextAlign.Center)
            })
          }
          .margin({ top: 30 })

          // 各天课程列
          ForEach(this.weekDates(), (date: Date) => {
            this.DayColumn(date)
          }, (date: Date) => date.getTime().toString())
        }
        .width('100%')
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F6FA')
  }

  private shiftWeek(delta: number): void {
    const d = new Date(this.displayDate);
    d.setDate(d.getDate() + delta * 7);
    this.displayDate = d;
  }

  private sectionLabels(): Array<string> {
    const semester = DataStore.get().getSelectedSemester();
    if (semester === null) {
      return [];
    }
    const labels: Array<string> = [];
    for (let i = 0; i < semester.sectionCount; i++) {
      labels.push(`${i + 1}`);
    }
    return labels;
  }

  @Builder
  WeekHeader(date: Date) {
    Column({ space: 2 }) {
      Text(this.dayLabelOf(date))
        .fontSize(12)
        .fontColor(this.isTodayOf(date) ? this.themeColor : '#8A8A8E')
        .fontWeight(this.isTodayOf(date) ? FontWeight.Bold : FontWeight.Normal)
      Text(`${date.getDate()}`)
        .fontSize(13)
        .fontColor(this.isTodayOf(date) ? Color.White : '#4A4A4A')
        .fontWeight(this.isTodayOf(date) ? FontWeight.Bold : FontWeight.Normal)
        .width(26)
        .height(26)
        .textAlign(TextAlign.Center)
        .backgroundColor(this.isTodayOf(date) ? this.themeColor : Color.Transparent)
        .borderRadius(13)
    }
    .layoutWeight(1)
    .onClick(() => {
      this.displayDate = date;
    })
  }

  private isTodayOf(date: Date): boolean {
    return this.isSameDay(date, new Date());
  }

  private dayLabelOf(date: Date): string {
    const labels = ['一', '二', '三', '四', '五', '六', '日'];
    return labels[date.getDay() === 0 ? 6 : date.getDay() - 1];
  }

  @Builder
  DayColumn(date: Date) {
    Column({ space: 4 }) {
      ForEach(this.coursesForDay(this.dayOfWeekOf(date), this.currentWeek()),
        (course: ScheduleModels.Course) => {
        Column() {
          Text(course.name)
            .fontSize(10)
            .fontWeight(FontWeight.Medium)
            .fontColor(Color.White)
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
          Text(this.sectionRange(course, this.dayOfWeekOf(date)))
            .fontSize(9)
            .fontColor(Color.White)
            .opacity(0.9)
        }
        .width('100%')
        .padding(4)
        .backgroundColor(course.color === null ? this.themeColor : course.color)
        .borderRadius(6)
        .onClick(() => {
          this.selectedCourse = course;
        })
      }, (course: ScheduleModels.Course) => `${course.id}-${this.dayOfWeekOf(date)}`)
    }
    .layoutWeight(1)
    .padding({ left: 2, right: 2 })
    .margin({ top: 6 })
  }

  private dayOfWeekOf(date: Date): number {
    return date.getDay() === 0 ? 7 : date.getDay();
  }

  @Builder
  MonthCalendar() {
    Column() {
      // 月份标题
      Text(`${this.displayDate.getFullYear()}年${this.displayDate.getMonth() + 1}月`)
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor('#1A1A1A')
        .margin({ top: 6, bottom: 8 })

      // 星期表头
      Row() {
        ForEach(['一', '二', '三', '四', '五', '六', '日'], (label: string) => {
          Text(label)
            .fontSize(11)
            .fontColor('#8A8A8E')
            .layoutWeight(1)
            .textAlign(TextAlign.Center)
        })
      }
      .width('100%')

      // 日历网格
      Grid() {
        ForEach(this.calendarCells(), (cell: CalendarCell) => {
          GridItem() {
            Column({ space: 2 }) {
              Text(cell.day === 0 ? '' : `${cell.day}`)
                .fontSize(12)
                .fontColor(cell.inMonth ? '#1A1A1A' : '#C7C7CC')
                .fontWeight(this.isSameDay(cell.date, this.displayDate) ? FontWeight.Bold : FontWeight.Normal)
                .width(26)
                .height(26)
                .textAlign(TextAlign.Center)
                .backgroundColor(this.isSameDay(cell.date, this.displayDate) ? this.themeColor : Color.Transparent)
                .borderRadius(13)
                .fontColor(this.isSameDay(cell.date, this.displayDate) ? Color.White : (cell.inMonth ? '#1A1A1A' : '#C7C7CC'))
              Row({ space: 2 }) {
                ForEach(this.calendarDots(cell), (hasCourse: boolean, index: number) => {
                  Circle({ width: 4, height: 4 })
                    .fill(hasCourse ? this.themeColor : Color.Transparent)
                }, (hasCourse: boolean, index: number) => index.toString())
              }
              .height(4)
            }
            .width('100%')
            .padding({ top: 4, bottom: 4 })
            .justifyContent(FlexAlign.Center)
            .onClick(() => {
              if (cell.day !== 0) {
                this.displayDate = cell.date;
              }
            })
          }
        }, (cell: CalendarCell) => cell.date.getTime().toString())
      }
      .columnsTemplate('1fr 1fr 1fr 1fr 1fr 1fr 1fr')
      .rowsGap(2)
      .columnsGap(2)
      .width('100%')
      .margin({ bottom: 8 })
    }
    .width('100%')
    .padding({ left: 12, right: 12 })
    .backgroundColor(Color.White)
    .borderRadius(16)
    .margin({ left: 12, right: 12, top: 8 })
  }

  private calendarCells(): Array<CalendarCell> {
    const year = this.displayDate.getFullYear();
    const month = this.displayDate.getMonth();
    const firstDay = new Date(year, month, 1);
    const dayOfWeek = firstDay.getDay() === 0 ? 7 : firstDay.getDay();
    const daysInMonth = new Date(year, month + 1, 0).getDate();
    const cells: Array<CalendarCell> = [];
    const leading = dayOfWeek - 1;
    for (let i = 0; i < leading; i++) {
      const d = new Date(year, month, 1 - (leading - i));
      cells.push(new CalendarCell(d, 0, false));
    }
    for (let day = 1; day <= daysInMonth; day++) {
      cells.push(new CalendarCell(new Date(year, month, day), day, true));
    }
    const total = 42;
    while (cells.length < total) {
      const last = cells[cells.length - 1].date;
      const d = new Date(last);
      d.setDate(d.getDate() + 1);
      cells.push(new CalendarCell(d, 0, false));
    }
    return cells;
  }

  private calendarDots(cell: CalendarCell): Array<boolean> {
    if (cell.day === 0) {
      return [false, false, false];
    }
    const dayOfWeek = cell.date.getDay() === 0 ? 7 : cell.date.getDay();
    const semester = DataStore.get().getSelectedSemester();
    if (semester === null) {
      return [false, false, false];
    }
    const week = ScheduleUtils.weekNumberForDate(cell.date, semester);
    if (week <= 0) {
      return [false, false, false];
    }
    const courses = this.coursesForDay(dayOfWeek, week);
    const hasMorning = courses.some((c) => this.earliestSection(c, dayOfWeek) <= 5);
    const hasAfternoon = courses.some((c) => this.earliestSection(c, dayOfWeek) >= 6 && this.earliestSection(c, dayOfWeek) <= 10);
    const hasEvening = courses.some((c) => this.earliestSection(c, dayOfWeek) >= 11);
    return [hasMorning, hasAfternoon, hasEvening];
  }

  private isSameDay(a: Date, b: Date): boolean {
    return a.getFullYear() === b.getFullYear() &&
      a.getMonth() === b.getMonth() &&
      a.getDate() === b.getDate();
  }
}

export class CalendarCell {
  date: Date;
  day: number;
  inMonth: boolean;

  constructor(date: Date, day: number, inMonth: boolean) {
    this.date = date;
    this.day = day;
    this.inMonth = inMonth;
  }
}
