# WipeGuard 擦屏卫士

**擦拭 MacBook 屏幕与键盘时，锁定一切输入——不用关机。** 打开 WipeGuard，点「开始擦拭模式」，屏幕立即变为纯黑，键盘、触控板手势、鼠标、滚轮、媒体键的全部输入在系统层被丢弃。擦完按 `esc` 退出，就这么简单。

[![GitHub Releases 下载](https://img.shields.io/badge/下载-GitHub%20Releases-blue)](../../releases)
![platform](https://img.shields.io/badge/平台-macOS%2010.15%2B-arm64%20%2B%20x86__64)
![license](https://img.shields.io/badge/许可-MIT-green)

[English](README.md)

<!-- TODO(录制 5 秒演示 GIF 放这里)：进入擦拭模式 → 擦键盘 → esc 退出 -->
<!-- ![demo](docs/demo.gif) -->

## 它解决什么问题

给 Mac 擦屏幕、擦键盘时：

- 不想关机，但系统锁屏下随便按一个键屏幕就亮起，还往密码框里输入字符；
- 正在编辑的文档被误触打出一串乱码；
- 误触触控板触发捏合缩放，弄乱了开着的屏幕共享窗口。

擦屏卫士把所有屏幕盖成纯黑遮罩，并在系统事件层丢弃**全部**输入——不会点亮任何界面、不会留下任何输入、不会漏给任何 App。

## 竞品对比

| | **WipeGuard** | [KeyboardCleanTool](https://folivora.ai/keyboardcleantool/) | [pristine_screen](https://github.com/RhinoInani/pristine_screen) | [LUCE](https://github.com/arinltte/LUCE) |
|---|---|---|---|---|
| 拦截键盘 | ✅ | ✅ | ✅ | ✅ |
| 拦截鼠标 / 触控板 / 滚轮 / 手势 | ✅ | ✅ | ❌ 鼠标乱飞 | ❌（靠鼠标点按钮解锁） |
| 拦截媒体键（亮度 / 音量 / 背光 / 播放） | ✅ | ✅ | ❌ | ✅ |
| 全屏纯黑遮罩 | ✅ | ❌ 屏幕亮着 | ✅ | ❌ |
| 退出方式 | **esc 单键** | 组合键 | — | 点按钮 |
| 防休眠 / 屏保 / 自动锁屏 | ✅ | ❌ | ❌ | 仅亮度检查 |
| 失效保护（绝不"假锁定"） | ✅ | — | ❌ | 部分 |
| 合盖自动退出 | ✅ | ❌ | ❌ | ❌ |
| 双击即用 + 全局热键 | ✅ ⌥⌘K | ❌ | ✅ | ❌ |
| 原生零依赖 | ✅ 约 750KB 通用二进制 | — | Flutter | SwiftUI |
| 最低系统 | **10.15** | — | 未知 | 14 |
| 开源 | ✅ MIT | ❌ | ✅ | ✅ |

"失效保护"指：输入拦截因任何原因失效时，WipeGuard **立即自动结束擦拭模式并提示**，绝不停留在"看似锁定、实际没锁"的危险状态。

## 安装

从 [Releases](../../releases) 下载 `WipeGuard-<版本>-universal.zip`，解压后把 **WipeGuard.app** 拖入 `/Applications`。

- 构建使用 ad-hoc 签名（暂无 Apple 开发者证书），首次打开请**右键 → 打开 → 打开**，之后正常双击即可；
- 要求 macOS 10.15+；通用二进制（Apple Silicon + Intel）。

### 首次运行（一次性授权）

拦截系统输入需要**辅助功能**权限（本品类所有工具都需要）：

1. 首次打开会弹出引导，点「打开系统设置」；
2. 在 **系统设置 → 隐私与安全性 → 辅助功能** 中允许 WipeGuard；
3. 回到弹窗点「我已授权，重试」。

## 使用

| 操作 | 效果 |
|---|---|
| 打开 App → 「开始擦拭模式」（或随时 `⌥⌘K`） | 全屏变黑，锁定一切输入 |
| 按 `esc` | 退出擦拭模式，回到主窗口 |
| 电源键 | 保持系统原生行为（短按弹睡眠对话框，长按关机） |
| 关闭窗口（红钮） | App 留在 Dock，点 Dock 图标恢复窗口 |
| `⌘Q` | 彻底退出 |

擦拭期间 App 持有防休眠断言：屏幕不会自动熄灭、屏保不会启动、系统不会自动锁屏。合盖或系统休眠会**自动结束**擦拭模式，不会把你困在黑屏后面。

## 工作原理

约 1000 行零依赖 Swift：

- **输入拦截**：会话层 `CGEventTap`（head-insert）订阅*全部*事件类型并按白名单放行：`esc` 触发退出；电源键（`NX_KEY_TYPE_POWER`）放行；其余一律丢弃——包括媒体键（`NX_SYSDEFINED` subtype 8）、触控板手势、压力与数位板事件。tap 意外失效时重新启用或立即终止擦拭模式，绝不"假锁定"。
- **视觉遮罩**：每块屏幕一个无边框纯黑窗口（屏幕保护层级 1000），可加入所有 Space（含全屏 App），显示器热插拔自动重建。
- **状态保持**：`IOPMAssertionCreateWithName(PreventUserIdleDisplaySleep)` 阻止休眠/屏保；`NSWorkspace.willSleep` 兜底自动退出。

## 已知限制

- **Touch Bar**（2016–2019 款 MacBook Pro）：独立硬件屏幕，触摸仍会点亮背光（输入本身已被拦截）；
- 系统通知横幅可能浮在遮罩上层，擦拭期间建议开勿扰；
- 三指切换桌面等系统级手势在会话事件 tap 之下处理，极少数情况可能仍生效；
- 「登录时自动启动」仅 macOS 13+；
- 自行分发需重新签名公证。

## 隐私

无网络访问、无数据收集、无第三方代码。整个代码库一下午就能读完。

## 开发

要求：Xcode Command Line Tools（`xcode-select --install`）。

```bash
./scripts/build.sh          # 构建通用 WipeGuard.app（图标、双架构、lipo、签名）
```

- 构建脚本会自动部署到 `/Applications` 并结束正在运行的实例；设 `SKIP_DEPLOY=1` 可跳过（CI 如此）；
- 存在名为 **WipeGuard Dev** 的本地证书时自动使用（使辅助功能授权在重新构建后保持有效，见 `scripts/create_cert.sh`），否则回退 ad-hoc 签名；
- 自动化测试安全网：`WipeGuard.app/Contents/MacOS/WipeGuard --self-test <秒>` 在 N 秒后自动清理退出；`--self-test-start` 额外自动触发一次启动路径。

发布版由 GitHub Actions（`.github/workflows/release.yml`）在推送 tag 时自动构建。

## 许可

[MIT](LICENSE)
