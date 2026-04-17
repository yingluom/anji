# Anji — AI Development Prompt

> 本文件是给 AI 编程助手的上下文说明，描述项目目标、架构、约束和当前状态。
> 每次开新对话时可直接引用本文件。

---

## 1. 项目目标

开发一个 **iOS 闪卡学习 App**（名称 **Anji**），核心能力与 [Anki](https://github.com/ankitects/anki) 一致：

- **FSRS 间隔重复调度**（由官方 Rust 后端提供）
- **AnkiWeb 双向同步**（集合 + 媒体文件）
- **登录 AnkiWeb 账号**，凭据安全存储于 iOS Keychain
- 牌组浏览、复习、笔记编辑、统计、导入/导出 `.apkg` / `.colpkg`

**非目标**：不是 Anki 的完整移植，只做核心学习功能 + 同步。

---

## 2. 技术栈

| 层面 | 选型 |
|------|------|
| 语言 | **Swift 6.0**（strict concurrency = complete） |
| UI | **SwiftUI**（iOS 17+） |
| 后端 | **ankitects/anki rslib**（Rust），通过 C ABI 桥接 |
| 序列化 | **Protobuf**（swift-protobuf + prost） |
| DI | **swift-dependencies**（Point-Free） |
| 状态共享 | **swift-sharing**（`@Shared`） |
| 日志 | **swift-log** |
| 项目生成 | **XcodeGen**（`AnjiApp/project.yml` → `.xcodeproj`） |
| CI | **Codemagic**（`codemagic.yaml`），产出**无签名 IPA** |

开发者**没有 Mac 设备**，所有编译都在 Codemagic CI 上完成。

---

## 3. 架构（5 层）

```
SwiftUI Views  (AnjiApp/Sources/)
    ↕  @Dependency
AnkiClients    (Sources/AnkiClients/)      ← App 只看到这层
    ↕
AnkiServices   (Sources/AnkiServices/)     ← 业务逻辑，调 AnkiBackend
    ↕
AnkiBackend    (Sources/AnkiBackend/)      ← Swift FFI 包装器 (NSLock + protobuf)
    ↕  4 个 C 函数 (protobuf bytes)
AnkiRustLib    (anki-bridge-rs/ → XCFramework)
```

### 关键约定
- **AnkiKit**（`Sources/AnkiKit/`）：纯 Swift 领域类型，零外部依赖
- **AnkiProto**（`Sources/AnkiProto/`）：`protoc --swift_out` 生成，gitignored
- **AnkiSync**（`Sources/AnkiSync/`）：`KeychainHelper`，iOS Keychain 存取凭据
- Rust 桥只暴露 4 个 C 函数：`anki_open_backend` / `anki_close_backend` / `anki_run_method` / `anki_free_response`
- `AnkiBackend` 内部用 `NSLock` 保证线程安全；Swift 6 strict concurrency 下标记为 `Sendable`
- Service/Method 常量以 `package enum` 定义在 `AnkiBackend` 的扩展中

---

## 4. 仓库结构

```
anji/
├── AnjiApp/                    # iOS App（XcodeGen 项目）
│   ├── project.yml             # XcodeGen 配置
│   ├── Info.plist
│   ├── AnjiApp.entitlements
│   └── Sources/                # SwiftUI 视图层
│       ├── AnjiApp.swift       # @main 入口
│       ├── MainTabView.swift
│       ├── Decks/              # 牌组列表 & 详情
│       ├── Browse/             # 笔记搜索 & 编辑
│       ├── Review/             # 复习会话 (WebView 渲染卡片)
│       ├── Stats/              # 统计图表
│       ├── Sync/               # 登录 & 同步 UI
│       ├── Shared/             # 通用组件
│       └── Theme/              # 颜色、字体、组件样式
├── Sources/                    # Swift Package 模块
│   ├── AnkiKit/                # 领域类型（零依赖）
│   ├── AnkiProto/              # 生成的 protobuf 类型（gitignored）
│   ├── AnkiBackend/            # Rust FFI 包装器
│   ├── AnkiServices/           # 业务逻辑服务层
│   ├── AnkiClients/            # App 接口层 (@DependencyClient)
│   └── AnkiSync/               # Keychain 凭据存储
├── Tests/
├── anki-bridge-rs/             # Rust C ABI 桥（staticlib）
│   ├── Cargo.toml
│   ├── src/lib.rs
│   └── include/anki_bridge.h
├── anki-upstream/              # git submodule → ankitects/anki
├── scripts/
│   ├── build-xcframework.sh    # 交叉编译 Rust → XCFramework
│   ├── generate-protos.sh      # protoc 生成 Swift 类型
│   └── ExportOptions.plist
├── Package.swift               # SPM 包定义（AnjiBridge）
├── codemagic.yaml              # CI 流水线
└── README.md
```

---

## 5. 构建流水线（Codemagic）

1. **Install Rust** — `rustup target add aarch64-apple-ios aarch64-apple-ios-sim`
2. **Install tools** — `brew install protobuf swift-protobuf xcodegen`
3. **Checkout submodules** — `git submodule update --init --recursive`
4. **Build XCFramework** — `./scripts/build-xcframework.sh`（Rust 交叉编译 → `AnkiRust.xcframework`）
5. **Generate protos** — `./scripts/generate-protos.sh`
6. **XcodeGen** — `cd AnjiApp && xcodegen generate`
7. **Trust macros** — `defaults write` 跳过 Xcode 16 宏指纹验证
8. **Resolve SPM** — `xcodebuild -resolvePackageDependencies -skipMacroValidation -skipPackagePluginValidation`
9. **Archive** — `xcodebuild archive` (无签名: `CODE_SIGNING_ALLOWED=NO`)
10. **Package IPA** — 手动从 `.xcarchive` 提取 `.app` → zip 为 `.ipa`（`xcodebuild -exportArchive` 对无签名 archive 不可用）

---

## 6. 已知约束 & 注意事项

- **Xcode 16 宏验证**：CI 必须加 `-skipMacroValidation -skipPackagePluginValidation` 和 `defaults write com.apple.dt.Xcode IDESkipMacroFingerprintValidation -bool YES`（`IDESkipPackagePluginFingerprintValidatation` 的拼写是 Apple 原始键名，多了一个 `ta`）
- **无签名构建**：不能用 `xcodebuild -exportArchive`，需手动打包 Payload → zip
- **Swift 6 strict concurrency**：所有公共类型必须 `Sendable`；`AnkiBackend` 用 `NSLock` + `nonisolated(unsafe)` 处理可变状态
- **Rust 编译耗时**：首次约 15-30 分钟，Codemagic 上通过 `$HOME/.cargo` 缓存加速
- **AnkiProto 是生成文件**：不应手动编辑，CI 每次重新生成
- **anki-upstream 是 git submodule**：指向 `ankitects/anki`
- **AGPL-3.0 许可证**：因为依赖 ankitects/anki

---

## 7. 参考项目

- **anki 官方**: https://github.com/ankitects/anki — Rust 后端源码
- **amgi**: https://github.com/antigluten/amgi — 参考其 Rust FFI 桥接模式，但不照搬代码

---

## 8. 代码风格要求

- 遵循 iOS 开发准则（Human Interface Guidelines 精神）
- 有自己的视觉风格（`AnjiColors`, `AnjiTypography`, `AnjiComponents`）
- 不照搬 amgi 代码，架构可参考但实现独立
- 模块间通过 `swift-dependencies` 解耦，便于测试
- `package` 访问级别用于模块内 API（Swift 5.9+）
- 每个 Service/Client 都有 `TestDependencyKey` 实现

---

## 9. GitHub 仓库

- **地址**: https://github.com/yingluom/anji
- **默认分支**: `master`
- **远程**: `origin`
