# 70–210 mm 望遠ズームレンズデモ

`Docs/zoom_lens_simulink_spec.md`に基づく MATLAB / Simulink モデルです。MathWorks公式例の27面・13コンポーネントの処方をそのまま読み込み、C3–C4とC5–C12を剛体として移動します。C1–C2と像面C13（Z = 182.6223 mm）は固定します。

## 起動

MATLABでプロジェクトのルートフォルダをカレントフォルダにして実行します。

```matlab
addpath('Script');
paths = setupZoomProject;
app = main_zoom_demo;
```

`Script`フォルダをカレントフォルダにする場合は、`main_zoom_demo`だけで起動できます。起動・制御デモ・一括検証の各入口は、補助関数とモデルのパスを自動設定します。`setupZoomProject`はセッション内のMATLABパスとSimulink生成先を設定し、`savepath`による恒久設定は行いません。

## フォルダ構成

```text
zoomlens/
├─ Script/                     起動・実行用のMATLABファイル
│  ├─ main_zoom_demo.m          GUI起動
│  ├─ runZoomControlDemo.m      Simulink制御連携の実行
│  ├─ runZoomAcceptance.m       一括検証
│  ├─ setupZoomProject.m        パス・生成先設定
│  ├─ Functions/               補助関数・GUIクラス
│  │  └─ Official/             公式createPhotoZoomヘルパー
│  ├─ Examples/Official/       取得した公式例（参照用）
│  └─ Tests/                   自動テスト
├─ Model/                      Simulinkモデル
│  └─ Backup/                  整形前モデルの控え
├─ Results/                    図・動画・CSV・実行ログ
├─ Cache/                      最適化キャッシュ・Simulink生成物
├─ Docs/                       仕様書
│  └─ References/              公式ページ・出典情報
└─ README.md
```

モデル生成先は`Model`、解析結果は`Results`、最適化とSimulinkのキャッシュは`Cache`に固定しています。これらは実行時のカレントフォルダに依存しません。保存済みの過去の実行ログに含まれる絶対パスは、当時の記録として保持しています。

スライダーで70–210 mmの焦点距離を指令します。`Play / Stop`で往復再生、`Speed`で速度変更、`Save 12 s MP4`で動画保存ができます。画面には指令／実焦点距離、F値、gap1／gap2を表示します。通常再生は12秒で往復し、描画時間に応じてフレームが間引かれます。動画は別途、所定のフレーム数を計算して保存します。

```matlab
delete(app)                     % ウィンドウと再生タイマーを終了
open_system('ZoomActuatorControl.slx')
```

Simulinkモデルは、トップ階層・`Group1Servo`・`Group2Servo`の配置を整形済みです。主信号は左から右、飽和補償と位置フィードバックは下側に配置し、PI制御を青、アクチュエータを緑、制限を黄で表示しています。生成時にも同じ整形を適用します。既存モデルへ再適用する場合は次を実行します。

配線の分岐点と直角経路を明示し、ブロック内を横切る配線を防いでいます。共通の速度制限信号は、トップ階層のローカルGoto/Fromタグ`safe_close_v`で両軸へ渡します。同名タグは同一信号で、演算や遅延は追加しません。各群の位置フィードバックはサブシステム内に実線で表示します。保存後の再読込とモデル再生成でも同じ配線配置を確認済みです。

```matlab
formatZoomControlModel('ZoomActuatorControl');
save_system('ZoomActuatorControl');
```

階層別の画像は`Results/control_model.png`、`Results/group1_servo.png`、`Results/group2_servo.png`です。

## 必要製品

- MATLAB R2026b以降
- Image Processing Toolbox
- Optical Design and Simulation Library for Image Processing Toolbox
- Optimization Toolbox（ズーム軌跡の初回生成／再計算）
- Simulink（Phase 2のモデル生成／実行）

Parallel Computing Toolboxは不要です。MP4はWindows版MATLABの`VideoWriter(...,'MPEG-4')`を使用します。

## 一括再計算・検証

```matlab
trajectory = precomputeZoomTrajectory;             % キャッシュを再利用
trajectory = precomputeZoomTrajectory(Force=true); % 29点を再最適化
report = runZoomAcceptance;                        % 静止画・制御・テスト・UI・動画
```

外部ツール経由の実行でタイムアウトがある場合は、`[trajectory,complete] = precomputeZoomTrajectory(BatchSize=8)`を繰り返してください。各点の結果を`Cache/zoom_checkpoint.mat`へ保存し、次回は続きから計算します。全点の完了前は`trajectory=[]`、`complete=false`を返します。

個別実行も可能です。

```matlab
exportZoomSnapshots(trajectory);
controlResults = runZoomControlDemo(trajectory);
results = runtests(paths.Tests);
assertSuccess(results);
exportZoomAnimation(fullfile(paths.Results,'zoom_animation.mp4'), trajectory);
```

テストの制御成果物検査には、事前の`runZoomControlDemo`実行が必要です。全体の再実行は光線追跡と最適化のため数分以上かかります。最適化はUI再生中には行いません。

## 光学モデルと最適化

公式出典：<https://www.mathworks.com/help/images/optimize-photographic-zoom-lens-component-positions.html>

`Script/Functions/Official/createPhotoZoom.m`は`openExample('optics/OptimizePhotographicZoomLensComponentPositionsExample',...)`で取得した付属ファイルです。著作権表記を含めて変更せず保持しています。ガラスはヘルパー内の等価材料として定義され、外部Zemaxファイルや追加ガラスカタログには依存しません。取得ページは`Docs/References/`、公式例ソースは`Script/Examples/Official/`に保存しています。公式例ソースに埋め込まれた出力は本プロジェクトの検証結果ではありません。

- gap1はC2–C3、gap2はC4–C5の面頂点間距離です。単位はmmです。
- 公称モデルを毎回`copy`し、公式の`changeGap`で位置変更した後、像面を固定座標へ戻します。
- 70:5:210 mmの29点を`fmincon`で最適化します。
- 目的関数は`w × (実焦点距離−目標)^2 + (10 × RMSスポットサイズ)^2`です。通常はw=1、焦点距離誤差が0.25 mm以上残る場合はw=100で再計算し、重みもCSVへ記録します。公式例を参考に、滑らかな二乗残差へ変更しました。RMSはライブラリの`spot(...).RMS`値であり、表示上の拡大縮小はしません。
- 焦点距離と最適化用スポットは公称モデルの主波長558 nm、軸上で評価します。多波長・全画角の製造用レンズ最適化ではありません。
- 各点でソルバーの正常終了と焦点距離誤差0.25 mm未満を要求します。5 mm間隔の間は線形補間し、中間点も検証します。
- ギャップの下限と合計上限を課し、球面のサグを考慮した群境界の光学面クリアランスを0.05 mm確保します。鏡筒や保持機構の寸法は仕様書にないため含めません。
- `configureZoomSystem`は不正状態をエラーとして停止し、UIは警告を表示します。入力を黙って安全位置に置き換えることはしません。
- 描画更新では直前のチャートを削除し、光線や図がフレームごとに蓄積しないようにします。
- キャッシュにはヘルパー全文、MATLABバージョン、制約、スキーマ版を保存し、不一致時は再計算します。アルゴリズムを編集した場合は`Force=true`で再生成してください。

元の公式2配置は焦点距離が厳密に70／210 mmではありません。`Results/official_state_*.png`は元配置、`zoom_*mm.png`は今回の最適化後です。F/2.8–4は公式レンズの名称上の仕様であり、固定された公称絞りで算出される実F値は画面とCSVに別途記録します。

### 今回の測定結果と望遠端の制約

| 指令 | 実焦点距離 | 軸上スポットRMS | 実F値 | 近軸焦点の像面からのずれ |
|---|---:|---:|---:|---:|
| 70 mm | 70.003665 mm | 0.004155 mm | 2.891 | +0.133490 mm |
| 140 mm | 140.002785 mm | 0.001815 mm | 3.557 | +0.067778 mm |
| 210 mm | 209.988931 mm | 0.211711 mm | 4.259 | +2.440205 mm |

**210 mmでは画質が低下します。** gap2が下限の約0.05 mmに達するため、固定像面でのピントと210 mmへの追従を同時に満たせていません。焦点距離優先の再計算前は約209.100 mmに留まりました。この成果物はズーム運動と制御連携の検証モデルであり、全域で合焦する製品レンズの設計完成を意味しません。追加のフォーカス群移動や光学処方の再設計は今回の固定群条件の対象外です。

29点および2.5 mm刻みの中間点で、焦点距離誤差は最大0.140198 mmでした。これは焦点距離の誤差であり、画質や像面合焦の保証ではありません。

## Simulink位置制御

`Script/Functions/buildZoomControlModel.m`から実行可能な`Model/ZoomActuatorControl.slx`を生成します。モデルワークスペースにLookup Table、初期位置、指令、外乱を保持するので、保存済みモデルは単独で開いてシミュレーションできます。

2つの物理軸の位置を、C2の後面を基準として次のように定義しています。

| 信号 | 定義 |
|---|---|
| q1 / group1_actual | gap1 |
| q2 / group2_actual | gap1 + gap2（群1の固定厚さ分は座標原点に含む） |
| gap1_actual | q1 |
| gap2_actual | q2 − q1 |

第2群の位置をgap2だけで駆動すると、第1群の移動が反映されないため、Lookup Tableでq2へ変換してから制御しています。

- PIゲイン：Kp = 2、Ki = 12 /s、アンチワインドアップゲイン15 /s。
- プラント：`dq/dt = (u + disturbance − q) / tau`、tau = 0.12 / 0.18 s。
- 速度制限：両軸20 mm/s。指令と実位置にストローク制限を設けます。
- 群間のクリアランスが小さいときは、接近方向の速度を`10 × (gap2 − gap2下限)` mm/s以下にする相互インターロックを設けます。離れる方向は通常の20 mm/s制限です。これは連続状態の幾何制約を保つための制御上の保護であり、実ギャップの事後的な修正ではありません。
- ソルバー：固定刻み0.01 s、ode4。制御設計例であり、実アクチュエータの同定値ではありません。
- ステップ：2秒で70 → 210 mm。スイープ：12秒で70 → 210 → 70 mm。
- 外乱：7–7.5秒に第1軸+0.03 mm、第2軸−0.03 mm相当のプラント入力外乱。
- 全ソルバーサンプルの幾何制約を確認した後、0.1秒おきに実ギャップから光学系を再構成し、光線と焦点距離を計算します。
- グラフは指令／実ギャップ、ギャップ誤差、指令／実焦点距離、焦点距離誤差、固定像面からの近軸焦点ずれを表示します。補間による公称誤差とサーボ由来の誤差も分離します。

## 成果物

| ファイル | 内容 |
|---|---|
| `Cache/zoom_trajectory.mat` | 最適化した29点と計算条件 |
| `Results/zoom_trajectory.csv` | 各点の実焦点距離、ギャップ、RMS、収束情報 |
| `Results/representative_states.csv` | 70／140／210 mmの光学数値 |
| `Results/zoom_*mm.png`, `spot_*mm.png` | 代表状態の光線図・スポット図 |
| `Results/zoom_animation.mp4` | 12秒の往復ズーム動画 |
| `Results/zoom_animation_frames.csv` | 動画の各フレームの数値 |
| `Results/zoom_app.png` | 実行した操作画面 |
| `Model/ZoomActuatorControl.slx` | 2軸の位置制御モデル |
| `Results/*_simulink.mat` | ステップ／スイープの全ログ |
| `Results/*_optics.csv`, `*_control.png` | オフライン光学評価と比較グラフ |
| `Results/*_disturbance.png` | 外乱付近の位置／焦点距離誤差の拡大図 |
| `Results/control_model.png` | Simulinkブロック線図 |
| `Results/test_results.csv` | 自動テスト結果 |
| `Results/acceptance_report.mat` | 検証結果の集約 |

Phase 3のうちスポット評価を実装しています。PSF／MTF／eSFR画像合成は拡張項目として未実装です。PSFを画像へ変換する近似処理は含めていません。
