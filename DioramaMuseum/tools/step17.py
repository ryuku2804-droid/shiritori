"""段階17 (月の間の 2 作品) のページの中身。make_source_page.py が読み込む。"""

from step5 import museum_map  # 平面図は段階5と同じ

STEP_LABEL = "STEP 17"
STEP_TITLE = "段階17:月の間「月下の氷河」と「オーロラの夜」"

# 貼る順に並べる。(Assets からのパス, 状態, 説明)
FILES = [
    ("Assets/NightShards/Museum/Shaders/DioramaGlacier.shader", "新規",
     "作品「月下の氷河」。雪の峰・氷河とクレバス・青い氷の崖・月の光の道。仕掛けは氷河の崩落"),
    ("Assets/NightShards/Museum/Shaders/DioramaAurora.shader", "新規",
     "作品「オーロラの夜」。凍った湖・雪の森・オーロラのカーテン。仕掛けはオーロラ嵐"),
    ("Assets/NightShards/Museum/Scripts/DioramaTerrain.cs", "変更",
     "氷河とオーロラの地形 (歩く地面と立つ場所) を足した。シェーダーの表に焼く式を別に指定できるようにした"),
    ("Assets/NightShards/Museum/Scripts/DioramaWork.cs", "変更",
     "氷河が崩れる音・オーロラの音と、部屋の照明を染める色を足した"),
    ("Assets/NightShards/Museum/Scripts/MuseumLayout.cs", "変更",
     "「月下の氷河」を Glacier、「オーロラの夜」を Aurora で描くようにした"),
    ("Assets/NightShards/Museum/Shaders/DioramaBlueFire.shader", "そのまま",
     "同じ速くする仕組みを入れた"),
    ("Assets/NightShards/Museum/Shaders/DioramaEruption.shader", "そのまま",
     "地形の高さを表から読む・上へ抜ける線を早く打ち切る・当たった所だけ正確に合わせ直す"),
    ("Assets/NightShards/Museum/Shaders/MuseumArt.shader", "そのまま",
     "カメラのすぐ前を通る火の粉を消す (画面が白く点滅するのを直す)"),
    ("Assets/NightShards/Museum/Scripts/DioramaWorld.cs", "そのまま",
     "作品が決めた場所 (火口の縁) に立てるようにした"),
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
    ("Assets/NightShards/Museum/Scripts/FirstPersonController.cs", "そのまま",
     "一人称で歩く"),
]

NOTICE = {
    "title": "シェーダーを 2 つ新しく作ります",
    "body": [
        "`Shaders` フォルダで右クリック → **Create > Shader > Unlit Shader** を 2 回。名前を `DioramaGlacier` と `DioramaAurora` にして、中身を全部置き換えてください。",
        "スクリプトは 3 つ貼り直し。そのあと **Tools > Diorama Museum > 美術館を組み立てる** で組み立て直すと、月の間の 2 つの台座が新しい作品になります。",
    ],
}

OVERVIEW = ("月の間の 2 作品です。どちらも、大噴火や青い火の焦土と同じ仕組み (高さの表で速く描く・クリックで中に入れる・空は透明) で作りました。"
            "**月下の氷河**: するどい雪の峰に囲まれた谷を、青白い氷河が流れ下り、湖に面した青い氷の崖で終わります。"
            "氷河の表面には横向きの割れ目 (クレバス) が走り、その奥と崖の面が、月の光で青く透けます。湖には、奥の空の満月から手前へのびる一本の光の道。"
            "Space で**氷河の崖が崩れ**、氷の塊が倒れて湖に落ち、しぶきが上がって、波紋が湖いっぱいに広がり、氷山として浮かびます。"
            "**オーロラの夜**: 鏡のように凍った湖を、雪をかぶった針葉樹の森と雪山が囲みます。ケースの上のほうには、緑から紫へ色が変わる"
            "オーロラのカーテンが 3 枚、縦の光の筋を流しながら揺れ、凍った湖に映ります。Space で**オーロラ嵐**: カーテンが明るく速く大きく踊り、"
            "上に赤が混ざって、雪原と森が緑に照らされます。")

FLOW = [
    ("氷河 (Glacier)", "岩の山は高さの表で速く描き、氷河は式で描く (上の面と崖の面で囲んだ形)。クレバスは横向きの縞の溝。崩れるときは、崖から塊を切り取り、根元を軸に手前へ倒して湖に浮かべる"),
    ("湖 (Glacier)", "細かい波で月を映し、光の道をつくる。山と氷河を映し込む。仕掛けの最中は、落ちた所から波紋が広がる"),
    ("オーロラ (Aurora)", "ケースの上のほうの層を進みながら、3 枚のカーテンの光を足していく。すそはくっきり緑、上へ行くほど薄く紫。縦の筋と、横へ走る明るさの波"),
    ("凍った湖 (Aurora)", "鏡のようにオーロラと星空を映す。白いひびと雪だまり。雪だまりの所は映らない"),
    ("部屋 (RoomReactor)", "仕掛けの最中、氷河は青白く、オーロラは緑に、月の間の照明を染める"),
]

SEE = [
    "月の間に、雪の峰と氷河のジオラマと、オーロラのジオラマが並ぶ",
    "氷河: クレバスと崖が青く透け、湖に月の光の道がのびる",
    "氷河で Space: 崖が崩れて塊が湖に落ち、しぶきと波紋が広がる。ピシッ・ゴゴゴ・ザブンという音",
    "オーロラ: ケースの上のほうに緑と紫のカーテンが浮かび、凍った湖に映る",
    "オーロラで Space: カーテンが激しく踊り、赤が混ざり、雪原が緑に染まる。部屋も緑になる",
    "どちらもクリックで中に入れる (氷河は湖の岸、オーロラは森の手前の岸に立つ)",
]

PHASES = [
    {
        "title": "ファイルを入れる",
        "steps": [
            {
                "title": "シェーダーを 2 つ作る",
                "body": [
                    "`Shaders` フォルダで右クリック → **Create > Shader > Unlit Shader**。名前を `DioramaGlacier` にして、中身を全部置き換える。",
                    "もう一度同じように `DioramaAurora` を作って、中身を置き換える。",
                ],
                "ok": "2 つのシェーダーを選んだ Inspector に、エラーが出ていない。",
            },
            {
                "title": "スクリプトを 3 つ貼り直す",
                "body": ["右のタブで ● の付いた `DioramaTerrain.cs`・`DioramaWork.cs`・`MuseumLayout.cs` を貼り直す。"],
                "ok": "Console に赤いエラーがない。",
            },
            {
                "title": "組み立て直す",
                "body": ["**Tools > Diorama Museum > 美術館を組み立てる** を選ぶ。"],
                "ok": "月の間の 2 つの台座が、氷河とオーロラのジオラマになっている。",
            },
        ],
    },
    {
        "title": "見る",
        "steps": [
            {
                "title": "月下の氷河",
                "body": ["E で鑑賞していろいろな向きから見て、Space を押して 15 秒ほど見る。クリックで中に入って歩く。"],
                "ok": "氷河が崩れて湖に落ちる。中では湖の岸に立って、氷河と月を見上げる。",
            },
            {
                "title": "オーロラの夜",
                "body": ["同じように見て、Space でオーロラ嵐を起こす。クリックで中に入り、空を見上げる。"],
                "ok": "オーロラが踊り、湖に映る。中では頭の上にオーロラが広がる。",
            },
            {
                "title": "スクリーンショットと FPS を送る",
                "body": ["2 作品それぞれ、外から (ふだん・仕掛けの最中) と中からのスクリーンショットと、FPS (F1) を送ってください。"],
            },
        ],
    },
]

CHECKS = [
    "氷河: クレバスと青い崖、湖の月の光の道が見える",
    "氷河: Space で崖が崩れ、塊が湖に落ちて浮かぶ",
    "オーロラ: 緑と紫のカーテンが揺れ、凍った湖に映る",
    "オーロラ: Space で嵐になり、雪原が緑に染まる",
    "どちらもクリックで中に入れて、足が地面に合っている",
]

TROUBLE = [
    ("ジオラマがピンク",
     "Project でそのシェーダーを選ぶと、Inspector にエラーの行が出ます。その文を送ってください。"),
    ("台座が仮の箱のまま",
     "Console に「NightShards/Diorama/Glacier (または Aurora) が見つからない」と出ていないか見てください。シェーダーの 1 行目近くの名前を確認してください。"),
    ("オーロラがざらざら・点々に見える",
     "オーロラを描く細かさの問題です。スクリーンショットを送ってください。"),
    ("中で森の木にぶつからない",
     "木には当たり判定を付けていません (通り抜けられます)。"),
]

NEXT = ("スクリーンショットを見て、氷河とオーロラの見た目を詰めます。月の間が仕上がったら、次の部屋に進みます。")
