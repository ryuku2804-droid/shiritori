# BLIND SPOT(Unity ホラーゲーム)

盲目で音に敏感な怪物から足音を殺して逃げる、一人称ステルスホラー。
終盤で怪物が実は見えていたと明かされ、隠れる手段が通じない全力逃走に切り替わる。

## 開発方針

- 一人開発、予算0円(無料素材・無料ツールのみ)
- Unity 6 / URP / 新しい Input System
- 公開:itch.io の PC ダウンロード版(WebGL はメインにしない)
- 進め方:作者は Unity 経験あり。スクリプトを用意し、エディタでの設定手順も日本語で説明する
- エディタ上の手作業は、可能な限りエディタ拡張(メニューから1クリックで組み立て)で自動化する
- コメントと説明は日本語

## 決定済みの仕様(要点)

### 主人公と物語
- 主人公:久世 透(仮名)、男性。研究所の元研究員で、怪物に視覚除去手術を行った担当者
- 閉鎖された研究所から謎の呼び出しを受けて戻る。呼び出したのは怪物自身
- 怪物の目的:自力では出られないため、出口を開けられる主人公(IDカード・生体認証)に道案内させていた
- 盲目は嘘、聴覚過敏は本物。大きな音を聞くと激痛で本能的に襲う → 音を立てると即死

### ゲームシステム
- 移動:しゃがみ / 歩き / 走り(走りは前進時のみ)
- 足音の届く距離 = 移動状態の基本距離 × 床の素材倍率(Default, Carpet, Glass, Water, Metal)
- 音の UI:画面下に控えめな波紋。オプションで非表示可
- 隠れる:物陰でじっとする / ベッド・机の下 / ロッカー・棚の中
- 息止め:長押しでゲージ消費。減る速さは心拍(怪物との距離)に連動。限界で咳き込み大きな音
- 投擲物:合計最大5個、拾って補充。石・コンクリ片(普通)/ ガラス瓶(割れて大きい)/ 空き缶(転がって続く)
- 追跡からの逃げ切り:隠れて音を消す(怪物は最後に音がした場所を探す)/ 投擲で別方向へそらす
- 謎解き:IDカードの権限レベル(Lv1→2→3→最上位)/ 番号錠(答えはメモに記載、押下音あり、誤入力でブザー)
- 捕まると即死(怪物の顔が迫る短いアニメ)→ 守衛室の端末で手動セーブした地点から再開
- 懐中電灯:バッテリー制

### 怪物
- 本命:人型、2.5〜3m、肌色に血。白く濁った瞳を正面に固定(演技)。上手すぎるクリック音。2章〜
- 失敗作:本命より小柄な人型、本当に盲目、不器用なクリック音。1〜3章
- AI:巡回 → 調査(音の場所へ)→ 追跡(大きな音・至近距離)→ 捕獲。見失うと最後の音の場所を調査
- 基本は AI、伏線・演出の場面だけ台本どおりに動かす
- 真相判明後:クリック音を出さない、隠れる・投擲が無効、懐中電灯の光を嫌がる

### 構成
- 1章 管理棟 / 2章 病棟 / 3章 実験区画 / 4章 地下・電源区画 / 5章 隔離棟 / ラストスパート(隔離棟→地上→屋外駐車場→車でキー連打して脱出)
- エンディング:トゥルー(脱出、怪物も外へ)/ 贖罪(伏線の日誌を全部集め、最後の扉を開けない)/ バッド(真相判明後に隠れ続ける)

## 開発の進め方(試作優先)

**品質の方針**:フェーズ A(ステップ1〜4、グレーボックスの試作)は手軽さ優先。**フェーズ B(ステップ5、1章)以降は最高品質の作り方**に切り替える。具体的には ScriptableObject で調整値を分離 / Input Actions アセットとリバインド / AI Navigation の NavMeshSurface を事前ベイク / Cinemachine / UI Toolkit / Audio Mixer / Assembly Definition と Unity Test Framework の自動テスト / バージョン付きセーブ / Profiler で性能目標。試作で作った仕組みもこの時点で置き換える(ロードマップの QUALITY 参照)

まずグレーボックスの1部屋で「足音を殺して怪物をやり過ごす」面白さを確認してから肉付けする。

1. [済] プレイヤー操作と足音・音の仕組み
2. [済] 怪物 AI(巡回・調査・追跡・捕獲)。仮モデルはカプセル
3. [ ] 隠れる・投擲・息止め
4. [ ] 実際に遊んで調整
5. [ ] 1章のマップ、照明、怪物モデル、謎解き、セーブ…と肉付け

## 既存のスクリプト(ステップ1)

場所:`BlindSpot/Assets/BlindSpot/`(Unity プロジェクトの `Assets/BlindSpot` にコピーして使う)。名前空間は `BlindSpot`。手順書は `BlindSpot/README.md`。


- `NoiseSystem.cs`:静的クラス。`NoiseSystem.Emit(位置, 届く距離, NoiseType)` で音を発生させ、`OnNoise` イベントで配る。プレイ中はシーンビューに範囲を円で表示
- `SurfaceMaterial.cs`:床に付けて素材(SurfaceType)を指定するコンポーネント
- `PlayerController.cs`:CharacterController ベースの一人称操作。`State`(Idle/Crouch/Walk/Run)、`InputEnabled` などを公開
- `FootstepNoise.cs`:歩いた距離ごとに足音を鳴らし NoiseSystem に通知。`OnStep` イベントあり
- `DebugHud.cs`:試作用の状態表示(F1 で切替)
- `Editor/GrayboxRoomBuilder.cs`:メニュー「Tools > BlindSpot > テスト部屋を作成」。StageLayout を読み、空の新規シーンに全部を生成・設定し、保存してビルド設定に登録する(何度押しても同じ結果)
- `Editor/Stage/StageLayout.cs`:配置データ(Placement のリスト)と、Room / Wall / Floor / Patch / Pillar / Crate / LowPassage などのヘルパー
- `Editor/Stage/PrototypeStage.cs`:テスト部屋のレイアウト。`static StageLayout Build()` と `ScenePath`

## ステージの作り方(Tools メニュー1クリックで丸ごと自動配置)

- 配置はすべて C# のレイアウトクラス(`Editor/Stage/〇〇Stage.cs` の `Build()`)に座標で書く。手でドラッグして置かない
- ビルダーは空シーンを作り、レイアウトをループして生成、プレイヤー・カメラ・ライトもコードで作り、保存・ビルド設定登録まで行う
- [SerializeField] の参照は SerializedObject 経由でセットする。オブジェクト同士の紐付けは名前(ビルダー内の `placed` 辞書)で行う
- レイアウトを変えたら `python3 BlindSpot/tools/check_layout.py [ステージのクラス名]` で検査する(mono の mcs が必要。無ければ `apt-get install -y mono-mcs`)。スタート地点が埋まっていないか、素材の床にたどり着けるか、落ちる穴が無いか、しゃがみが必要な場所を BFS で調べる
- 見た目が箱以外になったら、spec から OnEnable でメッシュとコライダーを作る [ExecuteAlways] 部品を検討する(今は CreatePrimitive の箱で足りている)
- プレイヤーは `Player` レイヤー、怪物は `Monster` レイヤー。床・天井判定のマスクから Player を外し、NavMesh の材料から Player と Monster を外す

## 怪物 AI(ステップ2)

- `Scripts/Monster/MonsterAI.cs`:状態 Patrol / Investigate / Chase / Caught。`NoiseSystem.OnNoise` を購読し、届く距離 10m 以上の大きな音か 3m 以内の音で追跡、それ以外は調査。追跡中は最後の音の位置へ向かい、2m 以内は気配で追う。4 秒音が無ければ最後の音の場所を調査。1.1m で捕獲 → 2.5 秒後にシーン再読み込み(本番の演出とセーブはステップ7)
- `Scripts/Monster/MonsterClicker.cs`:位置を知らせるクリック音(3D)。素材が無ければコードで音を作る。NoiseSystem には流さない
- `Scripts/Monster/RuntimeNavMesh.cs`:AI Navigation パッケージを使わず、Awake で NavMeshBuilder から NavMesh を作る([DefaultExecutionOrder(-1000)])。NavMeshAgent はビルダーで無効にしておき、MonsterAI.Start で有効にする
- 標準エージェント(高さ 2m)は天井 1.2m の低い通路に入れない = しゃがみ通路は安全地帯

## コードの渡し方

- **右のソースコード(Artifact)にはコードだけ**を出す。`python3 BlindSpot/tools/make_code_page.py <出力.html>` で作り、同じ URL(https://claude.ai/artifact/6Ek4AtZMgD4P7qAwoWXzAL)に上書き公開する。`FILES` の一覧と状態(新規 / 変更 / 変更なし)をステップごとに書き換える
- **手順・アタッチ先・Inspector の設定・解説はチャット**に書く。短く、わかりやすく
- 作者の目標は「書ける」より「コードを読んで、意味とこだわり(なぜそう書いたか)を自分で話せる」こと。ファイルごとに「役割 / 付ける場所 / こだわり(理由つき)」をチャットで伝える
- 変更したファイルは差分ではなく全文で渡す
- ファイルの配置は `.unitypackage` で一括で渡すのが基本。`python3 BlindSpot/tools/make_unitypackage.py BlindSpot/dist/BlindSpot_StepN.unitypackage` で作り、SendUserFile で送る。GUID はパスから決まるので、次のステップのパッケージは同じファイルを上書きする
- ロードマップは別の Artifact(https://claude.ai/artifact/22eYeWMwZR6LbSWtZNkH18、元ファイル `BlindSpot/docs/roadmap.html`)。ステップが終わるたびに「済 / 次 / 予定」を更新する
- **1行ずつの解説ページ**(別の Artifact、https://claude.ai/artifact/9HGLkmQPfHnUAV3iVCpVwg)は `python3 BlindSpot/tools/make_line_page.py <出力.html>` で作る。説明は `tools/annotations/<クラス名>.py` の NOTES = {行番号: 説明}。コードを変えたら行番号がずれるので、必ず作り直して、エラー(説明の無い行)が出ないことを確かめる。新しいファイルは FILES に追加する
- 以前の学習用ページの素材(`tools/lessons_step1.py`、`make_source_page.py`)は参考として残している
