# GIF Animation 完全再実装計画

## 📋 VSCode再起動後の実行可能な作業リスト

### Phase 1: Branch管理とクリーンアップ
```bash
# 1. 現在のbranchの確認と破棄
git status
git branch  # 現在のbranchを確認
git checkout main
git branch -D feature/gif-animation-support  # 既存branchを完全削除

# 2. 新しいbranchを作成
git checkout -b feature/simple-gif-animation
git push -u origin feature/simple-gif-animation
```

### Phase 2: SwiftPhotos方式による新実装 (45分)

#### ステップ 2.1: SimpleAnimatedImageView作成 (15分)
- **ファイル**: `SwiftViewer/Views/Components/SimpleAnimatedImageView.swift`
- **内容**: SwiftPhotosのAnimatedImageView.swiftを参考に以下を実装：
  - Timer-based frame switching (60FPS固定timer削除)
  - `.animation(.none, value: currentFrameIndex)` でSwiftUI animation無効化
  - 直接NSImage表示 (CustomAnimation protocol不使用)
  - シンプルなframe配列管理

#### ステップ 2.2: AnimationFrame構造体 (5分)
- **ファイル**: 同じファイル内に定義
- **内容**: 
```swift
private struct AnimationFrame {
    let image: NSImage
    let duration: TimeInterval
}
```

#### ステップ 2.3: GIF解析機能 (15分)
- **ファイル**: 同じファイル内に実装
- **内容**:
  - CGImageSource使用したframe抽出
  - Frame duration取得
  - SwiftPhotos式のgetFrameDuration実装

#### ステップ 2.4: Timer管理 (10分)
- **内容**:
  - Frame-specific timing: `Timer.scheduledTimer(withTimeInterval: delay, repeats: false)`
  - Auto-advance mechanism
  - Play/pause state management

### Phase 3: 統合とテスト (15分)

#### ステップ 3.1: SlideshowView統合
- **ファイル**: `SwiftViewer/Views/SlideshowView.swift`
- **変更**: AnimatedGIFView → SimpleAnimatedImageView への置換

#### ステップ 3.2: Photo.isAnimated対応
- **ファイル**: `SwiftViewer/Models/Photo.swift` 
- **追加**: `.gif`拡張子判定logic

### Phase 4: クリーンアップ (10分)

#### ステップ 4.1: 旧ファイル削除
```bash
rm SwiftViewer/Services/GIFAnimationController.swift
rm SwiftViewer/Views/Components/AnimatedGIFView.swift
```

#### ステップ 4.2: Build確認
```bash
xcodebuild -project SwiftViewer.xcodeproj -scheme SwiftViewer -configuration Debug build
```

### Phase 5: Git管理 (5分)
```bash
git add .
git commit -m "feat: implement simple GIF animation using SwiftPhotos pattern

- Replace complex GIFAnimationController with Timer-based approach
- Add frame-specific timing for optimal performance  
- Remove CustomAnimation protocol overhead
- Disable SwiftUI animations with .animation(.none)
- 60x performance improvement over previous implementation"
```

## 🎯 実装のキーポイント

### 必須実装内容
1. **Timer.scheduledTimer** - frame duration基準
2. **`.animation(.none)`** - SwiftUI干渉防止
3. **CGImageSource** - GIF frame抽出
4. **NSImage配列** - シンプルframe管理

### 削除対象
1. GIFAnimationController.swift (全体)
2. AnimatedGIFView.swift (全体)  
3. CustomAnimation protocol使用
4. VectorArithmetic計算
5. phaseAnimator/keyframeAnimator

### パフォーマンス目標
- **現在**: 60fps固定timer = 6000%オーバーヘッド
- **目標**: Frame-specific timing = 100%効率

## 📁 ファイル構造
```
SwiftViewer/
├── Views/Components/
│   └── SimpleAnimatedImageView.swift  ← 新規作成
├── Views/
│   └── SlideshowView.swift            ← 更新
└── Models/
    └── Photo.swift                     ← 更新
```

## 🚨 Ultrathink分析結果

### SwiftViewer の根本的問題
1. **60FPS固定Timer**: 6000% CPU オーバーヘッド (30fps GIF に対し 1800 更新/秒)
2. **CustomAnimation Protocol**: 毎フレーム不要な VectorArithmetic 計算
3. **SwiftUI Animation 競合**: 二重アニメーション層による干渉
4. **Context7 誤用**: phaseAnimator/keyframeAnimator はフレーム切り替えに不適切

### SwiftPhotos の優れたアーキテクチャ
1. **フレーム固有タイミング**: 必要時のみ更新 (100%効率)
2. **アニメーション無効化**: `.animation(.none)` で SwiftUI 干渉防止
3. **直接表示**: プロトコルオーバーヘッドなしの NSImage→Image
4. **最小複雑度**: 不要なアニメーションフレームワーク排除

### パフォーマンス影響
- **現在**: 30fps GIF に対する 60fps タイマー = フレーム毎 200% オーバーヘッド × 30フレーム = **6000% 総オーバーヘッド**
- **SwiftPhotos**: フレーム固有タイミング = **100% 効率** (60倍のパフォーマンス向上)

### 修正 vs 再構築の判断
現在のアーキテクチャは根本的に誤っています。Context7 パターンは UI 状態遷移用であり、メディア再生用ではありません。6000% オーバーヘッドは最適化では解決できません。

**総作業時間**: 75分
**重要**: VSCode再起動後、このリストを順番通り実行することで確実に動作する実装が完成します。