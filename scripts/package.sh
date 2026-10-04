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
codesign --force --deep --sign - "$APP_DIR"

echo "==> 压缩为 ${APP_NAME}.zip"
rm -f "${APP_NAME}.zip"
ditto -c -k --keepParent "$APP_DIR" "${APP_NAME}.zip"

echo "==> 完成: ${APP_NAME}.zip"
