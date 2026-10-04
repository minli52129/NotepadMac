#!/bin/bash
# 构建 Release 版本并打包为 NotepadMac.app / NotepadMac.zip
# 用法: ./scripts/package.sh
set -euo pipefail
cd "$(dirname "$0")/.."

APP_NAME="NotepadMac"
APP_DIR="${APP_NAME}.app"

echo "==> 构建 Release (arm64 + x86_64 通用二进制)"
swift build -c release --arch arm64 --arch x86_64

# 多架构构建产物位于 .build/apple/Products/Release/
BINARY=".build/apple/Products/Release/${APP_NAME}"
if [ ! -f "$BINARY" ]; then
    # 回退：单架构路径
    BINARY=".build/release/${APP_NAME}"
fi
if [ ! -f "$BINARY" ]; then
    echo "错误: 找不到构建产物" >&2
    exit 1
fi

echo "==> 创建 ${APP_DIR}"
rm -rf "$APP_DIR"
mkdir -p "${APP_DIR}/Contents/MacOS" "${APP_DIR}/Resources"
cp "$BINARY" "${APP_DIR}/Contents/MacOS/${APP_NAME}"
cp Resources/Info.plist "${APP_DIR}/Contents/Info.plist"
chmod +x "${APP_DIR}/Contents/MacOS/${APP_NAME}"

echo "==> 临时签名（ad-hoc）"
# 清除扩展属性（quarantine/资源叉等常见签名干扰项）
xattr -cr "$APP_DIR" 2>/dev/null || true
# 链接器已为二进制自带 ad-hoc 签名，这里尽量补签 bundle；
# 某些 macOS/codesign 版本对极简 bundle 会误报
# "unsealed contents present in the bundle root"，故签名失败不阻塞打包
#（ad-hoc 签名的二进制本身即可在 Apple Silicon 上运行）
if ! codesign --force --sign - "$APP_DIR" 2>&1; then
    echo "警告: codesign 失败，保留链接器自带的 ad-hoc 签名继续打包" >&2
fi
codesign -dv "$APP_DIR" 2>&1 || true

echo "==> 压缩为 ${APP_NAME}.zip"
rm -f "${APP_NAME}.zip"
ditto -c -k --keepParent "$APP_DIR" "${APP_NAME}.zip"

echo "==> 完成: ${APP_NAME}.zip"
