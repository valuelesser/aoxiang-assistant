/**
 * 首页 —— 对应 Android 参考实现 HomeFragment
 * 展示：今日课程、GPA/加权均分、电费余额、课程统计
 */
import { DataStore } from '../common/DataStore';
import { ScheduleModels } from '../model/ScheduleModels';
import { ScheduleUtils } from '../model/ScheduleUtils';

@Component
export struct HomePage {
  @StorageLink('themeColor') themeColor: string = '#2F80ED';
  @State now: Date = new Date();

  aboutToAppear(): void {
    this.now = new Date();
  }

  private selectedCourses(): Array<ScheduleModels.Course> {
    const courses = DataStore.get().getCourses();
    const semesterId = DataStore.get().getSelectedSemesterId();
    return courses.filter((course) => course.semesterId === semesterId);
  }

  private todayCourses(): Array<ScheduleModels.Course> {
    const semester = DataStore.get().getSelectedSemester();
    if (semester === null) {
      return [];
    }
    const week = ScheduleUtils.weekNumberForDate(this.now, semester);
    const dayOfWeek = this.now.getDay() === 0 ? 7 : this.now.getDay();
    return this.selectedCourses().filter((course) => {
      for (const slot of course.timeSlots) {
        if (slot.dayOfWeek === dayOfWeek &&
          ScheduleUtils.matchesRepeatRule(week, slot.repeatRule) &&
          ScheduleUtils.isWeekInRange(week, slot.weekRange)) {
          return true;
        }
      }
      return false;
    });
  }

  private gpaInfo(): Array<number> {
    // 返回 [当前学期课程门数, 加权均分, 总学分]
    const courses = this.selectedCourses();
    let credits = 0;
    let weighted = 0;
    let included = 0;
    for (const course of courses) {
      if (course.credits !== null && course.credits > 0) {
        credits += course.credits;
      }
    }
    return [courses.length, credits, included];
  }

  private weekdayLabel(): string {
    const labels = ['日', '一', '二', '三', '四', '五', '六'];
    return `周${labels[this.now.getDay()]}`;
  }

  build() {
    Scroll() {
      Column({ space: 14 }) {
        // 顶部问候
        Row() {
          Column({ space: 4 }) {
            Text(this.greeting())
              .fontSize(22)
              .fontWeight(FontWeight.Bold)
              .fontColor('#1A1A1A')
            Text(this.dateText())
              .fontSize(13)
              .fontColor('#8A8A8E')
          }
          .alignItems(HorizontalAlign.Start)

          Blank()

          Row({ space: 6 }) {
            Image($r('app.media.ic_schedule'))
              .width(18)
              .height(18)
              .fillColor(this.themeColor)
            Text(`${this.weekLabel()}`)
              .fontSize(13)
              .fontColor(this.themeColor)
          }
          .padding({ left: 12, right: 12, top: 6, bottom: 6 })
          .backgroundColor(`${this.themeColor}1A`)
          .borderRadius(16)
        }
        .width('100%')
        .padding({ left: 4, right: 4, top: 8 })

        // 统计卡片
        Row({ space: 12 }) {
          this.StatCard('本学期课程', `${this.selectedCourses().length}`, '门')
          this.StatCard('总学分', `${this.totalCredits()}`, '分')
          this.StatCard('本周课程', `${this.weekCourseCount()}`, '节')
        }
        .width('100%')

        // 今日课程卡片
        Column() {
          Row() {
            Text('今日课程')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor('#1A1A1A')
            Blank()
            Text(this.weekdayLabel())
              .fontSize(13)
              .fontColor(this.themeColor)
          }
          .width('100%')

          if (this.todayCourses().length === 0) {
            Column({ space: 8 }) {
              Text('📚')
                .fontSize(36)
              Text('今天没有课程，好好休息吧')
                .fontSize(14)
                .fontColor('#8A8A8E')
            }
            .width('100%')
            .padding({ top: 28, bottom: 28 })
            .justifyContent(FlexAlign.Center)
          } else {
            Column({ space: 8 }) {
              ForEach(this.sortedTodayCourses(), (course: ScheduleModels.Course) => {
                this.CourseRow(course)
              }, (course: ScheduleModels.Course) => course.id)
            }
            .width('100%')
            .padding({ top: 4 })
          }
        }
        .width('100%')
        .padding(16)
        .backgroundColor(Color.White)
        .borderRadius(16)

        // 数据说明（成绩数据在"成绩"标签中管理）
        Row({ space: 8 }) {
          Image($r('app.media.ic_grades'))
            .width(18)
            .height(18)
            .fillColor('#8A8A8E')
          Text('成绩与绩点明细请前往「成绩」标签页查看')
            .fontSize(13)
            .fontColor('#8A8A8E')
        }
        .width('100%')
        .padding({ left: 4, top: 4, bottom: 8 })
      }
      .width('100%')
      .padding(16)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F6FA')
    .align(Alignment.Top)
    .scrollBar(BarState.Off)
  }

  private greeting(): string {
    const hour = this.now.getHours();
    if (hour < 6) {
      return '夜深了';
    }
    if (hour < 12) {
      return '早上好';
    }
    if (hour < 14) {
      return '中午好';
    }
    if (hour < 18) {
      return '下午好';
    }
    return '晚上好';
  }

  private dateText(): string {
    const weekdays = ['日', '一', '二', '三', '四', '五', '六'];
    return `${this.now.getFullYear()}年${this.now.getMonth() + 1}月${this.now.getDate()}日 星期${weekdays[this.now.getDay()]}`;
  }

  private weekLabel(): string {
    const semester = DataStore.get().getSelectedSemester();
    if (semester === null) {
      return '未设置学期';
    }
    const week = ScheduleUtils.weekNumberForDate(this.now, semester);
    return week <= 0 ? '假期中' : `第 ${week} 周`;
  }

  private totalCredits(): number {
    let credits = 0;
    for (const course of this.selectedCourses()) {
      if (course.credits !== null && course.credits > 0) {
        credits += course.credits;
      }
    }
    return credits;
  }

  private weekCourseCount(): number {
    const semester = DataStore.get().getSelectedSemester();
    if (semester === null) {
      return 0;
    }
    const week = ScheduleUtils.weekNumberForDate(this.now, semester);
    let count = 0;
    for (const course of this.selectedCourses()) {
      for (const slot of course.timeSlots) {
        if (ScheduleUtils.matchesRepeatRule(week, slot.repeatRule) &&
          ScheduleUtils.isWeekInRange(week, slot.weekRange)) {
          count += slot.classSections.length;
        }
      }
    }
    return count;
  }

  private sortedTodayCourses(): Array<ScheduleModels.Course> {
    const courses = this.todayCourses();
    courses.sort((a: ScheduleModels.Course, b: ScheduleModels.Course) => {
      return this.earliestSection(a) - this.earliestSection(b);
    });
    return courses;
  }

  private earliestSection(course: ScheduleModels.Course): number {
    let min = 99;
    for (const slot of course.timeSlots) {
      const day = this.now.getDay() === 0 ? 7 : this.now.getDay();
      if (slot.dayOfWeek === day) {
        for (const section of slot.classSections) {
          min = Math.min(min, section);
        }
      }
    }
    return min;
  }

  @Builder
  StatCard(title: string, value: string, unit: string) {
    Column({ space: 6 }) {
      Text(title)
        .fontSize(12)
        .fontColor('#8A8A8E')
      Row() {
        Text(value)
          .fontSize(26)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.themeColor)
        Text(unit)
          .fontSize(12)
          .fontColor('#8A8A8E')
          .margin({ bottom: 4 })
      }
      .alignItems(VerticalAlign.Bottom)
    }
    .layoutWeight(1)
    .padding({ top: 14, bottom: 14 })
    .backgroundColor(Color.White)
    .borderRadius(16)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  CourseRow(course: ScheduleModels.Course) {
    Row({ space: 12 }) {
      Column()
        .width(4)
        .height(40)
        .borderRadius(2)
        .backgroundColor(course.color === null ? this.themeColor : course.color)

      Column({ space: 2 }) {
        Text(course.name)
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor('#1A1A1A')
        Text(this.courseMeta(course))
          .fontSize(12)
          .fontColor('#8A8A8E')
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Text(this.sectionText(course))
        .fontSize(13)
        .fontColor(this.themeColor)
    }
    .width('100%')
    .padding({ top: 8, bottom: 8 })
  }

  private courseMeta(course: ScheduleModels.Course): string {
    const parts: Array<string> = [];
    let location = '';
    for (const slot of course.timeSlots) {
      if (slot.location !== null && slot.location !== '') {
        location = slot.location;
        break;
      }
    }
    if (location !== '') {
      parts.push(location);
    }
    if (course.teacher !== null && course.teacher !== '') {
      parts.push(course.teacher);
    }
    return parts.join(' · ');
  }

  private sectionText(course: ScheduleModels.Course): string {
    let sections: Array<number> = [];
    const day = this.now.getDay() === 0 ? 7 : this.now.getDay();
    for (const slot of course.timeSlots) {
      if (slot.dayOfWeek === day) {
        sections = sections.concat(slot.classSections);
      }
    }
    sections.sort((a, b) => a - b);
    return `${sections[0]}-${sections[sections.length - 1]}节`;
  }
}
