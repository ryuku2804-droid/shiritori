# Void Cloak — Particleで構成するフード付き黒マントキャラクター（Unity URP）

参考画像のフード付き黒マントを、**数学的に定義した布面の上に大量のParticleをサンプリング**して再現するUnity用一式です。
ランダムに点を散らして形を作るのではなく、

```
シルエット → 3D断面 → 布面 → Major Fold → Secondary Fold → Edge → Micro Noise → Particle Sampling
```

の順で形状を作ります。

![preview](Docs/preview_front.png)

（上の画像はUnity外のオフラインプレビュー（`Tools/Preview`）で、シェーダーと同じライティング式を使ったもの。点サイズ0.02。）

---

## ファイル構成

| ファイル | 役割 |
|---|---|
| `Assets/VoidCloak/Scripts/VoidCloakCharacter.cs` | MonoBehaviour。Inspector、Mesh(`MeshTopology.Points`)生成、Material設定 |
| `Assets/VoidCloak/Scripts/VoidCloakGenerator.cs` | 各Particle群の生成関数（`GenerateHood()` 〜 `GenerateGroundWrinkles()`）とサーフェスサンプラー |
| `Assets/VoidCloak/Scripts/VoidCloakSurfaces.cs` | 布面の数式定義（フード殻・開口部・縁・Void・肩ケープ・ドレープ） |
| `Assets/VoidCloak/Scripts/VoidCloakMath.cs` | `FoldField`（シワの山と谷）、プロファイル曲線、乱数、ノイズ |
| `Assets/VoidCloak/Scripts/VoidCloakSettings.cs` | 形状パラメータ、Particle数、`CloakPart`、`BuildStage` |
| `Assets/VoidCloak/Shaders/VoidCloakPointShader.shader` | URP用シェーダー `VoidCloak/ClothPoint` |
| `Tools/Preview/` | Unity外で形状を確認するためのツール（Unityにはインポートしない） |

**役割分担:** 形状はC#、見た目・材質・描画・風はHLSL。

## セットアップ

1. `Assets/VoidCloak` フォルダをUnityプロジェクト（URP）の `Assets/` にコピー
2. 空のGameObjectを作成し `VoidCloakCharacter` を追加（MeshFilter / MeshRendererは自動で追加される）
3. Inspectorの **Character Shader** に `VoidCloakPointShader` をアサイン
   （またはこのシェーダーでMaterialを作って **Material Template** にアサイン）
   - `Shader.Find()` は何もアサインされていない時の最後のフォールバックとしてのみ使用
4. `[ExecuteAlways]` なので、Play前からScene Viewに表示される
5. 右クリックメニュー（コンテキストメニュー）の **Regenerate** で手動再生成も可能

## 段階的な制作（Build Stage）

Inspectorの **Build Stage** で、引き継ぎ資料の制作順どおりに確認できます。各段階はそれ以前の段階をすべて含みます。

| Stage | 内容 |
|---|---|
| Step01_HoodAndVoid | フード（Crown / Left / Right Shell）、開口部の縁、内部Void |
| Step02_Shoulders | 肩ケープ |
| Step03_OuterSilhouette | 外側マントの基本シルエット（シワなし） |
| Step04_MajorFolds | 大シワ ＋ シワの山と谷に沿った高密度Particle |
| Step05_FrontCloak | 中央前垂れ（CenterLeft / CenterRight）と内側の前布（FrontFold） |
| Step06_LowerDrape | 縦→斜め→地面へと流れが変わる下部 |
| Step07_GroundCloth | 地面に溜まる布（左右それぞれOuter/Middle/Inner）、地面の横シワ、裾の縁 |
| Step08_SecondaryFolds | 中シワ |
| Step09_MicroNoise | 最後に少量のMicro Noise |
| Complete | 全部 |

光沢（STEP 10）と風（STEP 11）はシェーダー側なので、常に有効です。

![stages](Docs/preview_stages.png)

構造の確認には **Debug Part Colors** をONにすると、Particle群ごとに色分けされます。

![parts](Docs/preview_parts.png)

## 形状の作り方（要点）

- **座標**: 足元 Y=0、正面 +Z、+X がキャラクターの右。4.2 units基準で作り、`Height` で全体をスケール。
- **フード**: 高さごとの水平楕円を積み重ねた布の殻。上部は `(1 - Q^2.2)^(1/crownSoftness)` の柔らかい山型（球ではない）。顔の開口部（上が丸く、側面は縦、下が少し尖る）は殻の**穴**として抜いており、顔パーツや黒い板は存在しない。
- **開口部の縁 (OpeningRim)**: 開口部の輪郭に沿った、巻いた布端のチューブ。内側を向いた面はVoidへ暗くなる。
- **InnerVoid**: 開口部の奥にある凹んだカップ状の面。シェーダーでほぼ黒（わずかな濃淡のみ）。布の裏側（`N·V < 0`）も暗くなるので、フード内部は奥行きのある黒になる。
- **肩**: 首から外側へほぼ水平に張り、端で落ちるケープ。厚みは他より大きい。
- **マント (DrapeSurface)**: 高さごとの楕円断面（幅・前後の厚みとも下へ行くほど増える。背中側の方が深い）。縦部分 → 円弧で曲がる下部 → 地面に寝た部分、が**1枚の連続した面**なので、縦シワがそのまま斜め、地面の放射状シワへと流れる。
- **シワ (FoldField)**: シワ1本ずつが「山の線」`u = c_i(t)` を持ち、山と山の間が谷になる断面（`cos` 位相＋谷位置のゆがみ）。間隔の不均一さ、振幅、途中から始まるシワ、下へ行くほどの横流れ（外側へ）、下部での斜め流れをシワごとに持たせている。左右は別の乱数列で作るので鏡像にならない。深さは局所的なシワ間隔に比例するので、上は細く浅く、下は太く深くなる。
- **中央前垂れ**: 外側マントより前（+Z）に出た2枚のパネル。中央で少し重なり、下端は斜めで左右で形が違う。後ろに内側の前布（FrontFold）がある。
- **地面**: 布束（左右それぞれOuter/Middle/Inner）で裾の到達距離と高さを変え、横・斜めのシワ（GroundWrinkles）を足している。最外周にHemEdge。
- **サンプリング**: 布面を格子に分けて実面積×密度ウェイトでCDFを作り、層化してParticleを配置（塊や穴ができない）。法線と流れ方向は折り目を含む最終形状から差分で求めるので、シワの山にハイライトが乗る。各Particleは Front / Front-Middle / Back-Middle / Back の4層の薄い厚みの中に置く。

## 頂点データ（C# → HLSL）

| チャンネル | 内容 |
|---|---|
| `POSITION` | 位置 |
| `NORMAL` | 布の法線 |
| `TANGENT` | xyz = 布の流れ方向（シワ方向）、w = 層 (-1 裏 〜 +1 表) |
| `COLOR` | r = Part ID / 32、g = 大シワ (0 谷 〜 1 山)、b = Void量、a = 乱数 |
| `TEXCOORD0` | x = サイズ倍率、y = 風の影響度 |
| `TEXCOORD1` | x = 中シワ、y = 焼き込みAO |

## シェーダー

- `MeshTopology.Points` の各点を**ジオメトリシェーダー**でカメラ向きの小さなQuadに展開し、布の流れ方向に少し伸ばしている。
- Quad内の座標は通常の `TEXCOORD` で渡すので、**`SV_PointCoord` は使っていない**（ps_4_0での `invalid ps_4_0 input semantic 'SV_PointCoord'` を回避）。
- `#pragma target 4.0` / `#pragma require geometry`。D3D11・Vulkan・OpenGL Coreで動作する想定。**MetalやWebGLはジオメトリシェーダー非対応**なので動かない（必要になったらC#側でQuad展開する方式を追加する）。
- 円形にクリップした不透明Particle（ZWrite On）にしているので、煙や霧のように透けない。
- ライティング: Fake Light（任意でURPのMain Lightとブレンド）、Wrap Diffuse、シワ方向に長いサテン調の異方性スペキュラー（Ward系）、山へのハイライト、谷の暗さ、Rim Light、布の裏側の暗さ、フード内のVoid。
- 風: 頂点シェーダーで、ゆっくりしたうねり＋突風＋小さな揺れ。肩やフードはほぼ固定、裾ほど動き、地面の布はあまり動かない。

## Inspectorの主なパラメータ

- **Particles**: Point Size, Point Variation, Flow Stretch
- **Wind**: Strength, Speed, Frequency, Direction, Flutter
- **Cloth Look**: Base / Sheen / Ambient色、Fake Light方向、スペキュラー、異方性、山のハイライト、谷の暗さ、Rim、Void色、布の裏側の明るさ、Debug Part Colors
- **Shape**: Height, Hood Width/Height/Depth、開口部サイズ、Crown Softness、Shoulder Width/Drop、Cloak Width / Hem Width / Depth、Hem Bend Height、Front Gap、Fold Count / Amplitude / Irregularity / Drift、Secondary Folds、Micro Noise、前垂れのシワ、Ground Spread / Train / Wrinkles / Bundles、厚み
- **Density**: 全体のMultiplier ＋ 群ごとのParticle数（既定で合計約11.5万）

## 確認状況と注意

- C#の形状生成部分は、Unityの型を置き換えるスタブを使って .NET 8 でビルド・実行し、`Tools/Preview` で描画して形状を確認済み（上の画像）。
- **Unity上（C# MonoBehaviour部分とHLSL）はこの環境ではコンパイル確認できていない。** URPのShaderLibrary関数（`TransformWorldToViewDir`, `GetWorldSpaceViewDir`, `GetMainLight` など）はURP 10以降を想定。
- 生成は約1秒（Release .NET）。Unity Editor（Mono）ではもう少しかかる。`Auto Regenerate` がONだと値を変えるたびに再生成されるので、重い時はOFFにして **Regenerate** を手動で実行する。
- プレビューは点サイズ0.02。Unityでは `Point Size` 0.012〜0.02付近で、密度Multiplierと合わせて調整する。

## オフラインプレビュー（任意）

```bash
cd Tools/Preview
dotnet run -c Release -- cloak.bin 10        # 第2引数 = Build Stage (1-10)、第3引数 = seed
python3 render_preview.py cloak.bin out.png  # --debug でPart色分け、--views 0,1.57 で視点指定
```

## 次の作業候補

- Unity上でシェーダーのコンパイルと見た目を確認し、Point Size・スペキュラーを調整
- 中央前垂れをもう少し目立たせる（オフセットとシワの深さ）
- 移動に合わせた形状変化（後ろへなびく）用のデータをC#から渡す
- Metal対応が必要ならC#でQuad展開するレンダリングモードを追加
