#!/bin/bash
#
# 闲雷虎虎 iOS — GitHub Actions 签名构建 Secrets 准备脚本
#
# 用法: 在 macOS 上运行此脚本，它会：
# 1. 检查你的 .p12 证书和 .mobileprovision 文件
# 2. 生成 base64 编码字符串
# 3. 输出需要添加到 GitHub Secrets 的所有值
#
# 用法:
#   chmod +x prepare_signing_secrets.sh
#   ./prepare_signing_secrets.sh /path/to/cert.p12 /path/to/profile.mobileprovision
#

set -e

# 颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}╔══════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║  闲雷虎虎 iOS — 签名 Secrets 生成工具           ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════╝${NC}"
echo ""

# 检查参数
P12_FILE="${1:-}"
PP_FILE="${2:-}"

if [ -z "$P12_FILE" ]; then
    echo -e "${YELLOW}请输入 .p12 证书文件路径:${NC}"
    read -r P12_FILE
fi

if [ -z "$PP_FILE" ]; then
    echo -e "${YELLOW}请输入 .mobileprovision 文件路径:${NC}"
    read -r PP_FILE
fi

# 检查文件存在
if [ ! -f "$P12_FILE" ]; then
    echo -e "${RED}错误: 找不到文件 $P12_FILE${NC}"
    exit 1
fi

if [ ! -f "$PP_FILE" ]; then
    echo -e "${RED}错误: 找不到文件 $PP_FILE${NC}"
    exit 1
fi

echo -e "${GREEN}✓ 证书文件: $P12_FILE${NC}"
echo -e "${GREEN}✓ 描述文件: $PP_FILE${NC}"
echo ""

# 检查 base64 命令
if ! command -v base64 &> /dev/null; then
    echo -e "${RED}错误: 未找到 base64 命令，请在 macOS 上运行此脚本${NC}"
    exit 1
fi

# 生成 base64
P12_BASE64=$(base64 -i "$P12_FILE")
PP_BASE64=$(base64 -i "$PP_FILE")

# 从 Provisioning Profile 中提取信息
PP_PLIST=$(security cms -D -i "$PP_FILE" 2>/dev/null || echo "")
PP_UUID=""
PP_NAME=""
PP_TEAM_ID=""

if [ -n "$PP_PLIST" ]; then
    PP_UUID=$(echo "$PP_PLIST" | /usr/libexec/PlistBuddy -c "Print UUID" /dev/stdin 2>/dev/null || echo "未知")
    PP_NAME=$(echo "$PP_PLIST" | /usr/libexec/PlistBuddy -c "Print Name" /dev/stdin 2>/dev/null || echo "未知")
    PP_TEAM_ID=$(echo "$PP_PLIST" | /usr/libexec/PlistBuddy -c "Print :TeamIdentifier:0" /dev/stdin 2>/dev/null || echo "")
fi

echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN} Provisioning Profile 信息${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "  Name:     ${GREEN}$PP_NAME${NC}"
echo -e "  UUID:     ${GREEN}$PP_UUID${NC}"
if [ -n "$PP_TEAM_ID" ]; then
    echo -e "  Team ID:  ${GREEN}$PP_TEAM_ID${NC}"
fi
echo ""

# 输出 GitHub Secrets
echo -e "${CYAN}╔══════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║  复制以下值到 GitHub Secrets                        ║${NC}"
echo -e "${CYAN}╠══════════════════════════════════════════════════╣${NC}"
echo ""

echo -e "${YELLOW}━━ 1. IOS_P12_CERTIFICATE ━━${NC}"
echo "$P12_BASE64"
echo ""

echo -e "${YELLOW}━━ 2. IOS_PROVISIONING_PROFILE ━━${NC}"
echo "$PP_BASE64"
echo ""

echo -e "${YELLOW}━━ 3. IOS_TEAM_ID ━━${NC}"
if [ -n "$PP_TEAM_ID" ]; then
    echo -e "${GREEN}$PP_TEAM_ID${NC}"
else
    echo -e "${RED}请手动从 Apple Developer → Membership 获取 Team ID${NC}"
fi
echo ""

echo -e "${YELLOW}━━ 4. IOS_P12_PASSWORD ━━${NC}"
echo -e "你导出 .p12 时设置的密码（手动输入到 GitHub Secret）"
echo ""

echo -e "${YELLOW}━━ 5. IOS_KEYCHAIN_PASSWORD ━━${NC}"
echo -e "${GREEN}$(date +%s | md5 | head -c 20)${NC}"
echo -e "（上面是自动生成的随机密码，你也可以用任意字符串）"
echo ""

echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN} 配置步骤${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "1. 打开你的 GitHub 仓库"
echo "2. 进入 Settings → Secrets and variables → Actions"
echo "3. 点击 New repository secret"
echo "4. 依次添加以上 5 个 Secret"
echo "5. 配置完成后，手动触发 workflow:"
echo "   Actions → iOS Build IPA → Run workflow → 选择 signed"
echo ""
echo -e "${GREEN}完成！配置好 Secrets 后，每次推送代码或 tag 都会自动构建签名 IPA${NC}"
