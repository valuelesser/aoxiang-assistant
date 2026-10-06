class WCourse {
  time: string = '';
  name: string = '';
  loc: string = '';
  color: string = '#1E88E5';
}

class WDay {
  label: string = '';
  date: string = '';
  today: boolean = false;
  empty: boolean = true;
  courses: WCourse[] = [];
}

class WData {
  title: string = '每周课表';
  hint: string = '';
  empty: boolean = true;
  days: WDay[] = [];
}

const weeklyStorage = new LocalStorage();

@Entry(weeklyStorage)
@Component
struct WeeklyCard {
  @LocalStorageProp('cardData') @Watch('onDataChanged') cardData: string = '';
  @State title: string = '每周课表';
  @State hint: string = '';
  @State days: WDay[] = [];

  aboutToAppear(): void {
    this.parseData();
  }

  onDataChanged(propName: string): void {
    this.parseData();
  }

  private parseData(): void {
    const data: WData = new WData();
    if (this.cardData.length > 0) {
      try {
        const obj: Record<string, Object> = JSON.parse(this.cardData) as Record<string, Object>;
        data.title = (obj['title'] ?? '每周课表') as string;
        data.hint = (obj['hint'] ?? '') as string;
        data.empty = (obj['empty'] ?? true) === true;
        const rawDays: Object[] = obj['days'] as Object[];
        if (rawDays !== undefined && rawDays !== null) {
          for (let di = 0; di < rawDays.length; di++) {
            const d: Record<string, Object> = rawDays[di] as Record<string, Object>;
            const day: WDay = new WDay();
            day.label = (d['label'] ?? '') as string;
            day.date = (d['date'] ?? '') as string;
            day.today = (d['today'] ?? false) === true;
            day.empty = (d['empty'] ?? true) === true;
            const rawCourses: Object[] = d['courses'] as Object[];
            if (rawCourses !== undefined && rawCourses !== null) {
              for (let ci = 0; ci < rawCourses.length; ci++) {
                const c: Record<string, Object> = rawCourses[ci] as Record<string, Object>;
                const item: WCourse = new WCourse();
                item.time = (c['time'] ?? '') as string;
                item.name = (c['name'] ?? '') as string;
                item.loc = (c['loc'] ?? '') as string;
                item.color = (c['color'] ?? '#1E88E5') as string;
                day.courses.push(item);
              }
            }
            data.days.push(day);
          }
        }
      } catch (e) {
        console.error(`WeeklyCard parse error: ${e}`);
      }
    }
    if (data.days.length === 0) {
      const labels: string[] = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
      for (let i = 0; i < labels.length; i++) {
        const day: WDay = new WDay();
        day.label = labels[i];
        day.empty = true;
        data.days.push(day);
      }
    }
    this.title = data.title;
    this.hint = data.hint;
    this.days = data.days;
  }

  @Builder
  CourseRow(item: WCourse) {
    Row() {
      Text('●')
        .fontSize(10)
        .fontColor(item.color)
        .width(14)
        .textAlign(TextAlign.Start)

      Column() {
        Text(item.name)
          .fontSize(11)
          .fontColor($r('app.color.widget_name_text'))
          .fontWeight(FontWeight.Bold)
          .width('100%')
        if (item.time.length > 0) {
          Text(item.time)
            .fontSize(10)
            .fontColor($r('app.color.widget_muted_text'))
            .margin({ top: 1 })
            .width('100%')
        }
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
    .constraintSize({ minHeight: 24 })
    .alignItems(VerticalAlign.Top)
    .margin({ bottom: 3 })
  }

  @Builder
  DayBlock(day: WDay) {
    Column() {
      Row() {
        Text(day.label)
          .fontSize(11)
          .fontWeight(FontWeight.Bold)
          .fontColor(day.today ? $r('app.color.accent') : $r('app.color.widget_name_text'))
        if (day.date.length > 0) {
          Text(day.date)
            .fontSize(10)
            .fontColor($r('app.color.widget_muted_text'))
            .margin({ left: 4 })
        }
      }
      .width('100%')
      .margin({ bottom: 3 })

      if (day.courses.length > 0) {
        ForEach(day.courses, (item: WCourse, idx: number) => {
          this.CourseRow(item)
        }, (item: WCourse, idx: number) => `${day.label}_${item.name}_${item.time}_${idx}`)
      } else {
        Text('暂无课程')
          .fontSize(10)
          .fontColor($r('app.color.widget_muted_text'))
          .width('100%')
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .margin({ bottom: 4 })
  }

  build() {
    Column() {
      Row() {
        Text(this.title)
          .fontSize(12)
          .fontColor($r('app.color.widget_muted_text'))
          .fontWeight(FontWeight.Bold)
      }
      .width('100%')
      .justifyContent(FlexAlign.Start)
      .padding({ bottom: 4 })

      if (this.hint.length > 0) {
        Column() {
          Text(this.hint)
            .fontSize(12)
            .fontColor($r('app.color.widget_muted_text'))
            .textAlign(TextAlign.Center)
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      } else {
        List({ space: 4 }) {
          ForEach(this.days, (day: WDay, idx: number) => {
            ListItem() {
              this.DayBlock(day)
            }
          }, (day: WDay, idx: number) => `wday_${idx}_${day.label}`)
        }
        .layoutWeight(1)
        .width('100%')
        .scrollBar(BarState.Auto)
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
