#!/bin/bash
# WipeGuard 一键构建：编译通用二进制 → 组装 .app → 生成图标 → Ad-hoc 签名
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

APP_NAME="WipeGuard"
MIN_DEPLOY="10.15"
BUILD_DIR="$ROOT/build"
APP_ROOT="$ROOT/$APP_NAME.app"

echo "==> 清理旧构建"
rm -rf "$BUILD_DIR" "$APP_ROOT"
mkdir -p "$BUILD_DIR/arm64" "$BUILD_DIR/x86_64"

echo "==> 生成应用图标"
if [ ! -f "$ROOT/resources/AppIcon.icns" ] || [ "${FORCE_ICON:-0}" = "1" ]; then
    swift "$ROOT/scripts/make_icon.swift" "$ROOT/resources/WipeGuard.iconset"
    iconutil -c icns "$ROOT/resources/WipeGuard.iconset" -o "$ROOT/resources/AppIcon.icns"
else
    echo "    图标已存在，跳过（FORCE_ICON=1 可强制重新生成）"
fi

echo "==> 编译 arm64"
swiftc -O -swift-version 5 \
    -target "arm64-apple-macos${MIN_DEPLOY}" \
    -o "$BUILD_DIR/arm64/$APP_NAME" \
    Sources/WipeGuard/*.swift

echo "==> 编译 x86_64"
if swiftc -O -swift-version 5 \
    -target "x86_64-apple-macos${MIN_DEPLOY}" \
    -o "$BUILD_DIR/x86_64/$APP_NAME" \
    Sources/WipeGuard/*.swift; then
    echo "==> 合成通用二进制 (arm64 + x86_64)"
    lipo -create -output "$BUILD_DIR/$APP_NAME" \
        "$BUILD_DIR/arm64/$APP_NAME" "$BUILD_DIR/x86_64/$APP_NAME"
else
    echo "!! x86_64 编译失败，回退为仅 arm64"
    cp "$BUILD_DIR/arm64/$APP_NAME" "$BUILD_DIR/$APP_NAME"
fi

echo "==> 组装 $APP_NAME.app"
mkdir -p "$APP_ROOT/Contents/MacOS" "$APP_ROOT/Contents/Resources"
cp "$BUILD_DIR/$APP_NAME" "$APP_ROOT/Contents/MacOS/$APP_NAME"
cp "$ROOT/resources/Info.plist" "$APP_ROOT/Contents/Info.plist"
if [ -f "$ROOT/resources/AppIcon.icns" ]; then
    cp "$ROOT/resources/AppIcon.icns" "$APP_ROOT/Contents/Resources/"
fi
chmod +x "$APP_ROOT/Contents/MacOS/$APP_NAME"

echo "==> 签名"
SIGN_IDENTITY=""
if security find-identity -v -p codesigning 2>/dev/null | grep -qF "WipeGuard Dev"; then
    SIGN_IDENTITY="WipeGuard Dev"
fi
if [ -n "${SIGN_IDENTITY}" ]; then
    echo "    使用固定开发证书 ${SIGN_IDENTITY} （重新构建后辅助功能授权不会失效）"
    codesign --force --timestamp=none --sign "${SIGN_IDENTITY}" "$APP_ROOT"
else
    echo "    未找到 WipeGuard Dev 证书，回退 Ad-hoc 签名（每次构建后需重新授予辅助功能权限）"
    codesign --force --sign - "$APP_ROOT"
fi
codesign --verify --strict "$APP_ROOT"

echo "==> 构建完成"
echo "    $APP_ROOT"
lipo -info "$APP_ROOT/Contents/MacOS/$APP_NAME"
du -sh "$APP_ROOT"

if [ "${SKIP_DEPLOY:-0}" = "1" ]; then
    echo "==> 跳过部署 (SKIP_DEPLOY=1)"
else
    echo "==> 部署到 /Applications"
    DEPLOY_PATH="/Applications/$APP_NAME.app"
    if [ -d "$DEPLOY_PATH" ]; then
        # 结束正在运行的旧实例，否则文件替换后旧进程仍跑旧代码
        pkill -f "$DEPLOY_PATH/Contents/MacOS/$APP_NAME" 2>/dev/null || true
        sleep 0.5
        rm -rf "$DEPLOY_PATH"
    fi
    cp -R "$APP_ROOT" /Applications/
    codesign --verify --strict "$DEPLOY_PATH"
    echo "    已更新 ${DEPLOY_PATH} (固定证书签名，授权保持有效)"
    echo "    旧实例已结束，重新打开即用新版"
fi
