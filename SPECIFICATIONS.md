# Swift Photos 要件

## 機能要件

### 主機能

- フォルダ単位で画像を一枚ずつ表示する機能を持つこと (must)
  - ウィンドウ枠全てを画像の表示領域として利用できること (should)
  - 画像の表示されない領域は、画像の blur がかかること (nice to have)
  - 対象の画像ファイルは jpg, heic, gif を対象とする (must)
  - gif は Animation GIF へ対応すること (should)
- スライドショーを実現できること (must)
  - スライドショーの切替時間は 1,2,3,5,10,20,30,60,120,300 程度の間隔で設定ができること (must)
  - Repeat 機能で画像の終わりまできたら銭湯へ戻る機能を on/off できること (should)
- 戻る/進む と、スライドショーの再生/停止の Toggle ボタンを持つ小さいコントローラーで画像の操作が出来ること (must)
  - コントローラーは背後の画像を blur しつつ透過できること (nice to have)
  - マウスやキーボードの操作がない時は非表示となること (should)
  - プログレスバーを持ち、プログレスバーをクリックするとその位置の画像を表示できる (nice to have)
- 左右上下のカーソルキーの入力により閲覧する画像の進めたり戻せること (must)
- F キーでフルスクリーンと標準ウィンドウを Toggle 操作できること (must)
- 画像表示順番を昇順、降順でソートできること (must)
  - ファイル名のアルファベット順
  - ファイルの作成日順
  - ファイルのサイズ順
  - ランダム (フォルダを指定するたびに毎回ランダムシードが変更される)
- 上記の機能を利用できる Window Menu を持つこと (must)
- 上記の設定が可能な設定ウィンドウを “⌘,” や Window Menu から実行できること (must)
  - 設定は動的に変更されること (should)

### UI/UX に関する詳細機能

- 画像のリサイズ方法をユーザが選択可能 (nice to have)

  - Fit（アスペクト比維持で全体表示） (must)

  - Fill（画面を埋める、クロップあり）

  - Actual Size（実サイズ表示）

- ズーム機能 (nice to have)
  - 将来実装可能であれば良い
    - ピンチジェスチャー対応
    - ズームレベルの範囲（10%-1000%）

### エラーハンドリング

- 破損した画像ファイルはスキップする
- アクセス権限のないフォルダは権限要求する
- ネットワークドライブの画像も対応する
- 画像が 0 枚のフォルダは表示しない

### データの永続化

- 設定の保存先：UserDefalt に保存すること
- 最後に見た画像の位置を記憶する (ランダムの場合は保持しない)
- お気に入り/レーティング機能は将来実装するかも知れない
- 閲覧履歴は 10 件から 100 件保持できること(設定で変更可能)

### セキュリティ要件

- App Sandbox を有効にする
- 必要な Entitlements：
  □ com.apple.security.files.user-selected.read-only
  □ com.apple.security.files.downloads.read-write
  □ com.apple.security.files.bookmarks.app-scope
- Mac App Store での配布予定あり

### 国際化/アクセシビリティ

- 対応言語: 日本語と英語、将来的にはスペインやフランス語、中国語などにも拡張可能な仕様とする
- VoiceOver 対応は不要
- キーボードのみでの完全操作が必要
- ハイコントラストモード対応

## 機能要求 (将来要件)

- 追加画像ファイルの対応
  - RAW ファイルへの対応
  - EXIF 情報の表示 (on/off が可能)
  - mac で標準で対応していない画像フォーマットを変換して表示できる機能をプラグインできること
  - プラグイン可能な Interface を想定しておくこと
- Traisition 機能の対応
  - 画像の切替時にエフェクトを利用できるよう拡張できること
  - エフェクト機能は、プラグインで増やすことができること
  - プラグイン可能な Interface と仕様を想定しておくこと
-

## 非機能要件

- パフォーマンス要求
  - 10 万枚以上の画像を表示する能力をもつこと
    - 想定する平均的な画像サイズは 5MB 未満
      - ただし最大で 50MB 程度のファイルであっても表示可能な機能を有すること
    - メモリ使用量の上限目標
      - ユーザーが設定できること
      - 設定ウィンドウから設定する
      - ファイルの枚数と利用可能なメモリ状況からある程度キャッシュサイズなどを自動で割り当てられることが望ましい
      - 必要に応じてキャッシュ機能を持つライブラリの利用も想定すること
      - キャッシュサイズを動的に制御して稼働することを前提とする
    - プリロード戦略
      - 10 枚から 1,000 枚をユーザーが設定可能
      - メモリ状況に合わせて基本的には自動的に動的に設定される
      - 非同期で読み込まれる
    - サムネイル生成は不要
    - 全ての画像データを読み込むのではなく、割り当てられたメモリや画像の枚数に応じて変動するキャッシュ機能を持ち、高速な画像表示を実装する。キャッシュされていれば 10ms 前後で表示できること

## 技術要件

- Xcode16/Swift6/SwiftUI の仕様に準ずること
- Mac の arm アプリケーションであること
- Mac version 14+ 対応
- MVVM またはそれに準ずる構造であること
- 一つの機能もしくは一つの責任分解点が、一つのファイル内で完結すること
- 設定によって debug log を出力する機能を持つこと
- 機能の追加や改修が、他のファイルへの影響が最小化する構造となること
- 影響を抑制する為の抽象化層やデザインパターンを採用しても良い
- 一つのファイルのサイズは人間が見通せる行数とすること

## プロジェクト要件

- アプリ名: Swift Vierwer
- Bundle Identifier: oshiire.SwiftViewer
- 開発チーム設定: Takashi Abe
- Code Signing の方式: Development
- 最小デプロイメントターゲット macOS 14.0 以降
- テスト駆動仕様に従うこと
- 作業は step by step で一つのファイル、又は一つの機能、一つのバグ修正の単位で進めること
  - コンパイルでのビルドエラーなく実行可能な最小限の単位を選択すること
- git と github を利用してコードを管理する
  - 各単位では git の branch を作成して commit を行い、GitHub へ push して Pull Request を上げること
  - Pull Request の内容を品質管理の担当者が確認し、merge を行う
  - Merge された branch から次の作業を始めること
  - git の branch 戦略は GitHub Flow に従うこと
- cipher mcp を必ず利用すること
  - ファイルの read/write や検索などの主体は serena を利用すること
  - 計画、設計内容、実行の結果などの記録は全て cipher を利用すること

#### 📝 Cipher MCP の活用戦略

##### **1. プロジェクト初期設定での指示**

````markdown
Claude Code への初期指示例：

# SwiftViewer プロジェクトの初期化

## Cipher MCP での記録管理

以下の内容を Cipher MCP を使って記録・管理してください：

1. プロジェクト構造の記録

   - cipher_upsert_memory でプロジェクト構造を "project_structure" として保存
   - アーキテクチャ決定事項を "architecture_decisions" として記録

2. 開発進捗の追跡

   - 各機能実装前に cipher_upsert_memory で実装計画を記録
   - 実装完了後に結果と学んだことを更新

3. テスト戦略の記録
   - TDD サイクルごとに "test*cycle*[番号]" として記録
   - テストカバレッジの推移を "test_coverage_history" に記録

## 具体的な使用例

### 新機能開発時

```bash
# 1. 計画段階
cipher_upsert_memory(
  key: "feature_image_cache_plan",
  value: {
    "目的": "画像キャッシュ機能の実装",
    "設計": "LRUキャッシュ、最大100枚",
    "テスト計画": "メモリ使用量、パフォーマンステスト",
    "開始日時": "2024-01-XX"
  }
)

# 2. 実装後
cipher_upsert_memory(
  key: "feature_image_cache_result",
  value: {
    "実装内容": "NSCacheベースの実装",
    "テスト結果": "10ms以下の読み込み達成",
    "課題": "メモリ警告時の処理追加必要",
    "完了日時": "2024-01-XX"
  }
)
```
````

##### **2. アーキテクチャ設計の記録**

```markdown
## アーキテクチャ設計の記録指示

Cipher MCP で以下の構造で設計を記録してください：

cipher_upsert_memory(
key: "architecture_mvvm",
value: {
"pattern": "MVVM + Repository",
"layers": {
"presentation": ["Views", "ViewModels"],
"domain": ["Models", "UseCases"],
"data": ["Repositories", "DataSources"]
},
"dependencies": {
"DI_container": "Protocol-based injection",
"async_handling": "async/await + Combine"
}
}
)

各モジュールの責務を記録：
cipher_upsert_memory(
key: "module_responsibilities",
value: {
"ImageLoader": "画像の非同期読み込み",
"ImageCache": "メモリキャッシュ管理",
"FileManager": "ファイルシステムアクセス",
"SettingsManager": "UserDefaults 管理"
}
)
```

##### **3. TDD サイクルの記録**

```markdown
## TDD サイクルごとの記録

各テストサイクルで以下を記録：

# RED Phase

cipher_upsert_memory(
key: "tdd_cycle_001_red",
value: {
"feature": "画像読み込み",
"test_name": "test_loadImage_success",
"expected": "URL から画像を読み込める",
"status": "FAILING"
}
)

# GREEN Phase

cipher_upsert_memory(
key: "tdd_cycle_001_green",
value: {
"implementation": "ImageLoader.loadImage()実装",
"code_location": "Sources/ImageLoader.swift",
"status": "PASSING"
}
)

# REFACTOR Phase

cipher_upsert_memory(
key: "tdd_cycle_001_refactor",
value: {
"changes": ["エラーハンドリング追加", "async/await 化"],
"performance": "読み込み時間: 50ms → 30ms",
"status": "COMPLETED"
}
)
```

##### **4. Git ワークフローとの連携**

```markdown
## Git 操作との連携記録

# ブランチ作成時

cipher_upsert_memory(
key: "branch_feature_image_cache",
value: {
"branch_name": "feature/image-cache",
"created_from": "main",
"purpose": "画像キャッシュ機能の実装",
"pr_number": null
}
)

# PR 作成時

cipher_upsert_memory(
key: "pr_123",
value: {
"branch": "feature/image-cache",
"files_changed": 15,
"tests_added": 8,
"coverage_delta": "+5%",
"review_status": "pending"
}
)
```

##### **5. 継続的な設計判断の記録**

```markdown
## 設計判断の記録（ADR: Architecture Decision Records 形式）

cipher_upsert_memory(
key: "adr_001_cache_strategy",
value: {
"title": "画像キャッシュ戦略の選択",
"context": "10 万枚の画像を扱う必要がある",
"decision": "NSCache とディスクキャッシュの併用",
"consequences": {
"positive": ["高速アクセス", "メモリ効率"],
"negative": ["実装の複雑化"],
"mitigation": ["抽象化層の導入"]
},
"date": "2024-01-XX"
}
)
```

### CI/CD

- GitHub のリポジトリ: https://github.com/sho7650/SwiftViewer
- CI/CD ツール: Github Actions
- コードカバレッジのしきい値: 75% 以上
- SwiftLint を利用する

```yaml
# .swiftlint.yml - 画像閲覧アプリ向け推奨設定

# 基本ルール
included:
  - Sources
  - Tests

excluded:
  - .build
  - DerivedData
  - ${PODS_ROOT}

# 有効にすべきルール
opt_in_rules:
  # コード品質
  - empty_count
  - empty_string
  - first_where
  - sorted_first_last
  - contains_over_filter_count
  - contains_over_filter_is_empty
  - flatmap_over_map_reduce

  # 可読性向上
  - multiline_parameters
  - multiline_function_chains
  - vertical_parameter_alignment_on_call
  - closure_end_indentation

  # SwiftUI特有
  - multiple_closures_with_trailing_closure
  - modifier_order # SwiftUIのmodifier順序

  # 安全性
  - force_unwrapping # ! の使用を警告
  - implicitly_unwrapped_optional
  - weak_delegate

  # テスト関連
  - quick_discouraged_call
  - single_test_class

# カスタムルール
custom_rules:
  no_print:
    name: "Print文の使用禁止"
    regex: '\bprint\('
    message: "Use Logger instead of print()"
    severity: warning

  todo_fixme:
    name: "TODO/FIXMEにチケット番号必須"
    regex: '(//|#|\\*)\s*(TODO|FIXME)(?!.*#\d+)'
    message: "TODOとFIXMEにはチケット番号を含めてください"

# 設定値
line_length:
  warning: 120
  error: 200
  ignores_comments: true

file_length:
  warning: 400
  error: 600

type_body_length:
  warning: 300
  error: 500

function_body_length:
  warning: 40
  error: 60

cyclomatic_complexity:
  warning: 10
  error: 20
```

#### GitHub Branch Protection Rules

main ブランチの保護設定:

✅ 必須設定:

- Require a pull request before merging

  - Required approvals: 1 以上
  - Dismiss stale PR approvals when new commits

- Require status checks to pass

  - Required checks:
    - build-and-test
    - swiftlint
    - test-coverage (80%以上)
  - Require branches to be up to date

- Require conversation resolution
- Require linear history (rebase を強制)

⭐ 推奨設定:

- Include administrators (管理者も例外なし)
- Restrict who can push (特定メンバーのみ)

🔧 開発効率のための設定:

- Allow auto-merge (CI 通過後自動マージ)
- Automatically delete head branches

## テスト駆動仕様

I'll search for the latest best practices for Swift/SwiftUI testing and TDD approaches for macOS app development.

Based on my research, here's a concise prompt for Claude Code to implement TDD best practices for Swift/SwiftUI macOS app development:

Create a Swift/SwiftUI macOS app with TDD approach following these requirements:

### Architecture

- MVVM with protocol-based dependency injection

- ViewModels as @Observable (Swift 5.9+) or ObservableObject

- Repository pattern for data layer

- Separate protocols for all dependencies (networking, persistence, utilities)

### Testing Structure

- Organize tests mirroring source: Features/FeatureName/Tests/

- Use XCTest with async/await support

- Follow AAA pattern (Arrange-Act-Assert)

- Test naming: test_methodName_expectedBehavior_whenCondition()

### TDD Workflow

1. Write failing test first
2. Implement minimal code to pass
3. Refactor with confidence
4. Each commit should have test + implementation

### Key Components to Include

- Protocol-based NetworkService with URLSession implementation

- Mock/Stub implementations for testing

- ViewModel with @Published properties

- Repository with async throws methods

- Error handling with custom domain errors

- Deterministic time/scheduler abstractions

### Testing Requirements

- Unit tests for ViewModels (business logic)

- Integration tests for Repository + Network

- Use TestScheduler for Combine, TestClock for async

- No sleep(), use XCTExpectation or async/await

- Mock external dependencies, test doubles for protocols

- Aim for 80%+ coverage on business logic

### Example Structure

```swift
// Protocol
protocol UserRepository {
  func fetchUser(id: String) async throws -> User
}

// ViewModel
@Observable
final class UserViewModel {
  private let repository: UserRepository
  @Published var user: User?
  @Published var isLoading = false

  init(repository: UserRepository) {
    self.repository = repository
  }

  func loadUser(id: String) async {
    isLoading = true
    do {
      user = try await repository.fetchUser(id: id)
    } catch {
      // handle error
    }
    isLoading = false
  }
}

// Test
final class UserViewModelTests: XCTestCase {
  func test_loadUser_setsUser_whenRepositorySucceeds() async {
    // Arrange
    let mockUser = User(id: "1", name: "Test")
    let mockRepository = MockUserRepository(userToReturn: mockUser)
    let sut = UserViewModel(repository: mockRepository)

    // Act
    await sut.loadUser(id: "1")
    // Assert
    XCTAssertEqual(sut.user, mockUser)
    XCTAssertFalse(sut.isLoading)
  }
}
```

#### **SwiftUI View Testing**

- Keep Views thin, test ViewModels instead
- Use ViewInspector for SwiftUI view testing if needed
- Environment injection for integration tests
- Snapshot tests for critical UI components

#### **Best Practices**

- One assertion per test preferred
- Test behavior, not implementation
- Use factory methods for test data
- Isolate tests (no shared state)
- Fast feedback loop (<100ms per unit test)
- CI runs: Unit → Integration → UI (smoke only)

This prompt provides Claude Code with specific, actionable instructions for implementing TDD in a Swift/SwiftUI macOS app while incorporating the latest best practices from the research.
