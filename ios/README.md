# 闲雷虎虎 iOS 工程

## 项目结构

```
ios/
├── project.yml              # XcodeGen项目配置（用XcodeGen生成.xcodeproj）
├── Podfile                  # CocoaPods依赖管理
├── APIConfig.swift          # 所有API密钥和配置（含占位符）
├── XianLeiHuHu/             # 源码目录
│   ├── App/
│   │   ├── AppDelegate.swift        # 应用入口 + APNs推送注册
│   │   ├── MainTabBarController.swift # 底部TabBar
│   │   ├── LaunchScreenViewController.swift
│   │   └── Info.plist               # 权限描述 + 高德Key
│   ├── Common/
│   │   ├── IMManager.swift          # WuKongIM WebSocket连接管理
│   │   ├── AppUtility.swift         # 通用工具（Toast/头像/颜色/UIView扩展）
│   │   ├── LocalStore.swift         # 本地数据存储
│   │   └── Config.swift            # 环境配置
│   ├── Network/
│   │   └── APIRouter.swift          # 网络请求层（Alamofire封装）
│   ├── Models/
│   │   └── Models.swift             # 数据模型（User/Message/Conversation等）
│   ├── Modules/
│   │   ├── Login/
│   │   │   └── LoginViewController.swift   # 登录+注册页
│   │   ├── Chat/
│   │   │   ├── ConversationListViewController.swift # 会话列表
│   │   │   ├── ChatViewController.swift            # 聊天页
│   │   │   └── ChatInputBar.swift                  # 输入栏
│   │   ├── Contacts/
│   │   │   └── ContactsViewController.swift        # 通讯录
│   │   ├── Setting/
│   │   │   └── MySettingViewController.swift       # 我的+设置子页
│   │   ├── Location/
│   │   │   └── LocationPickerViewController.swift  # 地图选点（高德SDK）
│   │   ├── TRTC/
│   │   │   └── TRTCCallViewController.swift         # 音视频通话（腾讯TRTC）
│   │   └── Scan/
│   │       └── ScanViewController.swift            # 二维码扫描
│   └── Resources/
└── API_KEYS_GUIDE.md       # 密钥更换指南
```

## 在Mac上打开和编译

### 前置条件
1. Mac电脑
2. Xcode 15+（从App Store下载，免费）
3. CocoaPods（`sudo gem install cocoapods`）
4. XcodeGen（`brew install xcodegen`）

### 步骤

```bash
# 1. 把整个ios目录复制到Mac上

# 2. 生成Xcode工程（必须先执行此步）
cd ios
xcodegen generate

# 3. 安装依赖
pod install

# 4. 打开工程（必须用.xcworkspace，不能用.xcodeproj）
open XianLeiHuHu.xcworkspace

# 5. 在Xcode中：
#    - 选择你的Apple ID（Settings > Accounts）
#    - 选择开发团队（Signing & Capabilities）
#    - 连接iPhone，选择设备
#    - 点击运行按钮(⌘R)
```

### 免费Apple ID真机调试
- 用免费Apple ID登录Xcode即可真机调试
- 免费账号限制：应用7天有效期，最多3个设备
- 不需要付费$99/年Developer账号

### 需要替换的配置
1. **APNs推送证书**（步骤3）- 在Apple Developer后台创建
2. 其他所有密钥已在APIConfig.swift中配置完成

## 功能模块

| 模块 | 文件 | 说明 |
|------|------|------|
| 登录注册 | LoginViewController.swift | 手机号+验证码登录/注册 |
| 会话列表 | ConversationListViewController.swift | 聊天列表+未读徽章 |
| 聊天页 | ChatViewController.swift | 文字消息+WebSocket实时收发 |
| 输入栏 | ChatInputBar.swift | 自适应高度输入框 |
| 通讯录 | ContactsViewController.swift | 好友列表+搜索 |
| 我的 | MySettingViewController.swift | 个人资料+设置+退出登录 |
| 地图 | LocationPickerViewController.swift | 高德地图选点+POI搜索 |
| 通话 | TRTCCallViewController.swift | 音视频通话 |
| 扫描 | ScanViewController.swift | 二维码扫描 |
| IM连接 | IMManager.swift | WebSocket连接+自动重连 |
| 网络层 | APIRouter.swift | Alamofire REST API封装 |
| 推送 | AppDelegate.swift | APNs注册+Token上传 |
