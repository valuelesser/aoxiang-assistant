const elecStorage = new LocalStorage();

@Entry(elecStorage)
@Component
struct ElectricityCard {
  @LocalStorageProp('cardData') @Watch('onDataChanged') cardData: string = '';
  @State value: string = '--';
  @State unit: string = '度';
  @State empty: boolean = true;
  @State hint: string = '打开应用查询电费';
  @State updated: string = '';

  aboutToAppear(): void {
    this.parseData();
  }

  onDataChanged(propName: string): void {
    this.parseData();
  }

  private parseData(): void {
    if (this.cardData.length > 0) {
      try {
        const obj: Record<string, Object> = JSON.parse(this.cardData) as Record<string, Object>;
        this.value = (obj['value'] ?? '--') as string;
        this.unit = (obj['unit'] ?? '度') as string;
        this.empty = (obj['empty'] ?? true) === true;
        this.hint = (obj['hint'] ?? '打开应用查询电费') as string;
        this.updated = (obj['updated'] ?? '') as string;
      } catch (e) {
        console.error(`ElectricityCard parse error: ${e}`);
      }
    }
  }

  build() {
    Column() {
      Text('剩余电费')
        .fontSize(11)
        .fontColor($r('app.color.widget_muted_text'))
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .textAlign(TextAlign.Center)

      if (this.empty) {
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
        Row() {
          Text(this.value)
            .fontSize(28)
            .fontColor($r('app.color.widget_name_text'))
            .fontWeight(FontWeight.Bold)
          Text(this.unit)
            .fontSize(12)
            .fontColor($r('app.color.widget_muted_text'))
            .margin({ left: 2 })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(VerticalAlign.Bottom)

        if (this.updated.length > 0) {
          Text(`更新于 ${this.updated}`)
            .fontSize(9)
            .fontColor($r('app.color.widget_muted_text'))
            .width('100%')
            .textAlign(TextAlign.End)
        }
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
