# Milo iOS 下一次修复 AI 指令

## 项目背景
Milo 是一个即时通讯(IM)应用，有 Android 和 iOS 两个版本。Android 版本功能完整，iOS 版本正在开发中。后端使用 WuKongIM 作为 IM 服务器，Flask 作为业务后端。

## 服务器架构
- Port 8090: WuKongIM REST API (外部访问，nginx 代理)
- Port 8091: WuKongIM REST API (内部，后端调用)
- Port 5100: WuKongIM TCP (移动端 SDK 连接)
- Port 5200: WuKongIM WebSocket (Web 端连接)
- Port 5001: Flask 后端 (短信、注册、登录代理)
- Port 5002: 推送服务
- MySQL: 172.19.0.5:3306 (Docker 内部，数据库 "im")

## 认证协议
- WuKongIM REST API 认证头: `token: <token_value>` (不是 `Authorization: Bearer`)
- 登录响应包含: uid, token, im_token, short_no, phone, zone, email
- `token` 用于 REST API 认证，`im_token` 用于 IM 连接认证
- 如果响应中没有 `im_token`，则回退使用 `token`

## 已修复的问题
1. ✅ API 认证头从 `Authorization: Bearer` 改为 `token` header (APIRouter.swift)
2. ✅ IM 连接从 WebSocket(5200) 改为 TCP(5100) (IMManager.swift)
3. ✅ AppDelegate 冷启动时自动连接 IM
4. ✅ 登录成功后保存 im_token 到 UserDefaults
5. ✅ WuKongIMSDK 集成 (pod 'WuKongIMSDK')
6. ✅ 登录/注册/重置密码页添加 logo 和副标题
7. ✅ 聊天页面标题从"闲雷虎虎"改为"Milo"
8. ✅ 导航栏和 TabBar 毛玻璃效果增强

## WuKongIMSDK 实际 API 注意事项 (与文档不同)
- `WKSDK.shared()` 是方法调用，不是属性 (需要加 `()`)
- `WKSDK` 没有 `setup` 方法，通过 `WKSDK.shared().options = options` 配置
- `WKOptions` 没有 `apiURL` 属性，只有 `host`(String) 和 `port`(UInt16)
- 委托注册用 `add(self)` 而不是 `addDelegate(self)`
- `WKChannel()` 用默认 init 创建，然后设置 `channelId` 和 `channelType` 属性
- `WKChannel.channelType` 是 `UInt8` 类型，`WKChannelType.person` 的 rawValue 是 1
- `WKMessage.channel` 是非可选的，不需要 `?`
- `WKConnectStatus` 枚举值: 0=NoConnect, 1=Connecting, 2=PullingOffline, 3=Connected, 4=Disconnected
- 用 `status.rawValue` 判断连接状态，不要用 `.connected` 等枚举 case

## 待测试验证
1. 用安卓已注册账号登录 → 联系人、群聊、单聊、聊天记录是否正常显示
2. 实时消息收发是否正常
3. 冷启动(杀进程后重开)是否自动连接 IM
4. UI 是否符合要求:
   - 登录/注册/重置密码页: logo + 副标题 + 白色背景输入框
   - 聊天/通讯录/我的页面: 蓝色主题毛玻璃效果

## 可能需要修复的问题
1. **会话同步未实现**: Android 端通过 `addOnSyncConversationListener` 和 `addOnSyncChannelMsgListener` 实现会话和消息同步，iOS 端目前只通过 REST API 获取数据，没有实现 SDK 层面的同步回调。如果联系人/会话仍不显示，可能需要实现这些回调。
2. **消息发送可能失败**: `WKChannel()` 默认 init 创建后设置属性的方式可能不正确，如果发送消息失败，需要检查 WKChannel 的创建方式。
3. **connectInfo 设置方式**: 当前使用 `WKSDK.shared().options.connectInfo = info` 直接设置，可能需要改用 `connectInfoCallback` 闭包。
4. **UI 细节调整**: 根据用户实际截图反馈，可能需要进一步调整:
   - 输入框白色背景的透明度和圆角
   - 毛玻璃效果的强度和颜色
   - 登录页副标题文案和位置
   - 各页面与安卓版本的一致性

## 关键文件路径
- IM 管理: `ios/Milo ios/Common/IMManager.swift`
- API 路由: `ios/Milo ios/Network/APIRouter.swift`
- 数据模型: `ios/Milo ios/Models/Models.swift`
- 登录页面: `ios/Milo ios/Modules/Login/LoginViewController.swift`
- 应用入口: `ios/Milo ios/App/AppDelegate.swift`
- 主 TabBar: `ios/Milo ios/App/MainTabBarController.swift`
- 聊天列表: `ios/Milo ios/Modules/Chat/ConversationListViewController.swift`
- 通讯录: `ios/Milo ios/Modules/Contacts/ContactsViewController.swift`
- 我的设置: `ios/Milo ios/Modules/Setting/MySettingViewController.swift`
- 导航控制器: `ios/Milo ios/Common/BaseNavigationController.swift`
- API 配置: `ios/Milo ios/APIConfig.swift`
- Podfile: `ios/Podfile`

## 构建方式
- GitHub Actions: 推送到 `github` remote 的 `master` 分支自动触发构建
- GitHub 仓库: `milo-dev-2026/Milo`
- Gitee 备份: `zhang-sanzhangsan2026/milo`
- 构建产物: GitHub Actions Artifact (Milo-unsigned.ipa)
- 安装方式: Sideloadly (路径: `%LOCALAPPDATA%\Sideloadly\sideloadly.exe`)
- Apple ID: 2644802996@qq.com (已保存在 Sideloadly 中)

## 下次会话指令模板
```
Milo iOS 项目继续修复。请先查看项目记忆文件了解已完成的工作。

当前状态: IPA 已构建成功并安装到手机上测试。

需要你做的:
1. [根据测试结果填写: 例如 "联系人仍然不显示" 或 "UI 需要调整"]
2. [根据测试结果填写: 例如 "消息发送失败" 或 "毛玻璃效果不对"]

关键约束:
- WuKongIM REST API 认证头用 `token` 而不是 `Authorization: Bearer`
- WuKongIM SDK 用 TCP 端口 5100 连接，不是 WebSocket 5200
- WKSDK.shared() 是方法调用需要加 ()
- 委托注册用 add(self) 不是 addDelegate(self)
- 编译前需要用户确认
- App 名称必须是 "Milo"，Bundle ID 必须是 com.milo.im
```
