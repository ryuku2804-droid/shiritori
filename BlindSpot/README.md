# BLIND SPOT ステップ1:プレイヤー操作と足音・音の仕組み

このステップでは、次の3つを動かせるようにします。

- 一人称で歩く・走る・しゃがむ
- 床の素材によって足音の大きさが変わる
- 足音が「どこまで届いたか」を怪物 AI(ステップ2)が受け取れる

怪物はまだいません。プレイ中にシーンビューに出る**音の円の大きさ**を見て、「しゃがめば静か」「金属の床はうるさい」を確かめるところまでが今回のゴールです。

---

## 0. ファイル構成

```
BlindSpot/Assets/BlindSpot/
├─ Scripts/
│  ├─ Noise/
│  │  ├─ NoiseSystem.cs      … 音を発生させて配る仕組み (静的クラス)
│  │  └─ SurfaceMaterial.cs  … 床の素材を指定するコンポーネント
│  ├─ Player/
│  │  ├─ PlayerController.cs … 一人称操作 (歩く・走る・しゃがむ・視点)
│  │  └─ FootstepNoise.cs    … 足音を鳴らして NoiseSystem に知らせる
│  └─ Debug/
│     └─ DebugHud.cs         … 画面左上に状態を表示 (試作用)
└─ Editor/
   ├─ GrayboxRoomBuilder.cs  … Tools メニューから、レイアウトを読んでシーンを丸ごと作る
   └─ Stage/
      ├─ StageLayout.cs      … 「どこに何を置くか」のデータとヘルパー
      └─ PrototypeStage.cs   … テスト部屋の座標
```

---

## 1. Unity プロジェクトを用意する

1. **Unity Hub** → 「New project」
2. エディタのバージョンは **Unity 6**(6000.x)を選びます。
3. テンプレートは **「Universal 3D」**(URP)を選びます。
4. プロジェクト名(例:`BlindSpot`)を付けて「Create project」を押します。

### Input System の確認

Unity 6 の URP テンプレートには、最初から新しい Input System が入っています。念のため確認してください。

1. `Window > Package Manager` を開き、「In Project」に **Input System** があるか見ます。無ければ「Unity Registry」から Install します。
2. `Edit > Project Settings > Player > Other Settings` の **Active Input Handling** を **「Input System Package (New)」** か **「Both」** にします。変更すると再起動を求められるので、再起動します。

> テンプレートが用意する `InputSystem_Actions.inputactions` は使いません。入力はスクリプトの中で定義しているので、残しておいても問題ありません。

---

## 2. スクリプトをプロジェクトに入れる

1. GitHub のこのリポジトリを開き、ブランチを **`claude/new-session-t67fp1`** に切り替えます。
2. 緑の「Code」ボタン → **Download ZIP** でダウンロードして展開します。
3. 展開した中の **`BlindSpot/Assets/BlindSpot` フォルダ**を丸ごと、Unity プロジェクトの **`Assets` フォルダの中**へコピーします。
   - コピー後の場所は `(あなたのプロジェクト)/Assets/BlindSpot/Scripts/...` になります。
4. Unity に戻ると自動でコンパイルされます。**Console にエラー(赤)が出ていない**ことを確認してください。

---

## 3. テスト部屋を1クリックで作る

1. 上のメニューバーの **`Tools > BlindSpot > ステップ1: テスト部屋を作成`** をクリックします。
2. 新しいシーン `Assets/BlindSpot/Scenes/Prototype.unity` が作られ、部屋・プレイヤー・ライトが置かれて保存され、ビルド設定にも登録されます。

- 配置の座標は `Editor/Stage/PrototypeStage.cs` に書いてあります。数字を変えてメニューを押し直すと、シーンが作り直されます(手で置いたものは消えます)。
- 配置を変えたら、`python3 BlindSpot/tools/check_layout.py` で「スタートから全部の床に歩いて行けるか」「落ちる穴が無いか」を Unity を開かずに確かめられます(mono が必要)。

## 4. 遊んで確かめる

### 画面の配置

**Game ビューと Scene ビューを横に並べて**再生してください。タブをドラッグすると並べられます。Scene ビューで足音の円が見えます。

- Scene ビュー右上の **Gizmos ボタンが ON** になっていないと円が見えません。
- Game ビューの Gizmos も ON にすると、プレイ画面にも円が出ます。

### 操作

| キー | 動作 |
|---|---|
| WASD | 移動 |
| マウス | 視点 |
| 左 Shift(押しながら W) | 走る(前進中だけ) |
| 左 Ctrl または C(押している間) | しゃがむ |
| Esc | マウスカーソルを解放(クリックで戻る) |
| F1 | 左上の情報表示を ON/OFF |

ゲームパッドでも動きます(左スティック移動、右スティック視点、左スティック押し込みで走る、B/○ でしゃがむ)。

### 確認ポイント

- [ ] 歩くと水色の円(半径 約5m)が一定の間隔で出る
- [ ] しゃがむと円が小さくなる(約1.5m)。走ると大きくなる(約12m)
- [ ] 後ろ向き・横向きに Shift を押しても走らない
- [ ] 赤い床(カーペット)では円が半分に、青灰の床(金属)ではかなり大きくなる
- [ ] 低い通路にしゃがんで入り、通路の中で Ctrl を離しても**立ち上がらない**(頭上がふさがっているため)。出ると自動で立つ
- [ ] 左上の「最後の足音」の数値が、床と状態に応じて変わる

---

## 5. 仕組みの解説

### 音の流れ

```
FootstepNoise ──Emit(位置, 届く距離, 種類)──▶ NoiseSystem ──OnNoise──▶ 怪物AI (ステップ2)
                                                    └──▶ シーンビューに円を描く
```

- **NoiseSystem** は「音の放送局」です。音を出す側は `NoiseSystem.Emit(...)` を呼ぶだけで済みます。聞く側は `NoiseSystem.OnNoise += ...` で受け取ります。お互いを知らなくてよいので、投擲物・咳・番号錠などの音もあとから同じ方法で足せます。
- 音は **「位置」と「届く距離(半径)」** だけで表します。怪物が半径の内側にいれば「聞こえた」とします(`NoiseEvent.IsAudibleAt`)。実際の音量(AudioSource)とは分けてあるので、ゲームバランスは半径だけで調整できます。

### 足音の距離の計算

```
届く距離 = 移動状態の基本距離 × 床の素材倍率
```

| 移動状態 | 歩幅 (m) | 基本距離 (m) |
|---|---|---|
| しゃがみ | 0.5 | 1.5 |
| 歩き | 0.7 | 5 |
| 走り | 1.0 | 12 |

| 床 | 倍率 |
|---|---|
| Default | 1.0 |
| Carpet | 0.5 |
| Glass | 1.5 |
| Water | 1.3 |
| Metal | 1.8 |

- 足音は**時間ではなく歩いた距離**で鳴ります。そのため、ゆっくり動くほど足音の回数も減ります。
- 床の判定は足元から下向きのレイキャストで行います。当たったコライダー(またはその親)の `SurfaceMaterial` を見ます。付いていなければ Default です。

### 自分のマップの床に素材を付けるには

床のオブジェクト(コライダー付き)を選んで、`Add Component > SurfaceMaterial` を追加し、`Type` を選びます。

- 床ごとに倍率を変えたいとき:`Override Multiplier` を ON にして `Custom Multiplier` を設定します。
- 床ごとに足音の効果音を変えたいとき:`Footstep Clips` に音を入れます。

---

## 6. 調整できる値(Inspector)

### PlayerController

| 項目 | 意味 |
|---|---|
| Crouch / Walk / Run Speed | 各状態の移動速度 |
| Acceleration | 加減速の速さ。大きいほどキビキビ動く |
| Mouse Sensitivity | マウス感度 |
| Crouch Toggle | ON で「押すたびに切り替え」、OFF で「押している間だけ」 |
| Stand / Crouch Height | 立ち・しゃがみの身長 |
| Stand / Crouch Eye Height | 目の高さ |
| Obstacle Mask | 立ち上がれるかの判定に使うレイヤー(Player は外す) |

### FootstepNoise

| 項目 | 意味 |
|---|---|
| Crouch / Walk / Run | 歩幅(Stride)、基本距離(Base Radius)、効果音の音量 |
| Ground Mask | 床として調べるレイヤー(Player は外す) |
| Audio Source / Default Clips | 足音の効果音。空でも動きます |

### 足音の効果音を付けたいとき(任意)

無料の足音素材は、たとえば次のサイトで探せます。

- **freesound.org**:CC0 のものを選ぶとクレジット不要です。
- **OpenGameArt.org**
- Unity Asset Store の無料パック

使い方は次のとおりです。

1. wav / ogg を `Assets/BlindSpot/Audio/` などに入れます。
2. Player の `FootstepNoise > Default Clips` に数個ドラッグします。数個入れるとランダムに鳴ります。

---

## 7. うまくいかないとき

| 症状 | 原因と対処 |
|---|---|
| `The type or namespace name 'InputSystem' could not be found` | Input System パッケージが入っていません。手順1を確認してください |
| 再生しても動かない/マウスが効かない | Active Input Handling が「Input Manager (Old)」になっています。手順1を確認してください |
| Game ビューをクリックしないと視点が動かない | 仕様です。Game ビューをクリックするとカーソルがロックされます |
| 足音の円が見えない | Scene ビューの Gizmos を ON にしてください |
| 低い通路でしゃがみを離すと天井に埋まる | `Obstacle Mask` に天井のレイヤーが含まれているか確認してください |
| 床の素材が反映されない | 床に Collider があるか、`Ground Mask` にその床のレイヤーが含まれているか確認してください |
| 画面が真っ黒/真っ白 | シーンにライトがあるか確認してください(無ければメニュー実行時に自動で作られます) |
| 左上の日本語が表示されない | 試作用の表示なので、問題なければそのままで構いません |

---

## 8. 次のステップ

ステップ2は**怪物 AI(巡回 → 調査 → 追跡 → 捕獲)**です。仮モデルはカプセルで作ります。

- `NoiseSystem.OnNoise` を購読し、聞こえた音の場所へ NavMeshAgent で向かいます。
- 部屋が動いたら、「ステップ2をお願い」と伝えてください。
