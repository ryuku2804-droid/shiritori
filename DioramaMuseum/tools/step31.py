"""段階31 (死海を軽くする) のページの中身。make_source_page.py が読み込む。"""

from step5 import museum_map  # 平面図は段階5と同じ

STEP_LABEL = "STEP 31"
STEP_TITLE = "段階31:死海を軽くする"

FILES = [
    ("Assets/NightShards/Museum/Shaders/DioramaDeadSea.shader", "変更",
     "軽くした: きのこの表の読み方・きのこの帯の外は調べない・水の底は影を省く・映り込みは低い角度だけ・影は近くだけ・平らな所は大きめの歩幅"),
    ("Assets/NightShards/Museum/Shaders/DioramaPyramids.shader", "そのまま",
     "スフィンクスを、送ってもらった漫画の絵のスフィンクスにした (橙色のセル塗り・黒い輪郭線・二重の丸い目・困ったまぶた・鼻・口・額の U・耳の C・指の線)"),
    ("Assets/NightShards/Museum/Scripts/DioramaTerrain.cs", "そのまま",
     "スフィンクスの当たり判定を、大きめの頭に合わせた"),
    ("Assets/NightShards/Museum/Scripts/DioramaWork.cs", "そのまま",
     "砂嵐の音と、塩の結晶が育つ音、部屋の照明を染める色を足した"),
    ("Assets/NightShards/Museum/Scripts/MuseumLayout.cs", "そのまま",
     "「ギザのピラミッド」を Pyramids、「死海」を DeadSea で描くようにし、説明文を新しくした"),
    ("Assets/NightShards/Museum/Shaders/DioramaParis.shader", "そのまま",
     "エッフェル塔と凱旋門だけを大きく (塔は 2.2 倍・門は 3 倍)。まわりはエトワール広場の石畳を回る車のライトと、シャン・ド・マルスの芝生"),
    ("Assets/NightShards/Museum/Shaders/DioramaPisa.shader", "そのまま",
     "斜塔だけを大きく (5.5 倍)。正面から見て右へ傾く。足元は大理石の敷石と芝生、鳩"),
    ("Assets/NightShards/Museum/Scripts/DioramaWorld.cs", "そのまま",
     "作品が決めた拡大の倍率で世界を作る (実物の寸法の作品は、もっと大きくして人の大きさに近づける)"),
    ("Assets/NightShards/Museum/Shaders/DioramaTorii.shader", "そのまま",
     "軽くした: 影は近くだけ細かく・遠くは山の高さの表で、参道の位置の計算を使い回し、霧の計算を半分に"),
    ("Assets/NightShards/Museum/Shaders/DioramaTerraces.shader", "そのまま",
     "つやのある質感・景色を映す水鏡と風のさざ波・夕もやと光の筋・かまどの煙・石垣"),
    ("Assets/NightShards/Museum/Shaders/DioramaDeepSea.shader", "そのまま",
     "水を透き通らせ、光の筋をやわらかく、粒を控えめに。崖の面をなめらかな岩の層に"),
    ("Assets/NightShards/Museum/Shaders/DioramaAtoll.shader", "そのまま",
     "水の屈折と色の吸収・3 重の波・砂の波紋と海草・くっきりした光の網目・白い砕け波・魚の影・砂浜の質感"),
    ("Assets/NightShards/Museum/Scripts/FirstPersonController.cs", "そのまま",
     "一歩ごとに速さが波打ち、視点が上下・左右に揺れる歩き。足元がすべりやすいと、つるつる滑る"),
    ("Assets/NightShards/Museum/Shaders/DioramaGlacier.shader", "そのまま",
     "作品「月下の氷河」。雪の峰・氷河とクレバス・青い氷の崖・月の光の道。仕掛けは氷河の崩落"),
    ("Assets/NightShards/Museum/Shaders/DioramaAurora.shader", "そのまま",
     "作品「オーロラの夜」。凍った湖・雪の森・オーロラのカーテン。仕掛けはオーロラ嵐"),
    ("Assets/NightShards/Museum/Shaders/DioramaBlueFire.shader", "そのまま",
     "同じ速くする仕組みを入れた"),
    ("Assets/NightShards/Museum/Shaders/DioramaEruption.shader", "そのまま",
     "地形の高さを表から読む・上へ抜ける線を早く打ち切る・当たった所だけ正確に合わせ直す"),
    ("Assets/NightShards/Museum/Shaders/MuseumArt.shader", "そのまま",
     "カメラのすぐ前を通る火の粉を消す (画面が白く点滅するのを直す)"),
    ("Assets/NightShards/Museum/Scripts/RoomReactor.cs", "そのまま",
     "仕掛けの最中、照明と床の光を作品の色 (青い炎なら青) に寄せる"),
    ("Assets/NightShards/Museum/Scripts/ExhibitStand.cs", "そのまま",
     "ジオラマの箱を台座から 2mm 浮かせた (台座が透けて見えるちらつきを直す)"),
    ("Assets/NightShards/Museum/Scripts/MuseumPost.cs", "そのまま",
     "鑑賞モードのぼかし (被写界深度) をやめた"),
    ("Assets/NightShards/Museum/Scripts/MuseumBuilder.cs", "そのまま",
     "プレイヤーに DioramaWorld を付ける"),
    ("Assets/NightShards/Museum/Scripts/ExhibitViewer.cs", "そのまま",
     "クリックでジオラマの世界に入る (歩いているときも鑑賞中も)。入る直前の吸い込みとリセット"),
    ("Assets/NightShards/Museum/Scripts/MuseumInput.cs", "そのまま",
     "左ボタンを離した瞬間 (クリックとドラッグを見分ける) を追加"),
    ("Assets/NightShards/Museum/Scripts/MuseumHUD.cs", "そのまま",
     "画面全体を白や黒で覆う「場面の切り替え」の表示を追加"),
    ("Assets/NightShards/Museum/Scripts/MuseumDome.cs", "そのまま",
     "ドームの形をメッシュで作る道具 (円の床・出入口つきの円い壁・半球の天井・光の柱)"),
    ("Assets/NightShards/Museum/Scripts/DioramaLOD.cs", "そのまま",
     "描く距離を 30m に広げた (ドームから通路の奥の作品が見えるように)"),
    ("Assets/NightShards/Museum/Editor/MuseumMenu.cs", "そのまま",
     "「設計図を初期設定に戻して組み立てる」を追加"),
    ("Assets/NightShards/Museum/Shaders/MuseumSurface.shader", "そのまま",
     "ドームの格天井 (種類 7) と、真鍮を象眼した方位盤の床 (種類 8) を追加"),
    ("Assets/NightShards/Museum/Scripts/MuseumMaterials.cs", "そのまま",
     "漆喰の壁・砂岩・大理石・ドームの床・格天井の5つを追加"),
    ("Assets/NightShards/Museum/Scripts/ShojiSun.cs", "そのまま",
     "部屋が回して置かれても、夕日が正しい向きから差すようにした"),
    ("Assets/NightShards/Museum/Scripts/PerfDebug.cs", "そのまま",
     "重さを調べる道具"),
    ("Assets/NightShards/Museum/Shaders/MuseumDiorama.shader", "そのまま",
     "ガラスケースのジオラマ"),
    ("Assets/NightShards/Museum/Scripts/RoomArt.cs", "そのまま",
     "板とアートのマテリアルを作る関数を、MuseumBuilder からも使えるようにした"),
    ("Assets/NightShards/Museum/Scripts/CaptionText.cs", "そのまま",
     "中央そろえの文字を置けるようにした (入口の上のサイン用)"),
    ("Assets/NightShards/Museum/Scripts/LightThreads.cs", "そのまま",
     "月の間の、天井から下がる光の糸のメッシュを作る"),
    ("Assets/NightShards/Museum/Shaders/MuseumText.shader", "そのまま",
     "キャプションの文字"),
    ("Assets/NightShards/Museum/Scripts/MuseumGeometry.cs", "そのまま",
     "床・壁・天井を Cube で組む道具"),
]

NOTICE = {
    "title": "1 つのファイルを貼り直すだけです",
    "body": [
        "右のタブで ● の付いた `DioramaDeadSea.shader` を、中身を全部置き換えてください。組み立て直しはいりません。",
    ],
}

OVERVIEW = ("死海を見ているときの FPS が 10 ほどに下がるのを直しました。見た目はほとんど変えずに、むだな計算を減らしています。"
            "**いちばん効くはずの直し**: 塩のきのこの場所の表 (9 個) を、ループの中で番号で読んでいました。GPU では、表を番号で読むと、表を遅いメモリに置くことがあり、これが画面のすべての点・すべての歩みで起きていました。"
            "ループを展開して ([unroll])、番号が決まった数になるようにしました。結晶のループも同じです。"
            "**むだを省く**: きのこが並ぶ帯の外では、きのこを 1 つも調べません。きのこの表面のぼこぼこ (ノイズ) は、すぐ近くだけで計算します。"
            "水の底 (水の中の地面) は、水ごしではほとんど見分けがつかないので、影と陰の計算を省きました。"
            "**水の映り込み**: 上を向いてはね返る線は空しか映らないので、たどるのをやめました。低い角度の線だけ、28 歩 (前は 48 歩) でたどり、映った物の向きは高さの表で安く測ります。"
            "**影**: 影の線は近く (0.3) までにして、歩みの数も最大 16 にしました。"
            "**歩幅**: なだらかな岸と水の底では大きめの歩幅で進み、急な山並みだけ小さめに進みます。当たったとみなす近さも、遠いほど少しゆるくしました。")

FLOW = [
    ("表と [unroll]", "static const の表を、ループの番号 i で読むと、GPU によっては一時的なメモリ (遅い) に置かれる。[unroll] でループを展開すると、i が 0, 1, 2... の決まった数になり、表はただの定数になる"),
    ("帯の外の早上がり", "きのこは z = -0.07〜0.25 の帯にしかないので、帯の外の点では、帯までの距離をすぐ返す"),
    ("水の底", "水面より下の点は、影 (16 歩) と陰 (4 回) を計算しない"),
    ("映り込み", "はね返った線が上向き (y > 0.3) なら空の色だけ。低い角度の線だけをたどる"),
]

SEE = [
    "死海の見た目は、ほとんど前と同じ",
    "FPS が上がっている (外から見たとき・中に入ったとき)",
]

PHASES = [
    {
        "title": "ファイルを入れる",
        "steps": [
            {
                "title": "1 つのファイルを貼り直す",
                "body": ["右のタブで ● の付いた `DioramaDeadSea.shader` を貼り直す。"],
                "ok": "シェーダーの Inspector にエラーがない。",
            },
        ],
    },
    {
        "title": "確かめる",
        "steps": [
            {
                "title": "FPS を見る",
                "body": ["死海を外から鑑賞したときと、中に入ったときの FPS (F1) を見る。仕掛け (Space) の最中も見る。"],
                "ok": "前 (10 くらい) より上がっている。",
            },
            {
                "title": "数字を送る",
                "body": ["外・中・仕掛けの最中の FPS を送ってください。まだ低ければ、次は水の映り込みや影を、さらに軽くする手があります。"],
            },
        ],
    },
]

CHECKS = [
    "死海の FPS が上がった",
    "見た目が前とほとんど同じ",
]

TROUBLE = [
    ("ジオラマがピンク",
     "Project でそのシェーダーを選ぶと、Inspector にエラーの行が出ます。その文を送ってください。"),
    ("まだ FPS が低い",
     "外から・中から・仕掛けの最中のどれで低いかと、その数字を送ってください。"),
]

NEXT = "FPS の数字を見て、まだ足りなければさらに軽くします。そのあと、アンデスの間 (ウユニ塩湖・マチュピチュ) に進みます。"
