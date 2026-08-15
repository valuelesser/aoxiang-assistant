/**
 * 主框架 —— 五标签底部导航（首页/课表/成绩/管理/设置）
 * 对应 Android 参考实现 MainActivity 的五个 Fragment。
 * 后台挂载 SyncAutomation（Web 自动化同步组件）。
 */
import { HomePage } from './HomePage';
import { SchedulePage } from './SchedulePage';
import { GradesPage } from './GradesPage';
import { ManagePage } from './ManagePage';
import { SettingsPage } from './SettingsPage';
import { DataStore } from '../common/DataStore';
import { SyncAutomation } from '../common/SyncAutomation';

@Entry
@Component
struct Index {
  @StorageLink('themeColor') themeColor: string = DataStore.KEY_THEME_COLOR;
  @State currentIndex: number = 0;

  build() {
    Stack() {
      Column() {
        Tabs({ barPosition: BarPosition.End, index: this.currentIndex }) {
          TabContent() {
            HomePage()
          }
          .tabBar(this.TabBuilder('首页', $r('app.media.ic_home'), 0))

          TabContent() {
            SchedulePage()
          }
          .tabBar(this.TabBuilder('课表', $r('app.media.ic_schedule'), 1))

          TabContent() {
            GradesPage()
          }
          .tabBar(this.TabBuilder('成绩', $r('app.media.ic_grades'), 2))

          TabContent() {
            ManagePage()
          }
          .tabBar(this.TabBuilder('管理', $r('app.media.ic_manage'), 3))

          TabContent() {
            SettingsPage()
          }
          .tabBar(this.TabBuilder('设置', $r('app.media.ic_settings'), 4))
        }
        .onChange((index: number) => {
          this.currentIndex = index;
        })
        .scrollable(false)
        .barHeight(56)
        .barBackgroundColor(Color.White)
        .width('100%')
        .height('100%')
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#F5F6FA')

      // 后台自动化同步组件（隐藏，尺寸为 0）
      SyncAutomation()
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  TabBuilder(title: string, icon: Resource, index: number) {
    Column({ space: 2 }) {
      Image(icon)
        .width(24)
        .height(24)
        .fillColor(this.currentIndex === index ? this.themeColor : '#9AA0A6')
      Text(title)
        .fontSize(11)
        .fontColor(this.currentIndex === index ? this.themeColor : '#9AA0A6')
        .fontWeight(this.currentIndex === index ? FontWeight.Medium : FontWeight.Normal)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }
}
