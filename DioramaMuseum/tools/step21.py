"""段階21 (海の断面の水を透き通らせ、崖をなめらかに) のページの中身。make_source_page.py が読み込む。"""

from step5 import museum_map  # 平面図は段階5と同じ

STEP_LABEL = "STEP 21"
STEP_TITLE = "段階21:海の断面の水を透き通らせ、崖をなめらかに"

# 貼る順に並べる。(Assets からのパス, 状態, 説明)
FILES = [
    ("Assets/NightShards/Museum/Shaders/DioramaDeepSea.shader", "変更",
     "水を透き通らせ、光の筋をやわらかく、粒を控えめに。崖の面をなめらかな岩の層に"),
    ("Assets/NightShards/Museum/Scripts/DioramaTerrain.cs", "変更",
     "崖の形を、シェーダーと同じなめらかな形に合わせた (中で歩く地面)"),
    ("Assets/NightShards/Museum/Shaders/DioramaAtoll.shader", "そのまま",
     "水の屈折と色の吸収・3 重の波・砂の波紋と海草・くっきりした光の網目・白い砕け波・魚の影・砂浜の質感"),
    ("Assets/NightShards/Museum/Scripts/DioramaWork.cs", "そのまま",
     "潮が引く音・深海の光の音と、部屋の照明を染める色を足した"),
    ("Assets/NightShards/Museum/Scripts/MuseumLayout.cs", "そのまま",
     "「環礁」を Atoll、「海の断面」を DeepSea で描くようにし、説明文を新しくした"),
    ("Assets/NightShards/Museum/Scripts/DioramaWorld.cs", "そのまま",
     "世界の中で、氷の上だけすべりやすくする。美術館に戻ったら元に戻す"),
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
    "title": "貼り直すのは 2 つだけです",
    "body": ["`DioramaDeepSea.shader` と `DioramaTerrain.cs`。組み立て直しは要りません。"],
}

OVERVIEW = ("**水**: 見る線にかかるにごりを半分以下にして、遠くまで透き通る、さらさらした水にしました。"
            "ただし、深いほど暗くなる光の届き方は、別の強さのまま残したので、深海はちゃんと暗いままです。"
            "光の筋は大きくやわらかい帯に、マリンスノーとプランクトンの粒は小さく少なくして、ざらつきをなくしました (プランクトンは、生物発光のときにだけ一斉に光ります)。"
            "**崖**: 面の細かいでこぼこを弱め、ゆるやかなうねりと、横に重なる岩の層の段にしました。色も、まだら模様から、層ごとに少しずつ色のちがう縞にしました。"
            "中で歩く地面も、新しい崖の形に合わせました。")

FLOW = [
    ("SIGMA と LIGHT_SIGMA", "見る線のにごり (SIGMA) と、日の光が深さで弱まる速さ (LIGHT_SIGMA) を分けた。前者を小さくすると透き通り、後者はそのままなので深海は暗い"),
    ("Water (水の中)", "光の筋のノイズを半分の細かさに、強弱をやわらかく。粒は小さく、数を減らした"),
    ("CliffX (崖の形)", "細かいでこぼこ (0.06) を、ゆるやかなうねり (0.016) と、横の層の段 (0.004) に"),
]

SEE = [
    "海の断面の水が透き通って見え、奥の生き物や崖まで見える",
    "水の中のざらざらした粒が目立たない",
    "崖の面が、なめらかな岩の層に見える",
]

PHASES = [
    {
        "title": "入れて見る",
        "steps": [
            {
                "title": "2 つを貼り直す",
                "body": ["右のタブで ● の付いた 2 つを貼り直す。"],
                "ok": "Console とシェーダーの Inspector にエラーがない。",
            },
            {
                "title": "見比べる",
                "body": ["海の断面を E で鑑賞し、水の透き通り方と、崖の面を見る。"],
                "ok": "水がさらっと透き通り、崖がなめらか。",
            },
            {
                "title": "感想を送る",
                "body": ["まだにごって見える・透き通りすぎ、崖がまだでこぼこ、など教えてください。数字で細かく直せます。"],
            },
        ],
    },
]

CHECKS = [
    "水が透き通って、奥まで見える",
    "深海はちゃんと暗い",
    "崖の面がなめらか",
]

TROUBLE = [
    ("透き通りすぎて海に見えない",
     "シェーダーの SIGMA を少し大きくすると、にごりが戻ります (いまは 1.5, 0.55, 0.36)。"),
    ("「ぼこぼこ」が崖のことではなかった",
     "どこがでこぼこに見えるか、スクリーンショットで教えてください (水面・珊瑚の棚・深い底など)。"),
]

NEXT = "見た目が決まったら、夕の間に進みます。"
