class TTCourse {
  time: string = '';
  section: string = '';
  name: string = '';
  loc: string = '';
  teacher: string = '';
  color: string = '#1E88E5';
}

class TTDay {
  label: string = '';
  date: string = '';
  empty: boolean = true;
  courses: TTCourse[] = [];
}

class TTData {
  title: string = '今明课表';
  hint: string = '';
  days: TTDay[] = [];
}

const ttStorage = new LocalStorage();

@Entry(ttStorage)
@Component
struct TodayTomorrowCard {
  @LocalStorageProp('cardData') @Watch('onDataChanged') cardData: string = '';
  @State title: string = '今明课表';
  @State hint: string = '';
  @State days: TTDay[] = [];

  aboutToAppear(): void {
    this.parseData();
  }

  onDataChanged(propName: string): void {
    this.parseData();
  }

  private parseData(): void {
    const data: TTData = new TTData();
    if (this.cardData.length > 0) {
      try {
        const obj: Record<string, Object> = JSON.parse(this.cardData) as Record<string, Object>;
        data.title = (obj['title'] ?? '今明课表') as string;
        data.hint = (obj['hint'] ?? '') as string;
        const rawDays: Object[] = obj['days'] as Object[];
        if (rawDays !== undefined && rawDays !== null) {
          for (let di = 0; di < rawDays.length; di++) {
            const d: Record<string, Object> = rawDays[di] as Record<string, Object>;
            const day: TTDay = new TTDay();
            day.label = (d['label'] ?? '') as string;
            day.date = (d['date'] ?? '') as string;
            day.empty = (d['empty'] ?? true) === true;
            const rawCourses: Object[] = d['courses'] as Object[];
            if (rawCourses !== undefined && rawCourses !== null) {
              for (let ci = 0; ci < rawCourses.length; ci++) {
                const c: Record<string, Object> = rawCourses[ci] as Record<string, Object>;
                const item: TTCourse = new TTCourse();
                item.time = (c['time'] ?? '') as string;
                item.section = (c['section'] ?? '') as string;
                item.name = (c['name'] ?? '') as string;
                item.loc = (c['loc'] ?? '') as string;
                item.teacher = (c['teacher'] ?? '') as string;
                item.color = (c['color'] ?? '#1E88E5') as string;
                day.courses.push(item);
              }
            }
            data.days.push(day);
          }
        }
      } catch (e) {
        console.error(`TodayTomorrowCard parse error: ${e}`);
      }
    }
    while (data.days.length < 2) {
      const fallback: TTDay = new TTDay();
      fallback.label = data.days.length === 0 ? '今天' : '明天';
      fallback.empty = true;
      data.days.push(fallback);
    }
    this.title = data.title;
    this.hint = data.hint;
    this.days = data.days;
  }

  private dayAt(index: number): TTDay {
    return this.days[index];
  }

  private timeLine(item: TTCourse): string {
    if (item.section.length > 0 && item.time.length > 0) {
      return `${item.section}  ${item.time}`;
    }
    return item.time.length > 0 ? item.time : item.section;
  }

  private hasAnyCourse(): boolean {
    return this.dayAt(0).courses.length > 0 || this.dayAt(1).courses.length > 0;
  }

  private emptyText(dayIndex: number): string {
    return this.dayAt(dayIndex).label === '明天' ? '明天没有课了' : '今天没有课了';
  }

  @Builder
  CourseRow(item: TTCourse) {
    Column() {
      Row() {
        Text('●')
          .fontSize(10)
          .fontColor(item.color)
          .width(10)
          .textAlign(TextAlign.Start)
        Text(item.name)
          .fontSize(11)
          .fontColor($r('app.color.widget_name_text'))
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
      }
      .width('100%')

      Text(this.timeLine(item))
        .fontSize(10)
        .fontColor($r('app.color.widget_muted_text'))
        .margin({ top: 1 })
        .width('100%')

      if (item.loc.length > 0) {
        Text(item.loc)
          .fontSize(10)
          .fontColor($r('app.color.widget_muted_text'))
          .margin({ top: 1 })
          .width('100%')
      }
    }
    .width('100%')
    .padding(5)
    .borderRadius(5)
    .backgroundColor($r('app.color.widget_row_bg'))
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  DayColumn(day: TTDay, dayIndex: number) {
    Column() {
      if (day.courses.length > 0) {
        List({ space: 4 }) {
          ForEach(day.courses, (item: TTCourse, idx: number) => {
            ListItem() {
              this.CourseRow(item)
            }
          }, (item: TTCourse, idx: number) => `c_${dayIndex}_${idx}_${item.name}_${item.section}`)
        }
        .width('100%')
        .height('100%')
        .scrollBar(BarState.Auto)
      } else {
        Column() {
          Text(this.emptyText(dayIndex))
            .fontSize(10)
            .fontColor($r('app.color.widget_muted_text'))
            .textAlign(TextAlign.Center)
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      }
    }
    .layoutWeight(1)
    .height('100%')
  }

  @Builder
  Header() {
    Row() {
      Text(this.dayAt(0).label)
        .fontSize(12)
        .fontColor($r('app.color.widget_muted_text'))
        .fontWeight(FontWeight.Bold)
        .layoutWeight(1)

      Divider()
        .vertical(true)
        .strokeWidth(1)
        .color($r('app.color.widget_divider'))
        .height(12)
        .margin({ left: 7, right: 7 })

      Text(this.dayAt(1).label)
        .fontSize(12)
        .fontColor($r('app.color.widget_muted_text'))
        .fontWeight(FontWeight.Bold)
        .layoutWeight(1)
    }
    .width('100%')
    .padding({ bottom: 4 })
  }

  build() {
    Column() {
      this.Header()

      if (this.hasAnyCourse()) {
        Row() {
          this.DayColumn(this.dayAt(0), 0)

          Divider()
            .vertical(true)
            .strokeWidth(1)
            .color($r('app.color.widget_divider'))
            .margin({ left: 7, right: 7 })

          this.DayColumn(this.dayAt(1), 1)
        }
        .width('100%')
        .layoutWeight(1)
        .alignItems(VerticalAlign.Top)
      } else {
        Column() {
          Text(this.hint.length > 0 ? this.hint : '今天和明天都没有课')
            .fontSize(12)
            .fontColor($r('app.color.widget_muted_text'))
            .textAlign(TextAlign.Center)
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      }
    }
    .width('100%')
    .height('100%')
    .padding(10)
    .backgroundColor($r('app.color.widget_card_bg'))
    .border({ width: 1, color: $r('app.color.widget_card_stroke') })
    .borderRadius(16)
    .onClick(() => {
      postCardAction(this, {
        action: 'router',
        abilityName: 'EntryAbility'
      });
    })
  }
}
