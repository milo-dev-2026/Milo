# 无 Mac 电脑编译安装 iOS IPA 完整指南

> **核心原理**: GitHub Actions 提供云端 macOS 环境（完全免费），你在 Windows 上推送代码，云端自动编译 IPA，下载后用 Windows 工具安装到 iPhone。

## 三种方案对比

| 方案 | 费用 | 需要设备 | IPA 有效期 | 推荐度 |
|------|------|---------|-----------|--------|
| **方案 A: 未签名 + Sideloadly** | 免费 | 仅 Windows PC + iPhone | 7 天 | 最推荐（测试用） |
| **方案 B: 未签名 + 3uTools** | 免费 | 仅 Windows PC + iPhone | 7 天 | 推荐（中文界面） |
| **方案 C: 签名构建** | $99/年 | 需一次性借用 Mac | 1 年 | 适合长期分发 |

---

## 方案 A: 未签名构建 + Sideloadly 安装（推荐）

### 第一步：注册 GitHub 账号并创建仓库

1. 打开 https://github.com → 注册免费账号
2. 点击 **+** → **New repository**
3. 仓库名填 `Milo`，选择 **Public**（公开仓库完全免费），勾选 **Add a README file**
4. 点击 **Create repository**

### 第二步：上传项目到 GitHub

#### 方法 1：用 GitHub 网页上传（最简单）

1. 在你 Windows 电脑上，进入 `C:\Users\Administrator\Desktop\Milo` 目录
2. 在 GitHub 仓库页面点击 **uploading an existing file**
3. 把项目文件拖进去（注意：不要上传 `.git` 目录和 `node_modules` 等大目录）
4. 或者，在 `.gitignore` 中排除不需要的文件

#### 方法 2：用 Git 命令行上传（推荐）

```powershell
# 下载安装 Git for Windows: https://git-scm.com/download/win

# 打开 PowerShell，进入项目目录
cd C:\Users\Administrator\Desktop\Milo

# 初始化 Git
git init
git add .
git commit -m "Add iOS project with GitHub Actions"

# 添加远程仓库（替换成你的用户名）
git remote add origin https://github.com/你的用户名/Milo.git
git branch -M main
git push -u origin main
```

### 第三步：触发云端编译

推送代码后，GitHub Actions 会自动开始编译。你也可以手动触发：

1. 打开你的 GitHub 仓库页面
2. 点击 **Actions** 标签
3. 左侧选择 **iOS Build IPA**
4. 右侧点击 **Run workflow** → 选择 `unsigned` → 点击 **Run workflow**
5. 等待约 15-30 分钟（黄色圆圈表示正在运行）

> **提示**: 公开仓库完全免费，无限次构建。私有仓库每月 2000 分钟免费额度。

### 第四步：下载 IPA

1. 构建完成后（绿色对勾 ✓），点击对应的运行记录
2. 页面拉到底部，找到 **Artifacts** 区域
3. 点击 `XianLeiHuHu-unsigned.ipa` 下载
4. 保存到你 Windows 电脑上（如 `C:\Downloads\XianLeiHuHu-unsigned.ipa`）

### 第五步：安装 Sideloadly

1. 下载 Sideloadly: https://sideloadly.io/ → Download for Windows
2. 安装时需要：
   - **iTunes** (64位): https://www.apple.com/itunes/ → 选 "Windows" 下载
   - **.NET Framework 4.8**: 通常 Win10 已自带
3. 安装完成后打开 Sideloadly

### 第六步：签名并安装 IPA

1. 用 USB 数据线连接 iPhone 到电脑
2. 打开 Sideloadly
3. 顶部图标：点击 📁 选择下载的 `XianLeiHuHu-unsigned.ipa`
4. Apple ID 栏：输入你的 Apple ID（免费账号即可，不需要 $99 开发者账号）
5. 点击 **Start** 开始签名+安装
6. iPhone 上会提示"信任开发者"，按提示操作

#### iPhone 信任证书步骤
1. 设置 → 通用 → VPN与设备管理
2. 找到你的 Apple ID 对应的开发者描述述文件
3. 点击 → 信任

> **限制**: 免费 Apple ID 签名的 App 有效期 **7 天**，到期后需要重新签名安装。最多 3 台设备。

### 图示流程

```
Windows 电脑                    GitHub 云端 (macOS)              iPhone
    │                               │                             │
    │  git push 代码                  │                             │
    │──────────────────────────────▶│                             │
    │                               │  XcodeGen + Pod Install      │
    │                               │  xcodebuild 编译              │
    │                               │  打包 IPA                     │
    │  下载 IPA (Artifacts)          │                             │
    │◀──────────────────────────────│                             │
    │                               │                             │
    │  Sideloadly 签名 + 安装         │                             │
    │────────────────────────────────────────────────────────────▶│
    │                               │                             │
    │                               │                    设置→信任证书│
    │                               │                    App 可使用  │
```

---

## 方案 B: 未签名构建 + 3uTools 安装（中文界面）

3uTools 是中文界面，操作更直观：

### 1-4 步同方案 A（编译并下载 IPA）

### 第五步：安装 3uTools

1. 下载 3uTools: https://www.3u.com/
2. 安装并打开
3. 用 USB 连接 iPhone（需先信任电脑）

### 第六步：安装 IPA

1. 3uTools 顶部 → **应用&游戏** → **安装应用**
2. 拖入下载的 `XianLeiHuHu-unsigned.ipa`
3. 3uTools 会自动签名并安装
4. 需要登录 Apple ID（免费账号即可）
5. iPhone: 设置 → 通用 → VPN与设备管理 → 信任

> **优势**: 3uTools 界面中文，操作简单，支持一键安装。

---

## 方案 C: 签名构建（需要 Apple Developer 账户，无需 Mac）

如果你购买了 $99/年 Apple Developer 账户，可以获得 1 年有效期的签名。但需要一次性创建证书。

### 问题：没有 Mac 怎么创建 .p12 证书？

有三种方法：

### 方法 1: 借用 Mac 一次性创建证书（最简单）

找朋友/同事的 Mac，或去 Apple Store 用展示机，只需 10 分钟：

1. Apple Developer 网站 → 创建 iOS Distribution 证书
2. 钥匙串访问导出 .p12 文件
3. 创建 Provisioning Profile（注册你的设备 UDID）
4. 下载 .p12 和 .mobileprovision
5. 带回 Windows，用 `certutil` 生成 base64：

```powershell
# Windows 上生成 base64（PowerShell）
$bytes = [System.IO.File]::ReadAllBytes("cert.p12")
$base64 = [System.Convert]::ToBase64String($bytes)
$base64 | Set-Clipboard  # 复制到剪贴板

# 同样处理 mobileprovision
$bytes = [System.IO.File]::ReadAllBytes("profile.mobileprovision")
$base64 = [System.Convert]::ToBase64String($bytes)
$base64 | Set-Clipboard
```

### 方法 2: 使用云 Mac 服务（按小时付费）

| 服务 | 价格 | 说明 |
|------|------|------|
| MacinCloud | $1/小时 | https://www.macincloud.com/ |
| MacStadium | $50/月 | https://www.macstadium.com/ |
| AWS EC2 Mac | $26/月起 | 需 24小时最短租期 |
| XcodeClub | $15/月 | 性价比高 |

只需租 1 小时即可完成证书创建，然后永久使用 GitHub Actions 签名构建。

### 方法 3: 使用在线 CSR 生成器（免费但复杂）

1. 在线生成 CSR: https://certifyingly.com/ 或类似工具
2. 上传到 Apple Developer → 下载 .cer
3. 用 OpenSSL 转换 .cer + 私钥为 .p12（Windows 可装 OpenSSL）

```powershell
# 安装 OpenSSL for Windows
# https://slproweb.com/products/Win32OpenSSL.html

# 合并证书为 .p12
openssl pkcs12 -export -out cert.p12 -inkey private.key -in certificate.cer
```

### 配置好证书后

1. 将 5 个 Secrets 配置到 GitHub（按 GITHUB_ACTIONS_SETUP.md 指南）
2. 推送代码 → GitHub Actions 自动签名构建
3. 下载签名 IPA → 用 Sideloadly/3uTools 直接安装
4. 1 年有效期，不需要重新签名

---

## 不想推送到 GitHub？替代方案

如果不想用 Git，也可以用以下方式：

### 替代 1: Codemagic CI/CD（免费 500 分钟/月）

1. 注册 https://codemagic.io/
2. 连接 GitHub/GitLab/Bitbucket 仓库
3. 配置构建（提供 UI 界面，比 GitHub Actions 更直观）
4. 直接产出签名 IPA

### 替代 2: Appolocalypse（在线 Xcode 编译）

- https://appolocalipsis.com/
- 上传源码，云端编译
- 适合简单项目

### 替代 3: 使用 AltStore / SideStore（无需电脑编译）

如果你能从其他渠道获得已编译的 IPA：

**AltStore**:
1. Windows 安装 AltServer: https://altstore.io/
2. iPhone + Windows 同时连接同一 WiFi
3. AltServer 托盘图标 → Install AltStore
4. 通过 AltStore 安装 IPA

**SideStore**（AltStore 的无线版本）:
1. 安装 SideStore 后无需电脑即可重新签名
2. https://sidestore.io/

---

## 各方案对比总结

| 维度 | 方案A (Sideloadly) | 方案B (3uTools) | 方案C (签名) |
|------|-------------------|-----------------|-------------|
| 费用 | 免费 | 免费 | $99/年 |
| 需要 Mac | 不需要 | 不需要 | 借用1次 |
| 有效期 | 7天 | 7天 | 1年 |
| 操作难度 | 中（英文） | 低（中文） | 高 |
| 适合 | 测试 | 测试 | 长期使用 |
| 最多设备 | 3台 | 3台 | 100台 |

## 常见问题

### Q: GitHub Actions 构建失败怎么办？

A: 在 Actions 运行页面查看日志，常见问题：
- **Pod install 失败**: 检查 Podfile 语法
- **XcodeGen 失败**: 检查 project.yml 格式
- **编译错误**: 检查 Swift 代码语法

### Q: Sideloadly 提示 "Anisette server is down"

A: Sideloadly 设置中切换 Anisette server，或更新到最新版。

### Q: 安装后 App 闪退

A: iPhone: 设置 → 通用 → VPN与设备管理 → 信任你的 Apple ID 证书。7 天后需重新签名。

### Q: 免费账号每次只能签 3 个 App

A: 免费账号限制 3 个 App ID，删掉不用的 App 后重新签名。

### Q: 能不能 7 天自动续签？

A: 用 AltStore/SideStore 可以在 WiFi 下自动续签，但需要电脑开着 AltServer。SideStore 完全不需要电脑。

### Q: 每次改代码都要重新编译？

A: 是的，每次改代码 → push 到 GitHub → 下载新 IPA → 重新签名安装。GitHub Actions 每次约 15-30 分钟。
