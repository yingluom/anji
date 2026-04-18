# Anji

<p align="center">
  <img src="AnjiApp/Resources/Assets.xcassets/AppIcon.appiconset/icon_1024.png" width="128" height="128" alt="Anji アイコン">
</p>

<p align="center">
  <strong>公式 Anki Rust バックエンドを採用した iOS 単語帳アプリ</strong>
</p>

<p align="center">
  <a href="README.md">English</a> | <a href="README_CN.md">简体中文</a> | <a href="README_JP.md">日本語</a>
</p>

<p align="center">
  <a href="https://github.com/yingluom/anji/releases">
    <img src="https://img.shields.io/github/v/release/yingluom/anji?color=blue" alt="バージョン">
  </a>
  <a href="https://github.com/yingluom/anji/actions">
    <img src="https://img.shields.io/github/workflow/status/yingluom/anji/CI?label=CI" alt="CI">
  </a>
  <img src="https://img.shields.io/badge/iOS-18+-blue?logo=apple" alt="iOS 18+">
  <img src="https://img.shields.io/badge/Swift-6.0-orange?logo=swift" alt="Swift 6.0">
  <a href="LICENSE">
    <img src="https://img.shields.io/badge/License-AGPL--3.0-green" alt="ライセンス">
  </a>
</p>

---

Anji はオープンソースの iOS 単語帳アプリで、[Anki](https://apps.ankiweb.net/) の全機能を iPhone と iPad にもたらします。公式 Anki Rust バックエンド（`rslib`）を採用し、AnkiWeb 同期、FSRS スケジューリングアルゴリズム、すべての Anki カード機能と 100% 互換性があります。

## 機能

Anji は効果的な間隔反復学習のための完全な機能セットを提供します：

**同期とデータ**
- AnkiWeb 同期：コレクションデータとメディアファイルの完全な双方向同期
- インクリメンタル同期と進捗トラッキング
- MD5 チェックサムによるメディアファイル整合性検証
- 欠落または破損したメディアファイルの自動ダウンロード

**学習システム**
- FSRS アルゴリズム：最適な定着のための次世代間隔反復スケジューリング
- カードブラウザ：高度なクエリによる検索、フィルタリング、管理
- カスタム学習：集中復習セッション用のフィルターデッキ作成
- タグ管理：階層タグによるカード整理
- **スマートカードエディタ**：フィールドカテゴリ、タグ管理、書式ツールバー、多言語サポート

**学習インターフェース**
- クリーンで集中できる復習インターフェース
- すべての Anki カードタイプをサポート：標準、穴埋め、入力回答など
- リッチメディアサポート：カード内の画像、オーディオ、動画再生
- ナイトモードと3つのテーマバリエーション（ライト、ダーク、システム）
- **取り消し/やり直し**：最後の復習アクションを取り消し
- **ライブアクティビティ**：ダイナミックアイランドとロック画面ウィジェット対応（iOS 16.1+）

**統計と分析**
- 今日の概要：復習予定カード、完了した復習、学習時間
- 予測チャート：今後の復習作業量を可視化
- 復習履歴：長期的な学習進捗を追跡
- 間隔と易度チャート：カード難易度分布を理解
- **10+ 統計カード**：定着率、カード数、連続記録など
- **カスタマイズ可能なホーム**：メインデッキリストに表示する統計を選択

**毎日のインスピレーション**
- **毎日の名言**：Hitokoto/今日诗词 API からの名言（オン/オフ切り替え可能）
- **複数の名言ソース**：異なる名言ソース間で切り替え可能

**ローカリゼーション**
- 完全な英語、簡体字中国語、繁体字中国語、日本語インターフェース
- RTL 言語サポート準備
- ロケール対応の日付と数字の書式設定

## ダウンロード

GitHub Releases から最新のビルド済み IPA を入手：

<p align="center">
  <a href="https://github.com/yingluom/anji/releases/latest">
    <img src="https://img.shields.io/github/v/release/yingluom/anji?label=IPAをダウンロード&color=blue&style=for-the-badge" alt="最新リリースをダウンロード">
  </a>
</p>

| リリースタイプ | リンク | 説明 |
|-------------|--------|------|
| **最新安定版** | [Releases](https://github.com/yingluom/anji/releases/latest) | 本番環境対応ビルド |
| **すべてのリリース** | [Releases](https://github.com/yingluom/anji/releases) | バージョン履歴 |
| **ナイトリービルド** | [Codemagic](https://codemagic.io) | 最新 CI アーティファクト |

### システム要件

- iOS 18.0 以降
- iPhone または iPad
- 約 200MB の空き容量

## インストール方法

### サイドロード（推奨）

Anji は署名されていない IPA として配布されています。以下のツールのいずれかを使用してインストールできます：

#### 1. SideStore（推奨 ⭐）
ほとんどのユーザーに最適です。初期設定後は PC が不要です。

1. デバイスに [SideStore](https://sidestore.io/) をインストール
2. 最新の `AnjiApp-unsigned.ipa` をダウンロード
3. SideStore を開いて → 「マイアプリ」→ 「+」→ IPA を選択
4. Apple ID でログイン（無料の開発者アカウント）

#### 2. Sideloadly（無料、PC が必要）
USB 経由でのワンタイムインストールに適しています。

1. [Sideloadly](https://sideloadly.io/)（Windows/macOS）をダウンロード
2. USB でデバイスを接続
3. IPA を Sideloadly にドラッグ
4. Apple ID を入力してインストール

#### 3. AltStore（無料、PC が必要）
人気のある代替案で、自動更新をサポートしています。

1. PC に [AltStore](https://altstore.io/) をインストール
2. デバイスを接続して AltStore をインストール
3. デバイスで AltStore を開いて → 「マイアプリ」→ 「+」
4. ダウンロードした IPA を選択

#### 4. ESign / Scarlet（有料証明書）
PC は不要で、エンタープライズ証明書を使用します。

| ツール | コスト | PC | 自動更新 | 備考 |
|--------|--------|-----|----------|------|
| [SideStore](https://sidestore.io/) | 無料 | 初回のみ | ✅ 7日間 | **推奨** |
| [Sideloadly](https://sideloadly.io/) | 無料 | 常に必要 | ❌ 手動 | USB インストールが簡単 |
| [AltStore](https://altstore.io/) | 無料 | 常に必要 | ✅ WiFi | 人気のある代替案 |
| ESign / Scarlet | 有料 | 不要 | ✅ 1年間 | 証明書を使用 |

## スクリーンショット

<p align="center">
  <img src="screenshots/deck_list.png" width="200" alt="デッキリスト">
  <img src="screenshots/review_mode.png" width="200" alt="復習モード">
  <img src="screenshots/card_editor.png" width="200" alt="カードエディタ">
  <img src="screenshots/statistics.png" width="200" alt="統計">
</p>

> 注：`screenshots/` フォルダにスクリーンショットを追加してください

## 技術アーキテクチャ

```
┌─────────────────────────────────────────────────────────┐
│  SwiftUI ビューレイヤー (iOS 18+)                         │
│  - 復習インターフェース                                   │
│  - 統計チャート                                          │
│  - 設定とブラウザ                                        │
└─────────────────────────────────────────────────────────┘
                          ↕ @DependencyClient
┌─────────────────────────────────────────────────────────┐
│  AnkiClients （アプリケーションフェイシングインターフェース層）│
│  swift-dependencies を使用した型安全インターフェース         │
└─────────────────────────────────────────────────────────┘
                          ↕
┌─────────────────────────────────────────────────────────┐
│  AnkiServices （ビジネスロジック層）                      │
│  同期、復習、統計、メディア管理                           │
└─────────────────────────────────────────────────────────┘
                          ↕ Protocol Buffers
┌─────────────────────────────────────────────────────────┐
│  AnkiBackend （Swift FFI ラッパー）                     │
│  Rust ライブラリへの C ABI バインディング                 │
└─────────────────────────────────────────────────────────┘
                          ↕ C ABI
┌─────────────────────────────────────────────────────────┐
│  Rust (ankitects/anki rslib)                            │
│  - SQLite ストレージ                                    │
│  - AnkiWeb 同期プロトコル                               │
│  - FSRS スケジューラー                                  │
│  - カードレンダリングエンジン                            │
└─────────────────────────────────────────────────────────┘
```

**重要な FFI 関数：**
- `anki_open_backend` / `anki_close_backend`
- `anki_run_method`（protobuf リクエスト → レスポンス）
- `anki_free_response`

## ソースからのビルド

### 環境要件

- macOS 14+（Sonoma 以降）
- Xcode 16+（iOS 18 SDK を含む）
- Rust ツールチェーン（stable）
- Homebrew

```bash
# Rust をインストール（未インストールの場合）
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
rustup target add aarch64-apple-ios aarch64-apple-ios-sim

# ビルドツールをインストール
brew install protobuf swift-protobuf xcodegen
```

### ワンコマンドビルド（推奨）

クローン、パーミッション設定、ビルドを完了させるワンコマンド：

```bash
git clone --recurse-submodules https://github.com/yingluom/anji.git && cd anji && bash scripts/build-local.sh
```

このスクリプトは自動的に `chmod`、サブモジュールの初期化、依存関係チェック、Rust のコンパイル、protobuf の生成、Xcode プロジェクト設定、パッケージング、IPA の出力を処理します。

その他のモード：

```bash
bash scripts/build-local.sh --skip-rust  # 既存の XCFramework を再利用
bash scripts/build-local.sh --sim        # シミュレータービルド（迅速なイテレーション）
bash scripts/build-local.sh --clean      # すべてのアーティファクトをクリーンしてから再ビルド
```

ビルドログは `build/build.log` に保存され、失敗時にはエラー情報とファイルパス、行番号が自動的に抽出されます。出力 IPA は `build/AnjiApp-unsigned.ipa` にあります。

### 手動ビルド

段階的に実行したい場合：

```bash
git clone --recurse-submodules https://github.com/yingluom/anji.git
cd anji

# 1. Rust XCFramework をコンパイル（実機 + シミュレーター）
./scripts/build-xcframework.sh

# 2. 上流の .proto ファイルから Swift protobuf 型を生成
./scripts/generate-protos.sh

# 3. project.yml から Xcode プロジェクトを生成
cd AnjiApp && xcodegen generate && cd ..

# 4. Xcode で開いてビルド
open AnjiApp/AnjiApp.xcodeproj
```

## 継続的インテグレーション

[Codemagic](https://codemagic.io) による自動化ビルド：

- すべてのコミットがフルビルドをトリガー
- 署名されていない IPA アーティファクトを生成
- ユニットテストとリンティングを実行

設定は [`codemagic.yaml`](codemagic.yaml) と [`.github/workflows/`](.github/workflows/) を参照してください。

## 技術スタック

- **言語**：Swift 6.0
- **UI フレームワーク**：SwiftUI
- **アーキテクチャ**：Swift Dependencies + Composable Architecture パターン
- **バックエンド**：Rust FFI（Anki rslib）
- **同期プロトコル**：AnkiWeb REST API
- **CI/CD**：GitHub Actions + Codemagic

## 貢献

貢献を歓迎します！PR を送信する前に、[貢献ガイドライン](CONTRIBUTING.md) をお読みください。

### 貢献者クイックスタート

```bash
# フォークしてクローン
git clone --recurse-submodules https://github.com/YOUR_USERNAME/anji.git
cd anji

# すべてをビルド
bash scripts/build-local.sh

# または Xcode で開発
cd AnjiApp && xcodegen generate && open AnjiApp.xcodeproj
```

## 謝辞

- [Anki](https://apps.ankiweb.net/) by Damien Elmes - オリジナルの間隔反復ソフトウェア
- [ankitects/anki](https://github.com/ankitects/anki) - 公式 Anki Rust バックエンド
- [PointFree](https://www.pointfree.co/) - swift-dependencies と優れた Swift ライブラリを提供
- [Swift Composable Architecture](https://github.com/pointfreeco/swift-composable-architecture) - アーキテクチャのインスピレーション

---

<p align="center">
  <sub>世界中の学習者のために作られました ❤️</sub>
</p>

## ライセンス

**AGPL-3.0** — このプロジェクトは [ankitects/anki](https://github.com/ankitects/anki) Rust バックエンドを使用しており、AGPL-3.0 ライセンスです。すべての派生作品はこのライセンスを遵守する必要があります。
