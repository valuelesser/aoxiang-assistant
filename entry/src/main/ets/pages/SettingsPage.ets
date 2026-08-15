/**
 * 设置页 —— 对应 Android 参考实现 SettingsFragment
 * 账号登录、深色模式、主题色、同步间隔、通知开关、电费提醒
 */
import { DataStore } from '../common/DataStore';
import { ScheduleModels } from '../model/ScheduleModels';
import { LoginDialog } from './LoginDialog';
import { SyncScheduler } from '../common/SyncService';

@Component
export struct SettingsPage {
  @StorageLink('themeColor') themeColor: string = '#2F80ED';
  @StorageLink('darkMode') darkMode: boolean = false;
  @StorageLink('syncEnabled') syncEnabled: boolean = false;
  @StorageLink('syncInterval') syncInterval: number = 720;
  @StorageLink('notifyEnabled') notifyEnabled: boolean = true;
  @StorageLink('electricityReminder') electricityReminder: boolean = true;
  @StorageLink('electricityThreshold') electricityThreshold: number = 10;
  @StorageLink('username') username: string = '';
  @StorageLink('syncLastTime') syncLastTime: string = '';
  @State showLogin: boolean = false;
  @State showIntervalPicker: boolean = false;
  @State showThresholdPicker: boolean = false;
  @State intervalSelected: number = 720;
  @State thresholdSelected: number = 10;

  private loggedIn(): boolean {
    return this.username !== '';
  }

  build() {
    Stack() {
      Scroll() {
        Column({ space: 14 }) {
          // 账号卡片
          Column({ space: 12 }) {
            Row({ space: 12 }) {
              Column() {
                Text(this.loggedIn() ? this.username.substring(0, 1).toUpperCase() : '未')
                  .fontSize(18)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(Color.White)
              }
              .width(44)
              .height(44)
              .borderRadius(22)
              .backgroundColor(this.themeColor)
              .justifyContent(FlexAlign.Center)
              .alignItems(HorizontalAlign.Center)

              Column({ space: 2 }) {
                Text(this.loggedIn() ? this.username : '未登录')
                  .fontSize(15)
                  .fontWeight(FontWeight.Medium)
                  .fontColor('#1A1A1A')
                Text(this.loggedIn() ? '已配置教务账号，可同步课表/成绩' : '登录后可同步课表、成绩与电费')
                  .fontSize(12)
                  .fontColor('#8A8A8E')
              }
              .alignItems(HorizontalAlign.Start)
              .layoutWeight(1)

              Text(this.loggedIn() ? '切换' : '去登录')
                .fontSize(13)
                .fontColor(this.themeColor)
                .padding({ left: 12, right: 12, top: 6, bottom: 6 })
                .backgroundColor('#EAF2FD')
                .borderRadius(15)
                .onClick(() => {
                  this.showLogin = true;
                })
            }
            .width('100%')

            Row() {
              Text('最近同步')
                .fontSize(13)
                .fontColor('#8A8A8E')
              Blank()
              Text(this.syncLastTime === '' ? '从未同步' : this.syncLastTime)
                .fontSize(13)
                .fontColor('#4A4A4A')
            }
            .width('100%')

            Row() {
              Text('立即同步')
                .fontSize(13)
                .fontColor(this.themeColor)
              Blank()
              Button('同步')
                .fontSize(12)
                .fontColor(Color.White)
                .backgroundColor(this.themeColor)
                .height(30)
                .padding({ left: 16, right: 16 })
                .borderRadius(15)
                .enabled(this.loggedIn())
                .opacity(this.loggedIn() ? 1 : 0.4)
                .onClick(() => {
                  this.triggerSync();
                })
            }
            .width('100%')
          }
          .width('100%')
          .padding(16)
          .backgroundColor(Color.White)
          .borderRadius(16)

          // 外观设置
          Column({ space: 6 }) {
            Text('外观')
              .fontSize(15)
              .fontWeight(FontWeight.Medium)
              .fontColor('#1A1A1A')
              .width('100%')

            Row() {
              Text('深色模式')
                .fontSize(14)
                .fontColor('#1A1A1A')
              Blank()
              Toggle({ type: ToggleType.Switch, isOn: this.darkMode })
                .selectedColor(this.themeColor)
                .onChange((isOn: boolean) => {
                  this.darkMode = isOn;
                  DataStore.get().setDarkMode(isOn);
                })
            }
            .width('100%')
            .padding({ top: 8, bottom: 8 })

            Divider().color('#F0F0F3')

            Row() {
              Text('主题色')
                .fontSize(14)
                .fontColor('#1A1A1A')
              Blank()
              Row({ space: 6 }) {
                ForEach(ScheduleModels.PRESET_COLORS, (color: string) => {
                  Circle({ width: 22, height: 22 })
                    .fill(color)
                    .stroke(this.themeColor === color ? this.themeColor : Color.Transparent)
                    .strokeWidth(2)
                    .onClick(() => {
                      this.themeColor = color;
                      DataStore.get().setThemeColor(color);
                    })
                }, (color: string) => color)
              }
            }
            .width('100%')
            .padding({ top: 8, bottom: 8 })
          }
          .width('100%')
          .padding(16)
          .backgroundColor(Color.White)
          .borderRadius(16)

          // 同步设置
          Column({ space: 6 }) {
            Text('同步')
              .fontSize(15)
              .fontWeight(FontWeight.Medium)
              .fontColor('#1A1A1A')
              .width('100%')

            Row() {
              Text('自动同步')
                .fontSize(14)
                .fontColor('#1A1A1A')
              Blank()
              Toggle({ type: ToggleType.Switch, isOn: this.syncEnabled })
                .selectedColor(this.themeColor)
                .onChange((isOn: boolean) => {
                  this.syncEnabled = isOn;
                  DataStore.get().setSyncEnabled(isOn);
                  SyncScheduler.get().schedule(
                    this.getUIContext().getHostContext()?.getApplicationContext(),
                    isOn,
                    this.syncInterval
                  );
                })
            }
            .width('100%')
            .padding({ top: 8, bottom: 8 })

            Divider().color('#F0F0F3')

            Row() {
              Text('同步间隔')
                .fontSize(14)
                .fontColor('#1A1A1A')
              Blank()
              Text(this.intervalLabel(this.syncInterval))
                .fontSize(13)
                .fontColor(this.themeColor)
                .onClick(() => {
                  this.intervalSelected = this.syncInterval;
                  this.showIntervalPicker = true;
                })
            }
            .width('100%')
            .padding({ top: 8, bottom: 8 })

            Divider().color('#F0F0F3')

            Row() {
              Text('课表/成绩变更通知')
                .fontSize(14)
                .fontColor('#1A1A1A')
              Blank()
              Toggle({ type: ToggleType.Switch, isOn: this.notifyEnabled })
                .selectedColor(this.themeColor)
                .onChange((isOn: boolean) => {
                  this.notifyEnabled = isOn;
                  DataStore.get().setNotifyEnabled(isOn);
                })
            }
            .width('100%')
            .padding({ top: 8, bottom: 8 })

            Divider().color('#F0F0F3')

            Row() {
              Text('电费不足提醒')
                .fontSize(14)
                .fontColor('#1A1A1A')
              Blank()
              Toggle({ type: ToggleType.Switch, isOn: this.electricityReminder })
                .selectedColor(this.themeColor)
                .onChange((isOn: boolean) => {
                  this.electricityReminder = isOn;
                  DataStore.get().setElectricityReminderEnabled(isOn);
                })
            }
            .width('100%')
            .padding({ top: 8, bottom: 8 })

            Divider().color('#F0F0F3')

            Row() {
              Text('电费提醒阈值')
                .fontSize(14)
                .fontColor('#1A1A1A')
              Blank()
              Text(`${this.electricityThreshold} 元`)
                .fontSize(13)
                .fontColor(this.themeColor)
                .onClick(() => {
                  this.thresholdSelected = this.electricityThreshold;
                  this.showThresholdPicker = true;
                })
            }
            .width('100%')
            .padding({ top: 8, bottom: 8 })
          }
          .width('100%')
          .padding(16)
          .backgroundColor(Color.White)
          .borderRadius(16)

          // 关于
          Column({ space: 6 }) {
            Row() {
              Text('关于翱翔助手')
                .fontSize(14)
                .fontColor('#1A1A1A')
              Blank()
              Text('v2.0.0')
                .fontSize(13)
                .fontColor('#8A8A8E')
            }
            .width('100%')
            .padding({ top: 8, bottom: 8 })

            Divider().color('#F0F0F3')

            Text('数据仅存储于本机，凭据加密保存，仅用于登录您本人所在学校的教务系统')
              .fontSize(12)
              .fontColor('#8A8A8E')
              .width('100%')
              .lineHeight(18)
              .padding({ bottom: 4 })
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

      // 登录弹窗
      if (this.showLogin) {
        LoginDialog({
          onClose: () => {
            this.showLogin = false;
          },
          onSaved: () => {
            this.showLogin = false;
          }
        })
      }

      // 同步间隔选择
      if (this.showIntervalPicker) {
        this.PickerMask()
        this.IntervalPicker()
      }

      // 阈值选择
      if (this.showThresholdPicker) {
        this.PickerMask()
        this.ThresholdPicker()
      }
    }
    .width('100%')
    .height('100%')
  }

  private intervalLabel(minutes: number): string {
    if (minutes <= 0) {
      return '手动';
    }
    if (minutes < 60) {
      return `${minutes} 分钟`;
    }
    return `${minutes / 60} 小时`;
  }

  private triggerSync(): void {
    SyncScheduler.get().syncNow(
      this.getUIContext().getHostContext()?.getApplicationContext(),
      (message: string) => {
        try {
          this.getUIContext().getPromptAction().showToast({ message: message });
        } catch (e) {
          // ignore
        }
      }
    );
  }

  @Builder
  PickerMask() {
    Column()
      .width('100%')
      .height('100%')
      .backgroundColor('#66000000')
      .onClick(() => {
        this.showIntervalPicker = false;
        this.showThresholdPicker = false;
      })
  }

  @Builder
  IntervalPicker() {
    Column({ space: 10 }) {
      Text('同步间隔')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor('#1A1A1A')
      Column({ space: 0 }) {
        ForEach(this.intervalOptions(), (option: IntervalOption) => {
          Row() {
            Text(option.label)
              .fontSize(14)
              .fontColor('#1A1A1A')
            Blank()
            if (this.intervalSelected === option.minutes) {
              Text('✓')
                .fontSize(14)
                .fontColor(this.themeColor)
            }
          }
          .width('100%')
          .height(40)
          .padding({ left: 8, right: 8 })
          .onClick(() => {
            this.intervalSelected = option.minutes;
          })
        }, (option: IntervalOption) => `${option.minutes}`)
      }
      Row({ space: 12 }) {
        Button('取消')
          .fontSize(14)
          .fontColor('#8A8A8E')
          .backgroundColor('#F0F0F3')
          .layoutWeight(1)
          .height(38)
          .borderRadius(19)
          .onClick(() => {
            this.showIntervalPicker = false;
          })
        Button('保存')
          .fontSize(14)
          .fontColor(Color.White)
          .backgroundColor(this.themeColor)
          .layoutWeight(1)
          .height(38)
          .borderRadius(19)
          .onClick(() => {
            this.syncInterval = this.intervalSelected;
            DataStore.get().setSyncInterval(this.intervalSelected);
            SyncScheduler.get().schedule(
              this.getUIContext().getHostContext()?.getApplicationContext(),
              this.syncEnabled,
              this.intervalSelected
            );
            this.showIntervalPicker = false;
          })
      }
      .width('100%')
    }
    .width('82%')
    .padding(20)
    .backgroundColor(Color.White)
    .borderRadius(20)
    .alignSelf(ItemAlign.Center)
    .position({ y: '30%' })
  }

  private intervalOptions(): Array<IntervalOption> {
    return [
      new IntervalOption('手动', 0),
      new IntervalOption('1 小时', 60),
      new IntervalOption('6 小时', 360),
      new IntervalOption('12 小时', 720),
      new IntervalOption('24 小时', 1440)
    ];
  }

  @Builder
  ThresholdPicker() {
    Column({ space: 10 }) {
      Text('电费提醒阈值')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor('#1A1A1A')
      Column({ space: 0 }) {
        ForEach(this.thresholdOptions(), (value: number) => {
          Row() {
            Text(`${value} 元`)
              .fontSize(14)
              .fontColor('#1A1A1A')
            Blank()
            if (this.thresholdSelected === value) {
              Text('✓')
                .fontSize(14)
                .fontColor(this.themeColor)
            }
          }
          .width('100%')
          .height(40)
          .padding({ left: 8, right: 8 })
          .onClick(() => {
            this.thresholdSelected = value;
          })
        }, (value: number) => `${value}`)
      }
      Row({ space: 12 }) {
        Button('取消')
          .fontSize(14)
          .fontColor('#8A8A8E')
          .backgroundColor('#F0F0F3')
          .layoutWeight(1)
          .height(38)
          .borderRadius(19)
          .onClick(() => {
            this.showThresholdPicker = false;
          })
        Button('保存')
          .fontSize(14)
          .fontColor(Color.White)
          .backgroundColor(this.themeColor)
          .layoutWeight(1)
          .height(38)
          .borderRadius(19)
          .onClick(() => {
            this.electricityThreshold = this.thresholdSelected;
            DataStore.get().setElectricityThreshold(this.thresholdSelected);
            this.showThresholdPicker = false;
          })
      }
      .width('100%')
    }
    .width('82%')
    .padding(20)
    .backgroundColor(Color.White)
    .borderRadius(20)
    .alignSelf(ItemAlign.Center)
    .position({ y: '30%' })
  }

  private thresholdOptions(): Array<number> {
    return [5, 10, 20, 30, 50];
  }
}

export class IntervalOption {
  label: string;
  minutes: number;

  constructor(label: string, minutes: number) {
    this.label = label;
    this.minutes = minutes;
  }
}
