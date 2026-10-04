# NotepadMac

macOS 原生的轻量级文本/代码编辑器，类似 Notepad++。使用 Swift + SwiftUI/AppKit 开发，无需 Xcode 工程文件，通过 Swift Package Manager 构建。

## 功能

- **多标签页**：新建 / 打开 / 关闭标签页，`Ctrl+Tab` 切换，拖拽文件到窗口直接打开
- **语法高亮**：Swift、Python、JavaScript/TypeScript、Java、C/C++、Go、Rust、Ruby、Shell、JSON、HTML、CSS、XML、YAML、Markdown、SQL 等
- **行号栏**：随内容自动调整宽度
- **查找 / 替换**：`Cmd+F` 查找（支持回绕、区分大小写、全量高亮），`Cmd+Option+F` 替换，`Cmd+G` 查找下一个
- **跳转到行**：`Cmd+L`
- **编码支持**：自动探测 UTF-8 / GB18030 / ISO-8859-1，状态栏可按指定编码重新打开
- **换行符**：自动识别 LF / CRLF / CR，状态栏一键转换
- **状态栏**：光标行列、字符数、语言、编码、换行符
- **未保存提醒**：关闭标签页时提示存储
- 原生体验：深色模式、访达「打开方式」、撤销重做

## 构建

### 本地（需要 macOS + Xcode 命令行工具）

```bash
# 直接运行
swift run

# 打包为 .app（通用二进制 arm64 + x86_64）并压缩
./scripts/package.sh
```

产物为 `NotepadMac.app` 与 `NotepadMac.zip`。

### GitHub Actions

推送到 `main` 分支或创建 PR 即自动构建，产物以 Artifact 形式上传（`NotepadMac-macos-universal`）。

推送 `v*` 形式的 tag（如 `v1.0.0`）会自动创建 GitHub Release 并附上 zip 包：

```bash
git tag v1.0.0
git push origin v1.0.0
```

> 应用使用 ad-hoc 签名。首次打开时如提示「无法验证开发者」，请在「系统设置 → 隐私与安全性」中允许，或右键 → 打开。

## 项目结构

```
NotepadMac/
├── Package.swift                 # SwiftPM 清单（executableTarget）
├── Resources/Info.plist          # App Bundle 信息
├── scripts/package.sh            # 打包脚本（CI 复用）
├── .github/workflows/build.yml   # GitHub Actions 构建/发布
└── Sources/NotepadMac/
    ├── NotepadMacApp.swift       # 应用入口、菜单命令
    ├── AppDelegate.swift         # 打开文件、激活策略
    ├── Models/
    │   ├── TextDocument.swift    # 文档模型（编码/换行符/语言）
    │   └── DocumentStore.swift   # 标签页管理、打开保存、查找状态
    ├── Editor/
    │   ├── EditorViewController.swift  # NSTextView 装配、查找替换
    │   ├── LineNumberRulerView.swift   # 行号栏
    │   ├── SyntaxHighlighter.swift     # 正则语法高亮
    │   └── Language.swift              # 语言定义（19 种）
    └── Views/                    # SwiftUI 界面（标签栏/查找栏/状态栏）
```

## 已知限制

- 语法高亮基于正则、全文重扫，超大文件（数 MB）输入时可能有卡顿
- 未做代码签名公证（notarization），如需分发请配置开发者证书
