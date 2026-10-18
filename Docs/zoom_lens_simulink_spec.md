# 望遠ズームレンズの動作・レイトレース・制御連携デモ 仕様書
**対象:** MATLAB R2026b / Optical Design and Simulation Library / Simulink  
**目的:** AIエージェントに設計・実装・検証を依頼するための仕様

## 1. システム概要
70–210 mm望遠ズームレンズの2つの可動レンズ群を前後に移動させ、光学配置・レイトレース・焦点距離の変化を2Dアニメーションで表示する。次の段階でSimulinkの2軸位置制御と連携し、応答遅れや位置決め誤差が光学性能に与える影響を確認する。

## 2. 公式ベースモデル・依存関係
- 公式例: https://www.mathworks.com/help/images/optimize-photographic-zoom-lens-component-positions.html
- 70–210 mm、F/2.8–4の光学系。C1–C2:固定フォーカス群、C3–C4:可動群1、C5–C12:可動群2、C13:固定像面。
- `createPhotoZoom`は公式例の付属ヘルパー。付属ファイルの取得を初期タスクとする。
- 必須: MATLAB R2026b、Image Processing Toolbox、Optical Design and Simulation Library Add-On。
- Optimization Toolbox: `fmincon`による可動群位置の最適化時に必要。Simulink:制御連携時に必要。PCTは任意。

## 3. 要求機能
### Phase 1: MATLAB光学デモ（必須）
1. 公式例に付属の`createPhotoZoom`から`opticalSystem`を生成。
2. `gap1`: C2–C3間、`gap2`: C4–C5間。公式例と同じ`changeGap`を用いて変更。
3. 焦点距離70〜210 mmを5 mm刻みで指定し、公式例の`fmincon`を参考に`gap1`/`gap2`を求めて保存。補間によって中間状態も作る。
4. 各フレームで公称光学系のコピーを作成して群位置を更新し、C13像面を基準Z位置へ戻す。コンポーネントの重なり・負のギャップは禁止。
5. `paraxialInfo`で実焦点距離、`traceMarginalRays`または`traceRays`で光線、`view2d`+`addRays`で2D可視化。
6. UI: 焦点距離スライダー、再生/停止、速度、目標/実焦点距離表示、gap1/2表示、保存ボタン。
7. 10秒以上のアニメーションを実行し、MP4を書き出せること。
8. 代表状態（広角端・中間・望遠端）の静止画と数値を残す。

### Phase 2: Simulink位置制御（推奨）
1. 2つのレンズ群の位置制御モデルを`.slx`として作成。まずは一次遅れのアクチュエータ＋PI制御器、位置・速度制約。
2. 目標焦点距離をgap1/2目標軌跡へ変換（Lookup Table）。
3. ステップ入力とスイープ入力を用意。応答遅れ、外乱、位置決め誤差を評価。
4. 初期実装はオフライン連携：Simulinkで`gap1_actual`/`gap2_actual`をログに保存し、MATLABの各時刻に反映して光線を再計算。
5. 位置誤差と実焦点距離誤差の時系列グラフを表示。

### Phase 3: 画質評価（拡張）
1. `spot`で光線スポット評価。R2026bの`psf`/`mtf`で画質指標を取得。負荷対策として間引いて計算。
2. `psf`の結果`Image`を使う場合、物理寸法と画像ピクセルの換算・正規化を明示。表示のためにPSFを恣意的に圧縮しない。
3. `addImageSensor`と`renderChart`によるeSFR画像表示は、公式APIと必要条件を確認後にオプション実装する。

## 4. API・コーディング注意
- 公式例のコード例：
  `changeGap(opsys,2,gap1,GapLocation="after");`
  `changeGap(opsys,4,gap2,GapLocation="after");`
  `opsys.Components(end).Position(3)=fixedImagePlaneZ;`
- `createPhotoZoom`の依存資産を必ず確認し、未確認の関数・オブジェクトプロパティを仮定しない。
- `fmincon`の目的関数は焦点距離の残差＋RMSスポットのペナルティ、制約は可動範囲と非干渉。
- 高負荷の最適化はUI再生中に行わず、事前計算してMATファイルにキャッシュする。
- 描画を毎フレーム新規追加してメモリ増加しないよう、適切に更新する。

## 5. 成果物の構成例
- `main_zoom_demo.m`: デモ起動
- `loadZoomSystem.m`: モデル読込・依存チェック
- `precomputeZoomTrajectory.m`: 最適化とキャッシュ
- `configureZoomSystem.m`: 位置更新・像面固定
- `evaluateZoomState.m`: 焦点距離・光線・画質指標
- `ZoomDemoApp.m` または `.mlapp`: UI
- `ZoomActuatorControl.slx`: Simulinkの制御モデル
- `syncSimulinkOptics.m`: Simulinkログとの連携
- `tests/`: 幾何制約・焦点距離・再現性の自動テスト
- `README.md`: 実行手順・必要Add-On・既知の制約

## 6. 受入条件
- 公式光学系をロードし、光線付き2D表示ができる。
- ズーム指令に応じ2群が物理的に妥当な範囲で動き、焦点距離が追従する。
- C1–C2およびC13は固定され、可動群内の相対位置は保持。
- 負のギャップや干渉時は解析を停止して警告を表示。
- アニメーションとMP4保存が可能。
- Simulink制御連携で、指令/実位置/焦点距離誤差を時系列比較できる。
- 数値結果を捏造せず、公式例に基づいて検証ログを残す。

## 7. AIエージェントへの作業順序
1. 公式例を開き付属資産とAPIを確認。
2. Phase 1最小構成（2状態のレイトレース）を実行。
3. ズーム位置最適化と補間・制約チェックを実装。
4. GUIとMP4出力、テストを実装。
5. Phase 2のSimulink制御連携。
6. 時間があればPhase 3のPSF/MTF/eSFR評価を追加。
7. 動作ログ、スクリーンショット、ソース一式、READMEを提出。
