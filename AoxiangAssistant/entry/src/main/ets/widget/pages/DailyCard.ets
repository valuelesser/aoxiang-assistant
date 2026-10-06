class CardCourse {
  time: string = '';
  section: string = '';
  name: string = '';
  loc: string = '';
  teacher: string = '';
  color: string = '#1E88E5';
}

class DailyData {
  title: string = '今日课表';
  date: string = '';
  hint: string = '';
  empty: boolean = true;
  courses: CardCourse[] = [];
}

const dailyStorage = new LocalStorage();

@Entry(dailyStorage)
@Component
struct DailyCard {
  @LocalStorageProp('cardData') @Watch('onDataChanged') cardData: string = '';
  @State title: string = '今日课表';
  @State date: string = '';
  @State hint: string = '';
  @State empty: boolean = true;
  @State courses: CardCourse[] = [];

  aboutToAppear(): void {
    this.parseData();
  }

  onDataChanged(propName: string): void {
    this.parseData();
  }

  private parseData(): void {
    const data: DailyData = new DailyData();
    if (this.cardData.length > 0) {
      try {
        const obj: Record<string, Object> = JSON.parse(this.cardData) as Record<string, Object>;
        data.title = (obj['title'] ?? '今日课表') as string;
        data.date = (obj['date'] ?? '') as string;
        data.hint = (obj['hint'] ?? '') as string;
        data.empty = (obj['empty'] ?? true) === true;
        const rawCourses: Object[] = obj['courses'] as Object[];
        if (rawCourses !== undefined && rawCourses !== null) {
          for (let i = 0; i < rawCourses.length; i++) {
            const c: Record<string, Object> = rawCourses[i] as Record<string, Object>;
            const item: CardCourse = new CardCourse();
            item.time = (c['time'] ?? '') as string;
            item.section = (c['section'] ?? '') as string;
            item.name = (c['name'] ?? '') as string;
            item.loc = (c['loc'] ?? '') as string;
            item.teacher = (c['teacher'] ?? '') as string;
            item.color = (c['color'] ?? '#1E88E5') as string;
            data.courses.push(item);
          }
        }
      } catch (e) {
        console.error(`DailyCard parse error: ${e}`);
      }
    }
    this.title = data.title;
    this.date = data.date;
    this.hint = data.hint;
    this.empty = data.empty;
    this.courses = data.courses;
  }

  private timeLine(item: CardCourse): string {
    if (item.section.length > 0 && item.time.length > 0) {
      return `${item.section}  ${item.time}`;
    }
    return item.time.length > 0 ? item.time : item.section;
  }

  private emptyHint(): string {
    return this.hint.length > 0 ? this.hint : '今天没有课了';
  }

  @Builder
  Header() {
    Row() {
      Text('今日课程')
        .fontSize(11)
        .fontColor($r('app.color.widget_muted_text'))
        .fontWeight(FontWeight.Bold)
      if (this.date.length > 0) {
        Text(this.date)
          .fontSize(10)
          .fontColor($r('app.color.widget_muted_text'))
          .margin({ left: 4 })
      }
    }
    .width('100%')
    .padding({ bottom: 3 })
  }

  @Builder
  CourseRow(item: CardCourse) {
    Row() {
      Text('●')
        .fontSize(10)
        .fontColor(item.color)
        .width(10)
        .textAlign(TextAlign.Start)

      Column() {
        Text(item.name)
          .fontSize(11)
          .fontColor($r('app.color.widget_name_text'))
          .fontWeight(FontWeight.Bold)
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
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .padding(5)
    .borderRadius(5)
    .backgroundColor($r('app.color.widget_row_bg'))
    .alignItems(VerticalAlign.Top)
  }

  build() {
    Column() {
      this.Header()

      if (this.courses.length > 0) {
        List({ space: 3 }) {
          ForEach(this.courses, (item: CardCourse, idx: number) => {
            ListItem() {
              this.CourseRow(item)
            }
          }, (item: CardCourse, idx: number) => `${item.section}_${item.name}_${idx}`)
        }
        .layoutWeight(1)
        .width('100%')
        .scrollBar(BarState.Auto)
      } else {
        Column() {
          Text(this.emptyHint())
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
