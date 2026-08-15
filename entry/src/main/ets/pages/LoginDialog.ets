/**
 * 登录对话框 —— 对应 Android 参考实现 LoginDialog
 * 用户凭据仅用于登录用户本人所在学校的教务/一卡通系统，
 * 密码以密文形式存储于本地（AES 加密）。
 * 以 Stack 覆盖层形式呈现（ArkUI 原生组件，不使用自定义 Dialog）。
 */
import { DataStore } from '../common/DataStore';
import { CredentialCrypto } from '../common/CredentialCrypto';

@Component
export struct LoginDialog {
  @StorageLink('themeColor') themeColor: string = '#2F80ED';
  @State username: string = '';
  @State password: string = '';
  @State saving: boolean = false;
  @State errorText: string = '';
  onClose: () => void = () => {
  };
  onSaved: () => void = () => {
  };

  aboutToAppear(): void {
    this.username = DataStore.get().getUsername();
  }

  build() {
    Stack() {
      // 半透明遮罩
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('#66000000')
        .onClick(() => {
          if (!this.saving) {
            this.onClose();
          }
        })

      Column({ space: 14 }) {
        Text('登录教务账号')
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1A1A1A')

        Text('凭据仅保存于本机（密码加密存储），仅用于同步您本人的课表与成绩')
          .fontSize(11)
          .fontColor('#8A8A8E')
          .lineHeight(16)

        TextInput({ placeholder: '学号 / 用户名', text: this.username })
          .height(42)
          .fontSize(14)
          .onChange((value: string) => {
            this.username = value;
          })

        TextInput({ placeholder: '密码（教务系统密码）', text: this.password })
          .height(42)
          .fontSize(14)
          .type(InputType.Password)
          .onChange((value: string) => {
            this.password = value;
          })

        if (this.errorText !== '') {
          Text(this.errorText)
            .fontSize(12)
            .fontColor('#E53935')
            .width('100%')
        }

        Row({ space: 12 }) {
          Button('取消')
            .fontSize(14)
            .fontColor('#8A8A8E')
            .backgroundColor('#F0F0F3')
            .layoutWeight(1)
            .height(40)
            .borderRadius(20)
            .enabled(!this.saving)
            .onClick(() => {
              this.onClose();
            })
          Button(this.saving ? '保存中...' : '保存')
            .fontSize(14)
            .fontColor(Color.White)
            .backgroundColor(this.themeColor)
            .layoutWeight(1)
            .height(40)
            .borderRadius(20)
            .enabled(!this.saving)
            .onClick(() => {
              this.saveCredentials();
            })
        }
        .width('100%')
      }
      .width('86%')
      .padding(20)
      .backgroundColor(Color.White)
      .borderRadius(20)
      .alignSelf(ItemAlign.Center)
      .position({ y: '28%' })
    }
    .width('100%')
    .height('100%')
  }

  private saveCredentials(): void {
    const name = this.username.trim();
    if (name === '') {
      this.errorText = '请输入学号/用户名';
      return;
    }
    if (this.password === '') {
      this.errorText = '请输入密码';
      return;
    }
    this.saving = true;
    this.errorText = '';
    CredentialCrypto.encrypt(this.password).then((encrypted: string) => {
      DataStore.get().setUsername(name);
      DataStore.get().setPasswordEncrypted(encrypted);
      DataStore.get().setAutofillEnabled(true);
      this.saving = false;
      this.onSaved();
    }).catch(() => {
      this.saving = false;
      this.errorText = '加密失败，请重试';
    });
  }
}
