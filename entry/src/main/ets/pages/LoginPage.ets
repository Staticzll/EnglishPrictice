import router from '@ohos.router'
import emitter from '@ohos.events.emitter'
import { createPost, login, sendCode } from './http/Api'

@Entry
@Component
struct LoginPage {
  @State phone: string = ''
  @State code: string = ''
  @StorageLink('token') token: string = ''
  @StorageLink('currentTabIndex') currentTabIndex: number = 0

  build() {
    Column() {
      Image($r('app.media.ic_back'))
        .backStyle()
        .alignSelf(ItemAlign.Start)
        .onClick(() => {
          router.back()
        })
      Blank()
      Column() {
        Text('欢迎登录')
          .titleStyle()
        Row() {
          Image($r("app.media.ic_phone"))
            .iconStyle()
          TextInput({ placeholder: '请输⼊⼿机号码', text: this.phone })
            .inputStyle()
            .onChange((value) => {
              this.phone = value;
            })
        }.margin({ top: 30 })

        Divider()
          .color(Color.Black)
        Row() {
          Image($r("app.media.ic_code"))
            .iconStyle()
          TextInput({ placeholder: '请输⼊验证码', text: this.code })
            .inputStyle()
            .onChange((value) => {
              this.code = value;
            })
          Button('获取验证码')
            .buttonStyle(Color.White, Color.Black)
            .onClick(async () => {
              //获取验证码
              let response = await sendCode(this.phone)
              this.code = response.data.data
            })
        }.margin({ top: 20 })

        Divider()
          .margin({ right: 120 })
          .color(Color.Black)
        Button('⽴即登录')
          .buttonStyle(Color.Black, Color.White)
          .width('100%')
          .margin({ top: 50 })
          .onClick(async () => {
            //登录
            let response = await login(this.phone, this.code)
            let token = response.data.data
            this.token = token
            if (this.currentTabIndex === 0) {
              // 发送打卡请求
              let param = router.getParams()
              await  createPost({
                rightCount: param['rightCount'],
                answeredCount: param['answeredCount'],
                timeUsed: param['timeUsed']
              })
              // 通知
              emitter.emit({eventId:1})
              // 跳转到打卡圈
              this.currentTabIndex = 1
            }
            router.back()

          })
        Row() {
          Text('登录即表示已同意')
            .fontSize(10)
            .fontColor('#546B9D')
          Text('《⽤户使⽤协议》')
            .fontSize(10)
            .fontColor('#00B3FF')
        }.margin({ top: 20 })
      }.formBgStyle()

      Row({ space: 10 }) {
        Image($r('app.media.ic_logo'))
          .width(36)
          .height(36)
        Text('快速记单词神器')
          .fontColor('#546B9D')
          .fontWeight(FontWeight.Bold)
          .fontSize(20)
      }.margin({ top: 70 })

      Text('Developed By Atguigu')
        .fontSize(12)
        .fontColor('#546B9D')
        .margin(10)
    }
    .loginBgStyle()
  }
}

36

@Styles function loginBgStyle() {
  .width('100%')
  .height('100%')
  .backgroundImage($r("app.media.img_login_bg"))
  .backgroundImageSize({ width: '100%', height: '100%' })
  .padding({
    top: 30, bottom: 30, left: 20, right: 20
  })
}

@Styles function backStyle() {
  .width(25)
  .height(25)
}

@Styles function formBgStyle() {
  .backgroundColor(Color.White)
  .padding(30)
  .borderRadius(20)
}

@Extend(Text) function titleStyle() {
  .fontWeight(FontWeight.Bold)
  .fontSize(22)
}

@Styles function iconStyle() {
  .width(24)
  .height(24)
}

@Extend(TextInput) function inputStyle() {
  .height(40)
  .layoutWeight(1)
  .fontSize(14)
  .backgroundColor(Color.Transparent)
}

@Extend(Button) function buttonStyle(bgColor: ResourceColor, fontColor: ResourceColor) {
  .type(ButtonType.Normal)
  .fontSize(14)
  .fontWeight(FontWeight.Medium)
  .borderWidth(1)
  .borderRadius(5)
  .backgroundColor(bgColor)
  .fontColor(fontColor)
}
