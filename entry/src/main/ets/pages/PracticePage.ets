import font from '@ohos.font'
import promptAction from '@ohos.promptAction'
import { PracticesStatus } from './enums/PracticesStatus'
import { AnswerStatus } from './enums/AnswerStatus'
import { getRandomQuestions, Question } from './model/Question'
import { OptionStatus } from './enums/OptionStatus'
import router from '@ohos.router'
import { createPost } from './http/Api'
import emitter from '@ohos.events.emitter'

@Component
export struct PracticePage {
  @State practicesStatus: PracticesStatus = PracticesStatus.Stopped
  @State totalCount: number = 10
  @State questions: Question[] = getRandomQuestions(this.totalCount)
  @State currentIndex: number = 0
  @State answerStatus: AnswerStatus = AnswerStatus.Answering
  @State selectedOption: string = ''
  // 回答个数
  @State answeredCount: number = 0
  // 正确个数
  @State rightCount: number = 0
  timeController: TextTimerController = new TextTimerController()
  timeUsed: number = 0
  dialogController: CustomDialogController = new CustomDialogController({ builder: ResultDialog(
    {
      answeredCount: this.answeredCount,
      rightCount: this.rightCount,
      timeUsed: this.timeUsed,
      resetPractice: () => {
        this.questions = getRandomQuestions(this.totalCount)
        this.currentIndex = 0
        this.answeredCount = 0
        this.rightCount = 0
        this.timeUsed = 0
        this.timeController.reset()
        this.answerStatus = AnswerStatus.Answering
      },
      startPractice: () => {
        this.startPractice()
      }
    }), customStyle: true, autoCancel: false })

  startPractice() {
    this.practicesStatus = PracticesStatus.Running
    // 启动计时器
    this.timeController.start()
  }

  test() {
  }

  pausePractice() {
    // dddd
    this.practicesStatus = PracticesStatus.Paused
    this.timeController.pause()
  }

  stopPractice() {
    this.practicesStatus = PracticesStatus.Stopped
    this.currentIndex = 0
    // 停止计时器
    this.timeController.pause()
    // 弹窗
    this.dialogController.open()
  }

  build() {
    Column() {
      Column({ space: 10 }) {
        // 准确率
        StatItem({ icon: $r('app.media.ic_accuracy'),
          name: '准确率',
          fontColor: Color.Black
        }) {
          Text((this.answeredCount === 0 ? 0 : this.rightCount / this.answeredCount * 100).toFixed() + '%')
            .width(100)
            .textAlign(TextAlign.Center)
        }
        // 进度
        StatItem({ icon: $r('app.media.ic_progress'),
          name: '进度',
          fontColor: Color.Black
        }) {
          Progress({ value: this.answeredCount, total: this.totalCount })
            .width(100)
        }
        // 个数
        StatItem({ icon: $r('app.media.ic_count'),
          name: '个数',
          fontColor: Color.Black
        }) {
          Button(this.totalCount.toString())
            .width(100)
            .height(25)
            .backgroundColor('#EBEBEB')
            .fontColor(Color.Black)
            .enabled(this.practicesStatus === PracticesStatus.Stopped)
            .onClick(() => {
              TextPickerDialog.show({
                defaultPickerItemHeight: 35,
                range: ['5', '10', '15', '20'],
                value: this.totalCount.toString(),
                onAccept: (result) => {
                  this.totalCount = parseInt(result.value)
                  this.questions = getRandomQuestions(this.totalCount)
                }
              })
            })
        }
        // 用时
        StatItem({ icon: $r('app.media.ic_timer'),
          name: '用时',
          fontColor: Color.Black
        }) {
          Row() {
            TextTimer({ controller: this.timeController })
              .onTimer((utc: number, elapsedTime: number) => {
                this.timeUsed = elapsedTime
              })
          }.width(100)
          .justifyContent(FlexAlign.Center)

        }
      }.staBgStyle()

      Column({ space: 10 }) {
        Text(this.questions[this.currentIndex].word).wordStyle()
        Text(this.questions[this.currentIndex].sentence).sentenceStyle()
      }

      Column({ space: 10 }) {
        ForEach(this.questions[this.currentIndex].options, option => {
          OptionButton({
            option: option,
            answerStatus: this.answerStatus,
            answer: this.questions[this.currentIndex].answer,
            selectedOption: this.selectedOption
          })
            .enabled(this.answerStatus == AnswerStatus.Answering)
            .onClick(() => {
              if (this.practicesStatus != PracticesStatus.Running) {
                promptAction.showToast({ message: '请先点开始测试' })
                return
              }

              // 判断正误
              this.selectedOption = option

              // 更新统计信息
              this.answeredCount++
              if (option == this.questions[this.currentIndex].answer) {
                this.rightCount++
              }

              // 当前的索引大于答题数组长度就停止答题，否则延时换下一题
              if (this.currentIndex < this.questions.length - 1) {
                this.answerStatus = AnswerStatus.Answered
                setTimeout(() => {
                  this.currentIndex++
                  this.answerStatus = AnswerStatus.Answering
                }, 500)
              } else {
                this.stopPractice()
              }
            })
        }, option => this.questions[this.currentIndex].word + '-' + option
        )
      }

      Row({ space: 10 }) {
        Button('停止测试')
          .controlButtonStyle({
            bg: Color.Transparent,
            border: this.practicesStatus === PracticesStatus.Stopped ? Color.Grey : Color.Black,
            font: this.practicesStatus === PracticesStatus.Stopped ? Color.Grey : Color.Black
          })
          .enabled(this.practicesStatus != PracticesStatus.Stopped)
          .onClick(() => {
            if (this.practicesStatus != PracticesStatus.Stopped) {
              this.stopPractice()
            }
          })
        Button(this.practicesStatus == PracticesStatus.Running ? '暂停测试' : '开始测试')
          .controlButtonStyle({
            bg: this.practicesStatus == PracticesStatus.Running ? '#555555' : Color.Black,
            border: this.practicesStatus == PracticesStatus.Running ? '#555555' : Color.Black,
            font: Color.White
          }).stateEffect(false)
          .onClick(() => {
            if (this.practicesStatus === PracticesStatus.Running) {
              this.pausePractice()
            } else {
              this.startPractice()
            }
          })
      }
    }.bgStyle()
  }
}

@CustomDialog
struct ResultDialog {
  controller: CustomDialogController = new CustomDialogController({ builder: ResultDialog() })
  timeUsed: number
  rightCount: number
  answeredCount: number
  resetPractice: () => void
  startPractice: () => void
  @StorageProp('token') token: string = ''
  @StorageLink('currentTabIndex') currentTabIndex: number = 0

  build() {
    Column({ space: 10 }) {
      Image($r('app.media.ic_close'))
        .width(25)
        .height(25)
        .alignSelf(ItemAlign.End)
        .onClick(() => {
          this.resetPractice()
          this.controller.close()
        })
      Column({ space: 10 }) {
        Image($r('app.media.img_post'))
          .width('100%')
          .borderRadius(10)
        StatItem({
          icon: $r('app.media.ic_timer'),
          name: '用时'
        }) {
          Text(`${this.timeUsed}秒`)
        }

        StatItem({
          icon: $r('app.media.ic_accuracy'),
          name: '准确率'
        }) {
          Text((this.answeredCount === 0 ? 0 : this.rightCount / this.answeredCount * 100).toFixed() + '%')
        }

        StatItem({
          icon: $r('app.media.ic_count'),
          name: '个数'
        }) {
          Text(this.answeredCount.toString())
        }

        Divider()
        Row({ space: 30 }) {
          Button('再来一局')
            .controlButtonStyle({
              bg: Color.Transparent,
              border: Color.Black,
              font: Color.Black
            })
            .onClick(() => {
              this.controller.close()
              this.resetPractice()
              this.startPractice()
            })
          Button(this.token ? '立即打卡' : '登录打卡')
            .controlButtonStyle({
              bg: Color.Black,
              border: Color.Black,
              font: Color.White
            })
            .onClick(async () => {
              this.controller.close()
              this.resetPractice()
              if (this.token) {
                // 发送打卡请求
                await  createPost({
                  rightCount: this.rightCount,
                  answeredCount: this.answeredCount,
                  timeUsed: this.timeUsed
                })
                // 跳转到打卡圈
                promptAction.showToast({ message: '打卡成功' })
                // 通知
                emitter.emit({eventId:1})
                this.currentTabIndex = 1
              } else {
                // 跳转到登录页面
                router.push({ url: 'pages/LoginPage', params: {
                  rightCount: this.rightCount,
                  answeredCount: this.answeredCount,
                  timeUsed: this.timeUsed
                } })
                // 发送打卡请求
                // 跳转到打卡圈
              }
            })
        }
      }
      .backgroundColor(Color.White)
      .width('100%')
      .padding(20)
      .borderRadius(10)
    }
    .backgroundColor(Color.Transparent)
    .width('80%')
  }
}

@Component
export struct StatItem {
  icon: Resource
  name: string
  @BuilderParam statComp: () => void
  fontColor: Color

  build() {
    Row({ space: 10 }) {
      Image(this.icon)
        .width(14)
        .height(14)
      Text(this.name)
        .fontColor(this.fontColor)
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
      Blank()
      this.statComp()
    }.width('100%')
    .height(30)
  }
}

@Component
struct OptionButton {
  option: string
  answer: string
  @State optionStatus: OptionStatus = OptionStatus.Default
  @Prop selectedOption: string
  @Prop @Watch('onAnswerStatusChange') answerStatus: AnswerStatus

  onAnswerStatusChange() {
    if (this.option === this.answer) {
      this.optionStatus = OptionStatus.Right
    } else {
      if (this.option == this.selectedOption) {
        this.optionStatus = OptionStatus.Wrong
      } else {
        this.optionStatus = OptionStatus.Default
      }
    }
  }

  getBgColor() {
    switch (this.optionStatus) {
      case OptionStatus.Right:
        return '#1DBF7B'
      case OptionStatus.Wrong:
        return '#fa635f'
      default:
        return Color.White
    }
  }

  build() {
    Stack() {
      Button(this.option)
        .optionButtonStyle({
          bg: this.getBgColor(),
          font: this.optionStatus === OptionStatus.Default ? Color.Black : Color.White
        })
      if (this.optionStatus === OptionStatus.Right) {
        Image($r('app.media.ic_right'))
          .width(22)
          .width(22)
          .offset({ x: 10 })
      } else if (this.optionStatus === OptionStatus.Wrong) {
        Image($r('app.media.ic_wrong'))
          .width(22)
          .width(22)
          .offset({ x: 10 })
      }
    }
    .alignContent(Alignment.Start)
  }
}

@Extend(Column) function bgStyle() {
  .backgroundImage($r('app.media.img_practice_bg'))
  .width('100%')
  .height('100%')
  .justifyContent(FlexAlign.SpaceEvenly)
}

@Extend(Column) function staBgStyle() {
  .width('90%')
  .backgroundColor(Color.White)
  .padding(10)
  .borderRadius(10)
}

@Extend(Text) function wordStyle() {
  .fontSize(50)
  .fontWeight(FontWeight.Bold)
}

@Extend(Text) function sentenceStyle() {
  .fontSize(16)
  .height(40)
  .fontColor('#9BA1A5')
  .width('80%')
  .fontWeight(FontWeight.Medium)
  .textAlign(TextAlign.Center)
}

@Extend(Button) function optionButtonStyle(color: {
  bg: ResourceColor,
  font: ResourceColor
}) {
  .width(240)
  .height(60)
  .fontSize(16)
  .type(ButtonType.Normal)
  .borderRadius(8)
  .fontWeight(FontWeight.Medium)
  .fontColor(color.font)
  .backgroundColor(color.bg)
}

@Extend(Button) function controlButtonStyle(color: {
  bg: ResourceColor,
  border: ResourceColor,
  font: ResourceColor
}) {
  .fontSize(16)
  .borderWidth(1)
  .backgroundColor(color.bg)
  .fontColor(color.font)
  .borderColor(color.border)
}
