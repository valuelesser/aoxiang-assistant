/**
 * 管理页 —— 对应 Android 参考实现 ManageFragment
 * 学期管理 + 课程管理 + 导入/导出 JSON
 */
import { DataStore } from '../common/DataStore';
import { ScheduleModels } from '../model/ScheduleModels';
import { ScheduleUtils } from '../model/ScheduleUtils';
import { ScheduleImport, RawCourse } from '../model/ScheduleImport';

export interface ExportPayload {
  version: number;
  semesters: Array<ScheduleModels.SemesterJson>;
  courses: Array<ScheduleModels.CourseJson>;
}

@Component
export struct ManagePage {
  @StorageLink('themeColor') themeColor: string = '#2F80ED';
  @State semesters: Array<ScheduleModels.Semester> = [];
  @State selectedSemesterId: string = '';
  @State courses: Array<ScheduleModels.Course> = [];
  @State showAddSemester: boolean = false;
  @State showAddCourse: boolean = false;
  @State showImportDialog: boolean = false;

  // 新增学期表单
  @State newSemesterName: string = '';
  @State newSemesterStartDate: string = '';
  @State newSemesterWeekCount: string = '20';
  // 添加课程表单
  @State newCourseName: string = '';
  @State newCourseSchedule: string = '';
  @State newCourseTeacher: string = '';
  @State newCourseCredits: string = '';
  // 导入表单
  @State importJson: string = '';

  aboutToAppear(): void {
    this.refresh();
  }

  private refresh(): void {
    this.semesters = DataStore.get().getSemesters();
    this.selectedSemesterId = DataStore.get().getSelectedSemesterId();
    this.courses = DataStore.get().getCourses();
  }

  private semesterCourses(): Array<ScheduleModels.Course> {
    return this.courses.filter((course) => course.semesterId === this.selectedSemesterId);
  }

  private selectSemester(id: string): void {
    DataStore.get().setSelectedSemesterId(id);
    this.selectedSemesterId = id;
  }

  private deleteSemester(id: string): void {
    const remaining = this.semesters.filter((s) => s.id !== id);
    DataStore.get().setSemesters(remaining);
    const remainingCourses = this.courses.filter((c) => c.semesterId !== id);
    DataStore.get().setCourses(remainingCourses);
    if (this.selectedSemesterId === id) {
      const nextId = remaining.length > 0 ? remaining[0].id : '';
      DataStore.get().setSelectedSemesterId(nextId);
    }
    this.refresh();
  }

  private deleteCourse(id: string): void {
    const remaining = this.courses.filter((c) => c.id !== id);
    DataStore.get().setCourses(remaining);
    this.refresh();
  }

  build() {
    Stack() {
      Scroll() {
        Column({ space: 14 }) {
          // 学期管理卡片
          Column({ space: 10 }) {
            Row() {
              Text('学期管理')
                .fontSize(16)
                .fontWeight(FontWeight.Medium)
                .fontColor('#1A1A1A')
              Blank()
              Button('新增学期')
                .fontSize(12)
                .fontColor(Color.White)
                .backgroundColor(this.themeColor)
                .height(28)
                .padding({ left: 12, right: 12 })
                .borderRadius(14)
                .onClick(() => {
                  this.showAddSemester = true;
                })
            }
            .width('100%')

            if (this.semesters.length === 0) {
              Text('暂无学期，请先新增学期或从教务同步')
                .fontSize(13)
                .fontColor('#8A8A8E')
                .width('100%')
                .textAlign(TextAlign.Center)
                .padding({ top: 12, bottom: 12 })
            } else {
              ForEach(this.semesters, (semester: ScheduleModels.Semester) => {
                Row() {
                  Radio({ value: semester.id, group: 'semesterGroup' })
                    .checked(this.selectedSemesterId === semester.id)
                    .radioStyle({ checkedBackgroundColor: this.themeColor })
                    .onChange((isChecked: boolean) => {
                      if (isChecked) {
                        this.selectSemester(semester.id);
                      }
                    })
                  Column({ space: 2 }) {
                    Text(semester.name)
                      .fontSize(14)
                      .fontWeight(FontWeight.Medium)
                      .fontColor('#1A1A1A')
                    Text(`${semester.startDate} ~ ${semester.endDate} · ${semester.weekCount}周`)
                      .fontSize(11)
                      .fontColor('#8A8A8E')
                  }
                  .alignItems(HorizontalAlign.Start)
                  .layoutWeight(1)
                  Text('删除')
                    .fontSize(12)
                    .fontColor('#E53935')
                    .padding({ left: 10, right: 10, top: 6, bottom: 6 })
                    .onClick(() => {
                      this.deleteSemester(semester.id);
                    })
                }
                .width('100%')
                .padding({ top: 6, bottom: 6 })
              }, (semester: ScheduleModels.Semester) => semester.id)
            }
          }
          .width('100%')
          .padding(16)
          .backgroundColor(Color.White)
          .borderRadius(16)

          // 课程管理卡片
          Column({ space: 10 }) {
            Row() {
              Text('课程管理')
                .fontSize(16)
                .fontWeight(FontWeight.Medium)
                .fontColor('#1A1A1A')
              Blank()
              Button('添加课程')
                .fontSize(12)
                .fontColor(Color.White)
                .backgroundColor(this.themeColor)
                .height(28)
                .padding({ left: 12, right: 12 })
                .borderRadius(14)
                .onClick(() => {
                  this.showAddCourse = true;
                })
            }
            .width('100%')

            if (this.semesterCourses().length === 0) {
              Text('当前学期暂无课程')
                .fontSize(13)
                .fontColor('#8A8A8E')
                .width('100%')
                .textAlign(TextAlign.Center)
                .padding({ top: 12, bottom: 12 })
            } else {
              ForEach(this.semesterCourses(), (course: ScheduleModels.Course) => {
                Row({ space: 10 }) {
                  Column()
                    .width(4)
                    .height(38)
                    .borderRadius(2)
                    .backgroundColor(course.color === null ? this.themeColor : course.color)
                  Column({ space: 2 }) {
                    Text(course.name)
                      .fontSize(14)
                      .fontWeight(FontWeight.Medium)
                      .fontColor('#1A1A1A')
                    Text(ScheduleUtils.formatCourseTime(course))
                      .fontSize(11)
                      .fontColor('#8A8A8E')
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                  }
                  .alignItems(HorizontalAlign.Start)
                  .layoutWeight(1)
                  Text('删除')
                    .fontSize(12)
                    .fontColor('#E53935')
                    .padding({ left: 10, right: 10, top: 6, bottom: 6 })
                    .onClick(() => {
                      this.deleteCourse(course.id);
                    })
                }
                .width('100%')
                .padding({ top: 4, bottom: 4 })
              }, (course: ScheduleModels.Course) => course.id)
            }
          }
          .width('100%')
          .padding(16)
          .backgroundColor(Color.White)
          .borderRadius(16)

          // 导入导出
          Column({ space: 10 }) {
            Text('数据管理')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor('#1A1A1A')
              .width('100%')

            Row({ space: 10 }) {
              Button('导出 JSON')
                .fontSize(13)
                .fontColor(this.themeColor)
                .backgroundColor('#EAF2FD')
                .height(38)
                .layoutWeight(1)
                .borderRadius(19)
                .onClick(() => {
                  this.exportData();
                })
              Button('导入 JSON')
                .fontSize(13)
                .fontColor(this.themeColor)
                .backgroundColor('#EAF2FD')
                .height(38)
                .layoutWeight(1)
                .borderRadius(19)
                .onClick(() => {
                  this.showImportDialog = true;
                })
            }
            .width('100%')

            Text('支持从「教务系统同步」或手动粘贴 JSON 导入课表数据')
              .fontSize(12)
              .fontColor('#8A8A8E')
              .width('100%')
          }
          .width('100%')
          .padding(16)
          .backgroundColor(Color.White)
          .borderRadius(16)
        }
        .width('100%')
        .padding(16)
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#F5F6FA')
      .scrollBar(BarState.Off)
      .align(Alignment.Top)

      // 新增学期弹窗
      if (this.showAddSemester) {
        this.DialogMask()
        this.SemesterDialog()
      }

      // 添加课程弹窗
      if (this.showAddCourse) {
        this.DialogMask()
        this.CourseDialog()
      }

      // 导入弹窗
      if (this.showImportDialog) {
        this.DialogMask()
        this.ImportDialog()
      }
    }
    .width('100%')
    .height('100%')
  }

  private exportData(): void {
    const semesters: Array<ScheduleModels.SemesterJson> = [];
    for (const semester of this.semesters) {
      semesters.push(semester.json());
    }
    const courses: Array<ScheduleModels.CourseJson> = [];
    for (const course of this.courses) {
      courses.push(course.json());
    }
    const data: ExportPayload = {
      version: 1,
      semesters: semesters,
      courses: courses
    };
    this.copyToClipboard(JSON.stringify(data));
  }

  private copyToClipboard(text: string): void {
    // 导出数据打印到日志，便于用户从 DevEco 日志中获取
    console.info('[Export] ' + text);
    try {
      this.getUIContext().getPromptAction().showToast({ message: '已导出，JSON 数据见 DevEco 日志' });
    } catch (e) {
      // ignore
    }
  }

  private addSemester(): void {
    const name = this.newSemesterName.trim();
    if (name === '') {
      return;
    }
    const weeks = parseInt(this.newSemesterWeekCount, 10);
    const count = Number.isNaN(weeks) || weeks <= 0 ? 20 : weeks;
    const start = this.newSemesterStartDate.trim() !== '' ? this.newSemesterStartDate.trim() : this.defaultStartDate();
    const end = this.endDateFromStart(start, count);
    const semester = new ScheduleModels.Semester(
      `semester-${Date.now()}`,
      name,
      start,
      end,
      count,
      13,
      ScheduleModels.buildDefaultSectionTimes(13)
    );
    const updated = this.semesters.concat([semester]);
    DataStore.get().setSemesters(updated);
    DataStore.get().setSelectedSemesterId(semester.id);
    this.showAddSemester = false;
    this.newSemesterName = '';
    this.newSemesterStartDate = '';
    this.newSemesterWeekCount = '20';
    this.refresh();
  }

  private defaultStartDate(): string {
    const now = new Date();
    return `${now.getFullYear()}-${this.pad2(now.getMonth() + 1)}-${this.pad2(now.getDate())}`;
  }

  private endDateFromStart(start: string, weeks: number): string {
    const parts = start.split('-');
    const date = new Date(parseInt(parts[0], 10), parseInt(parts[1], 10) - 1, parseInt(parts[2], 10));
    date.setDate(date.getDate() + weeks * 7 - 1);
    return `${date.getFullYear()}-${this.pad2(date.getMonth() + 1)}-${this.pad2(date.getDate())}`;
  }

  private addCourse(): void {
    const name = this.newCourseName.trim();
    if (name === '') {
      return;
    }
    if (this.selectedSemesterId === '') {
      return;
    }
    const raw = new RawCourse();
    raw.name = name;
    raw.teacher = this.newCourseTeacher.trim() === '' ? null : this.newCourseTeacher.trim();
    raw.credits = this.newCourseCredits.trim() === '' ? null : parseFloat(this.newCourseCredits);
    raw.scheduleText = this.newCourseSchedule.trim() === '' ? null : this.newCourseSchedule.trim();
    const converted = ScheduleImport.convertToCourses([raw], this.selectedSemesterId, null);
    if (converted.length === 0) {
      const course = new ScheduleModels.Course(`course-${Date.now()}`, name, this.selectedSemesterId, []);
      course.teacher = raw.teacher;
      course.credits = raw.credits;
      course.color = this.themeColor;
      DataStore.get().setCourses(this.courses.concat([course]));
    } else {
      const course = converted[0];
      course.color = course.color === null ? this.themeColor : course.color;
      DataStore.get().setCourses(this.courses.concat([course]));
    }
    this.showAddCourse = false;
    this.newCourseName = '';
    this.newCourseSchedule = '';
    this.newCourseTeacher = '';
    this.newCourseCredits = '';
    this.refresh();
  }

  private importData(): void {
    const text = this.importJson.trim();
    if (text === '') {
      return;
    }
    try {
      const root = JSON.parse(text) as Record<string, Object>;
      const rawSemesters = root['semesters'] as Array<Object> | null;
      const rawCourses = root['courses'] as Array<Object> | null;
      if (rawSemesters !== null) {
        const parsedSemesters: Array<ScheduleModels.Semester> = [];
        for (const item of rawSemesters) {
          parsedSemesters.push(ScheduleModels.Semester.from(item as Record<string, Object>));
        }
        if (parsedSemesters.length > 0) {
          DataStore.get().setSemesters(parsedSemesters);
        }
      }
      if (rawCourses !== null) {
        const parsedCourses: Array<ScheduleModels.Course> = [];
        for (const item of rawCourses) {
          parsedCourses.push(ScheduleModels.Course.from(item as Record<string, Object>));
        }
        if (parsedCourses.length > 0) {
          DataStore.get().setCourses(parsedCourses);
        }
      }
      this.showImportDialog = false;
      this.importJson = '';
      this.refresh();
    } catch (e) {
      try {
        this.getUIContext().getPromptAction().showToast({ message: '导入失败：JSON 格式错误' });
      } catch (e2) {
        // ignore
      }
    }
  }

  private pad2(value: number): string {
    return value < 10 ? `0${value}` : `${value}`;
  }

  @Builder
  DialogMask() {
    Column()
      .width('100%')
      .height('100%')
      .backgroundColor('#66000000')
      .onClick(() => {
        this.showAddSemester = false;
        this.showAddCourse = false;
        this.showImportDialog = false;
      })
  }

  @Builder
  SemesterDialog() {
    Column({ space: 12 }) {
      Text('新增学期')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor('#1A1A1A')
      TextInput({ placeholder: '学期名称（如：2025-2026学年第一学期）', text: this.newSemesterName })
        .height(40)
        .onChange((value: string) => {
          this.newSemesterName = value;
        })
      TextInput({ placeholder: '开学日期（如：2025-09-01）', text: this.newSemesterStartDate })
        .height(40)
        .onChange((value: string) => {
          this.newSemesterStartDate = value;
        })
      TextInput({ placeholder: '周数（默认 20）', text: this.newSemesterWeekCount })
        .height(40)
        .type(InputType.Number)
        .onChange((value: string) => {
          this.newSemesterWeekCount = value;
        })
      Row({ space: 12 }) {
        Button('取消')
          .fontSize(14)
          .fontColor('#8A8A8E')
          .backgroundColor('#F0F0F3')
          .layoutWeight(1)
          .height(38)
          .borderRadius(19)
          .onClick(() => {
            this.showAddSemester = false;
          })
        Button('保存')
          .fontSize(14)
          .fontColor(Color.White)
          .backgroundColor(this.themeColor)
          .layoutWeight(1)
          .height(38)
          .borderRadius(19)
          .onClick(() => {
            this.addSemester();
          })
      }
      .width('100%')
    }
    .width('86%')
    .padding(20)
    .backgroundColor(Color.White)
    .borderRadius(20)
    .alignSelf(ItemAlign.Center)
    .position({ y: '30%' })
  }

  @Builder
  CourseDialog() {
    Column({ space: 12 }) {
      Text('添加课程')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor('#1A1A1A')
      TextInput({ placeholder: '课程名称', text: this.newCourseName })
        .height(40)
        .onChange((value: string) => {
          this.newCourseName = value;
        })
      TextInput({ placeholder: '上课时间（如：周一1-2节 1-16周 教学楼A101）', text: this.newCourseSchedule })
        .height(40)
        .onChange((value: string) => {
          this.newCourseSchedule = value;
        })
      TextInput({ placeholder: '教师', text: this.newCourseTeacher })
        .height(40)
        .onChange((value: string) => {
          this.newCourseTeacher = value;
        })
      TextInput({ placeholder: '学分', text: this.newCourseCredits })
        .height(40)
        .type(InputType.Number)
        .onChange((value: string) => {
          this.newCourseCredits = value;
        })
      Row({ space: 12 }) {
        Button('取消')
          .fontSize(14)
          .fontColor('#8A8A8E')
          .backgroundColor('#F0F0F3')
          .layoutWeight(1)
          .height(38)
          .borderRadius(19)
          .onClick(() => {
            this.showAddCourse = false;
          })
        Button('保存')
          .fontSize(14)
          .fontColor(Color.White)
          .backgroundColor(this.themeColor)
          .layoutWeight(1)
          .height(38)
          .borderRadius(19)
          .onClick(() => {
            this.addCourse();
          })
      }
      .width('100%')
    }
    .width('86%')
    .padding(20)
    .backgroundColor(Color.White)
    .borderRadius(20)
    .alignSelf(ItemAlign.Center)
    .position({ y: '25%' })
  }

  @Builder
  ImportDialog() {
    Column({ space: 12 }) {
      Text('导入 JSON')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor('#1A1A1A')
      TextArea({ placeholder: '粘贴导出的 JSON 数据（含 semesters/courses 字段）', text: this.importJson })
        .height(160)
        .onChange((value: string) => {
          this.importJson = value;
        })
      Row({ space: 12 }) {
        Button('取消')
          .fontSize(14)
          .fontColor('#8A8A8E')
          .backgroundColor('#F0F0F3')
          .layoutWeight(1)
          .height(38)
          .borderRadius(19)
          .onClick(() => {
            this.showImportDialog = false;
          })
        Button('导入')
          .fontSize(14)
          .fontColor(Color.White)
          .backgroundColor(this.themeColor)
          .layoutWeight(1)
          .height(38)
          .borderRadius(19)
          .onClick(() => {
            this.importData();
          })
      }
      .width('100%')
    }
    .width('86%')
    .padding(20)
    .backgroundColor(Color.White)
    .borderRadius(20)
    .alignSelf(ItemAlign.Center)
    .position({ y: '25%' })
  }
}
