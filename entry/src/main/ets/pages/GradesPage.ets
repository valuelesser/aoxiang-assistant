/**
 * 成绩页 —— 对应 Android 参考实现 GradesFragment
 * 展示：成绩列表（科目/学分/成绩/绩点）、加权均分、总学分
 * 注意：原始 Android 版成绩数据来自同步服务采集，此处提供展示与管理能力，
 *       成绩数据存储于 Preferences（KEY_GRADES），由 SyncService 写入。
 */
import { DataStore, GradeItemData } from '../common/DataStore';
import { ScheduleModels } from '../model/ScheduleModels';

@Component
export struct GradesPage {
  @StorageLink('themeColor') themeColor: string = '#2F80ED';
  @State gradeItems: Array<GradeItemData> = [];

  aboutToAppear(): void {
    this.gradeItems = DataStore.get().getGradeItems();
  }

  private weightedAverage(): number {
    let weighted = 0;
    let credits = 0;
    for (const item of this.gradeItems) {
      if (item.credits > 0 && item.score > 0) {
        weighted += item.credits * item.score;
        credits += item.credits;
      }
    }
    return credits === 0 ? 0 : weighted / credits;
  }

  private totalCredits(): number {
    let credits = 0;
    for (const item of this.gradeItems) {
      credits += item.credits;
    }
    return credits;
  }

  private scoreColor(score: number): string {
    if (score >= 90) {
      return '#43A047';
    }
    if (score >= 80) {
      return '#1E88E5';
    }
    if (score >= 70) {
      return '#FB8C00';
    }
    if (score >= 60) {
      return '#F4511E';
    }
    return '#E53935';
  }

  private gradePoint(score: number): number {
    if (score >= 90) {
      return 4.0;
    }
    if (score >= 85) {
      return 3.7;
    }
    if (score >= 82) {
      return 3.3;
    }
    if (score >= 78) {
      return 3.0;
    }
    if (score >= 75) {
      return 2.7;
    }
    if (score >= 72) {
      return 2.3;
    }
    if (score >= 68) {
      return 2.0;
    }
    if (score >= 64) {
      return 1.5;
    }
    if (score >= 60) {
      return 1.0;
    }
    return 0.0;
  }

  build() {
    Column() {
      // 汇总卡片
      Row({ space: 12 }) {
        this.SummaryCard('加权均分', `${this.weightedAverage().toFixed(2)}`, this.themeColor)
        this.SummaryCard('总学分', `${this.totalCredits().toFixed(1)}`, '#1E88E5')
        this.SummaryCard('课程数', `${this.gradeItems.length}`, '#43A047')
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12 })

      // 成绩列表
      Scroll() {
        Column({ space: 10 }) {
          if (this.gradeItems.length === 0) {
            Column({ space: 10 }) {
              Text('📊')
                .fontSize(40)
              Text('暂无成绩数据')
                .fontSize(15)
                .fontColor('#1A1A1A')
                .fontWeight(FontWeight.Medium)
              Text('在「设置」中登录并同步后，成绩将显示在这里')
                .fontSize(13)
                .fontColor('#8A8A8E')
                .textAlign(TextAlign.Center)
            }
            .width('100%')
            .padding({ top: 60, bottom: 60 })
            .justifyContent(FlexAlign.Center)
          } else {
            ForEach(this.gradeItems, (item: GradeItemData, index: number) => {
              Row() {
                Column({ space: 4 }) {
                  Text(item.name)
                    .fontSize(15)
                    .fontWeight(FontWeight.Medium)
                    .fontColor('#1A1A1A')
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                  Row({ space: 8 }) {
                    Text(`${item.credits} 学分`)
                      .fontSize(12)
                      .fontColor('#8A8A8E')
                    if (item.semester !== '') {
                      Text(item.semester)
                        .fontSize(12)
                        .fontColor('#8A8A8E')
                    }
                  }
                }
                .alignItems(HorizontalAlign.Start)
                .layoutWeight(1)

                Column({ space: 2 }) {
                  Text(`${item.score}`)
                    .fontSize(18)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(this.scoreColor(item.score))
                  Text(`绩点 ${this.gradePoint(item.score).toFixed(1)}`)
                    .fontSize(11)
                    .fontColor('#8A8A8E')
                }
                .alignItems(HorizontalAlign.End)
              }
              .width('100%')
              .padding(14)
              .backgroundColor(Color.White)
              .borderRadius(14)
            }, (item: GradeItemData) => `${item.name}-${item.semester}`)
          }
        }
        .width('100%')
        .padding(16)
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .align(Alignment.Top)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F6FA')
  }

  @Builder
  SummaryCard(title: string, value: string, color: string) {
    Column({ space: 4 }) {
      Text(title)
        .fontSize(12)
        .fontColor('#8A8A8E')
      Text(value)
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .fontColor(color)
    }
    .layoutWeight(1)
    .padding({ top: 14, bottom: 14 })
    .backgroundColor(Color.White)
    .borderRadius(16)
    .alignItems(HorizontalAlign.Center)
  }
}
