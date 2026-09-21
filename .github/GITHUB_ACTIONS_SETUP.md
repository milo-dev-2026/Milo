# GitHub Actions iOS 签名构建指南

## 概述

本项目使用 GitHub Actions 自动构建**签名 IPA** 文件，可直接安装到已注册 UDID 的 iOS 设备。

### 签名构建 vs 未签名构建

| 模式 | 需要 Apple Developer | 签名状态 | 适用场景 |
|------|---------------------|---------|---------|
| **signed**（默认） | 需要 $99/年账户 | Ad-Hoc 签名 | 直接安装到设备、TestFlight 分发 |
| unsigned | 免费 | 未签名 | 通过 Sideloadly/AltStore 安装 |

> 本指南聚焦 **signed** 模式。如需 unsigned，在手动触发时选择 `unsigned` 即可。

## 费用说明

### 公开仓库（Public）— 完全免费
- GitHub Actions 对公开仓库提供无限分钟的免费运行时间
- macOS runner (`macos-latest`) 同样免费
- 无存储限制

### 私有仓库（Private）— 每月免费额度
- 免费账户：每月 2,000 分钟（macOS 按 10x 计算，约 200 分钟构建时间）
- Pro 账户 ($4/月)：每月 3,000 分钟

## 前置条件

### 1. Apple Developer 账户 ($99/年)
- 注册地址: https://developer.apple.com/programs/
- 需要完成实名认证

### 2. 以下文件准备好
- **.p12 证书文件** (iOS Distribution)
- **.mobileprovision 描述文件** (Ad Hoc)

## 第一步：创建证书和描述文件

### 1.1 创建证书

1. 登录 [Apple Developer](https://developer.apple.com/account)
2. **Certificates, Identifiers & Profiles → Certificates → +**
3. 选择 **iOS Distribution (Ad Hoc)** → Continue
4. 上传 Certificate Signing Request (CSR)
   - 在 Mac 上打开「钥匙串访问」→ 证书助理 → 从证书颁发机构请求证书
   - 填写邮箱，保存到磁盘
5. 下载 `.cer` 文件
6. 双击安装到钥匙串
7. 在钥匙串中找到该证书 → 右键导出 → 选择 **.p12** 格式 → 设置密码

### 1.2 注册 Bundle ID

1. **Identifiers → +**
2. App IDs → App
3. Bundle ID: `com.xian.leihuhu`
4. 勾选需要的 Capabilities（Push Notifications、Background Modes 等）

### 1.3 创建 Provisioning Profile

1. **Profiles → +**
2. 选择 **Ad Hoc** → Continue
3. 选择 App ID: `com.xian.leihuhu`
4. 选择上一步创建的证书
5. 选择要安装的设备 UDID（在 **Devices** 中先注册）
6. 命名为 `XianLeiHuHu-AdHoc`
7. 下载 `.mobileprovision` 文件

### 1.4 获取 Team ID

- **Membership** 页面 → 查看 Team ID（格式如 `ABCD1234EF`）

## 第二步：生成 base64 编码

### 方式一：使用辅助脚本（推荐）

将 `ios/ci/prepare_signing_secrets.sh` 复制到 Mac 上运行：

```bash
chmod +x prepare_signing_secrets.sh
./prepare_signing_secrets.sh /path/to/cert.p12 /path/to/profile.mobileprovision
```

脚本会自动：
- 生成 base64 编码
- 提取 Team ID
- 生成随机 keychain 密码
- 输出所有需要配置的 Secret 值

### 方式二：手动生成

在 macOS 终端执行：

```bash
# 证书 base64
base64 -i certificate.p12 | pbcopy

# Provisioning Profile base64
base64 -i XianLeiHuHu.mobileprovision | pbcopy

# 查看 Team ID
security cms -D -i XianLeiHuHu.mobileprovision | grep -A1 "TeamIdentifier"
```

## 第三步：配置 GitHub Secrets

1. 打开你的 GitHub 仓库
2. **Settings → Secrets and variables → Actions**
3. 点击 **New repository secret**

添加以下 5 个 Secrets：

| Secret 名称 | 值 | 说明 |
|---|---|---|
| `IOS_P12_CERTIFICATE` | base64 字符串 | .p12 证书的 base64 |
| `IOS_P12_PASSWORD` | 你的密码 | 导出 .p12 时设置的密码 |
| `IOS_PROVISIONING_PROFILE` | base64 字符串 | .mobileprovision 的 base64 |
| `IOS_KEYCHAIN_PASSWORD` | 任意字符串 | 如 `g1thub-4ct10ns-2024` |
| `IOS_TEAM_ID` | 如 `ABCD1234EF` | Apple Developer Team ID |

> **安全提示**: Secrets 配置后不可查看，只能更新。确保值正确无误。

## 第四步：触发构建

### 自动触发

```bash
# 推送代码（修改 ios/ 目录后自动触发 signed 构建）
git add .
git commit -m "Update iOS app"
git push

# 推送 tag 触发 Release 构建
git tag v1.0.0
git push origin v1.0.0
```

### 手动触发

1. GitHub 仓库 → **Actions**
2. 选择 **iOS Build IPA**
3. 点击 **Run workflow**
4. Build type 选择 **signed**（默认）
5. 勾选 **Create GitHub Release**（可选）
6. 点击绿色 **Run workflow** 按钮

## 构建产物

### 下载方式

**方式一：Actions Artifact**
1. 进入 Actions → 对应运行
2. 页面底部 **Artifacts** 区域
3. 下载 `XianLeiHuHu-signed.ipa`

**方式二：GitHub Release**（如果勾选了 Create Release）
1. 仓库首页 → **Releases**（右侧栏）
2. 下载 `.ipa` 文件

### 安装到设备

#### 方式一：Sideloadly（推荐）

1. 下载 [Sideloadly](https://sideloadly.io/)
2. 连接 iPhone 到电脑
3. 打开 Sideloadly → 拖入 IPA 文件
4. 填入 Apple ID（不需要 Developer 账户）
5. 点击 **Start** 安装
6. iPhone: 设置 → 通用 → VPN与设备管理 → 信任证书

#### 方式二：3uTools

1. 下载 [3uTools](https://www.3u.com/)
2. 连接 iPhone → 应用&游戏 → 安装
3. 拖入 IPA 文件

#### 方式三：Apple Configurator

1. Mac App Store 安装 Apple Configurator
2. 连接 iPhone → 选择设备
3. 将 IPA 拖入窗口

> **前提**: 设备 UDID 必须已注册在 Provisioning Profile 中。

## 触发方式

| 触发方式 | 条件 | 默认类型 | 创建 Release |
|---------|------|---------|-------------|
| Push 到 main/master | `ios/**` 有改动 | signed | 否 |
| 推送 tag `v*` | 如 `v1.0.0` | signed | 是 |
| Pull Request | 修改了 `ios/**` | signed | 否 |
| 手动触发 | workflow_dispatch | signed（可选） | 可选 |

## 工作流流程

```
┌───────────┐   ┌───────────┐   ┌────────────┐   ┌──────────────────┐
│ Checkout   │──▶│ XcodeGen   │──▶│ Pod Install│──▶│ 导入证书+描述文件  │
│ 代码检出    │   │ 生成工程    │   │ 安装依赖     │   │ (signed only)    │
└───────────┘   └───────────┘   └────────────┘   └────────┬─────────┘
                                                          │
                                                          ▼
                                    ┌────────────────────────────────┐
                                    │  xcodebuild archive            │
                                    │  构建归档 (.xcarchive)          │
                                    │  signed: 手动签名              │
                                    │  unsigned: CODE_SIGNING=NO     │
                                    └───────────────┬────────────────┘
                                                   │
                                                   ▼
                                    ┌────────────────────────────────┐
                                    │  xcodebuild -exportArchive    │
                                    │  signed: 通过 ExportOptions    │
                                    │  unsigned: 手动打包 Payload    │
                                    └───────────────┬────────────────┘
                                                   │
                                                   ▼
                                    ┌────────────────────────────────┐
                                    │  upload-artifact               │
                                    │  上传 IPA 为 Actions Artifact   │
                                    └───────────────┬────────────────┘
                                                   │
                                                   ▼
                                    ┌────────────────────────────────┐
                                    │  (tag push 或手动选择)         │
                                    │  创建 GitHub Release            │
                                    │  上传 IPA 到 Release            │
                                    └────────────────────────────────┘
```

## 目录结构

```
Milo/
├── .github/
│   ├── workflows/
│   │   └── ios-build.yml              # GitHub Actions 工作流
│   └── GITHUB_ACTIONS_SETUP.md        # 本文档
└── ios/
    ├── ci/
    │   ├── prepare_signing_secrets.sh  # Secrets 生成脚本
    │   ├── ExportOptions-unsigned.plist # 未签名导出模板
    │   └── ExportOptions-signed.plist   # 签名导出模板
    ├── project.yml                     # XcodeGen 配置
    ├── Podfile                         # CocoaPods 依赖
    └── Milo ios/                       # 源码目录
```

## 常见问题

### Q: 构建失败，提示 "IOS_P12_CERTIFICATE secret is not set"

A: 你选择了 signed 模式但未配置 GitHub Secrets。按本指南第二步和第三步操作。

### Q: "No signing certificate" 或 "iPhone Distribution: xxx not found"

A: 证书类型可能不对。确保创建的是 **iOS Distribution (Ad Hoc)** 证书，不是 Development 证书。检查 .p12 是否正确导入钥匙串。

### Q: "Provisioning profile doesn't include device UDID"

A: 在 [Apple Developer → Devices](https://developer.apple.com/account/resources/devices) 中注册设备 UDID，然后重新下载 Provisioning Profile。

### Q: 构建成功但 IPA 无法安装

A: 检查以下几点：
1. 设备 UDID 是否在 Provisioning Profile 中
2. iOS 版本是否 >= 14.0
3. 设置 → 通用 → VPN与设备管理 → 信任开发者证书

### Q: Pod install 失败

A: 首次运行较慢，后续有缓存加速。如持续失败，检查 Podfile 中的依赖版本兼容性。

### Q: 如何上传到 TestFlight

A: 在 workflow 中添加额外步骤，使用 `alloy/organism` action 或 `fastlane pilot`：
```yaml
- name: Upload to TestFlight
  run: |
    xcrun altool --upload-app \
      -f "$IPA_PATH" \
      --type ios \
      --apiKey ${{ secrets.APP_STORE_KEY_ID }} \
      --apiIssuer ${{ secrets.APP_STORE_ISSUER_ID }}
```

### Q: 如何添加设备 UDID

A:
1. iPhone 连接 Mac → 打开 Finder/iTunes → 查看 UDID
2. Apple Developer → Devices → 添加设备
3. 重新创建 Provisioning Profile（勾选新设备）
4. 下载新 .mobileprovision → 重新生成 base64 → 更新 GitHub Secret

## 本地验证

推送到 GitHub 前，在 Mac 上本地验证：

```bash
cd ios

# 生成工程
xcodegen generate

# 安装依赖
pod install

# 模拟器构建验证（不需要签名）
xcodebuild build \
  -workspace XianLeiHuHu.xcworkspace \
  -scheme XianLeiHuHu \
  -configuration Debug \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 15'

# 签名归档验证（需要本地证书）
xcodebuild archive \
  -workspace XianLeiHuHu.xcworkspace \
  -scheme XianLeiHuHu \
  -configuration Release \
  -archivePath build/XianLeiHuHu.xcarchive \
  -sdk iphoneos \
  DEVELOPMENT_TEAM="你的TeamID" \
  CODE_SIGN_STYLE="Manual" \
  CODE_SIGN_IDENTITY="iPhone Distribution"
```
