"""段階18 (一歩ずつの歩きと、氷の上の滑り) のページの中身。make_source_page.py が読み込む。"""

from step5 import museum_map  # 平面図は段階5と同じ

STEP_LABEL = "STEP 18"
STEP_TITLE = "段階18:一歩ずつ歩く感じと、氷の上でつるつる滑る"

# 貼る順に並べる。(Assets からのパス, 状態, 説明)
FILES = [
    ("Assets/NightShards/Museum/Scripts/DioramaTerrain.cs", "変更",
     "どこが氷の上か (凍った湖・氷河の上) を答えられるようにした"),
    ("Assets/NightShards/Museum/Scripts/DioramaWorld.cs", "変更",
     "世界の中で、氷の上だけすべりやすくする。美術館に戻ったら元に戻す"),
    ("Assets/NightShards/Museum/Scripts/FirstPersonController.cs", "変更",
     "一歩ごとに速さが波打ち、視点が上下・左右に揺れる歩き。足元がすべりやすいと、つるつる滑る"),
    ("Assets/NightShards/Museum/Shaders/DioramaGlacier.shader", "そのまま",
     "作品「月下の氷河」。雪の峰・氷河とクレバス・青い氷の崖・月の光の道。仕掛けは氷河の崩落"),
    ("Assets/NightShards/Museum/Shaders/DioramaAurora.shader", "そのまま",
     "作品「オーロラの夜」。凍った湖・雪の森・オーロラのカーテン。仕掛けはオーロラ嵐"),
    ("Assets/NightShards/Museum/Scripts/DioramaWork.cs", "そのまま",
     "氷河が崩れる音・オーロラの音と、部屋の照明を染める色を足した"),
    ("Assets/NightShards/Museum/Scripts/MuseumLayout.cs", "そのまま",
     "「月下の氷河」を Glacier、「オーロラの夜」を Aurora で描くようにした"),
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
    "title": "貼り直すのはスクリプト 3 つだけです",
    "body": ["`FirstPersonController`・`DioramaTerrain`・`DioramaWorld`。組み立て直しは要りません。"],
}

OVERVIEW = ("**一歩ずつの歩き**: これまでは同じ速さで滑るように進んでいました。今回から、進んだ距離と一歩の長さ (歩き 0.75m・走り 1.1m) から「いま何歩目のどのあたりか」を数え、"
            "地面をけった直後は少し速く、足を運ぶ間は少し遅く進むようにしました (平均の速さは今まで通り)。視点も一歩ごとに上下し (足をついた瞬間がいちばん低い)、"
            "右足・左足で左右にわずかに揺れて傾きます。走ると揺れが大きくなり、止まるとすっと収まります。"
            "**氷の上の滑り**: ジオラマの世界の中で、足元が氷の上 (オーロラの凍った湖・氷河の表面) のときだけ、すべりにくさを 0.08 に下げます。"
            "すると、歩き出しがゆっくりで、止まろうとしても止まれず、曲がろうとしても前へ流れていき、つるつる滑ります。足もうまく地面をけれないので、速さの波も小さくなります。")

FLOW = [
    ("FirstPersonController (歩き)", "一歩の進み具合 stepPhase を、実際の速さ ÷ 一歩の長さで進める。速さに「一歩ごとの波」を掛け、視点 (Camera Pivot) を上下・左右・傾きで揺らす"),
    ("DioramaTerrain (氷の場所)", "作品ごとに「そこは氷か」を答える式を持つ。オーロラは湖の面より低い所、氷河は氷河の表面が岩より高い所"),
    ("DioramaWorld (世界の中)", "入るとき、足元が氷ならすべりにくさ 0.08、それ以外は 1 を返す関数を、歩きのスクリプトに渡す。出るときに外す"),
    ("FirstPersonController (滑り)", "速さが目標に近づく速さに、すべりにくさを掛ける。氷の上では近づき方が 25 分の 1 くらいになり、止まれない・曲がれない"),
]

SEE = [
    "美術館を歩くと、一歩ごとに視点が上下・左右に揺れ、速さも一歩ごとに少し波打つ",
    "Shift で走ると、揺れが大きくなる。止まると揺れが収まる",
    "オーロラの世界で凍った湖に乗ると、つるつる滑って止まれない。岸に上がると、ふつうに歩ける",
    "氷河の世界で氷河の上に登ると、同じように滑る",
]

PHASES = [
    {
        "title": "入れて試す",
        "steps": [
            {
                "title": "3 つを貼り直す",
                "body": ["右のタブで ● の付いたスクリプト 3 つを貼り直す。"],
                "ok": "Console に赤いエラーがない。",
            },
            {
                "title": "歩いてみる",
                "body": ["再生して美術館を歩く。Shift で走る。"],
                "ok": "一歩ごとに視点が揺れ、速さが波打つ。酔うほど強くない。",
            },
            {
                "title": "氷の上で滑る",
                "body": ["「オーロラの夜」をクリックして中に入り、凍った湖の上を歩く。止まったり、曲がったりしてみる。"],
                "ok": "つるつる滑って、なかなか止まれない。岸に上がるとふつうに歩ける。",
            },
            {
                "title": "感想を送る",
                "body": ["揺れの大きさ・速さの波・氷の滑りやすさが、ちょうどいいか教えてください (強すぎ・弱すぎを数字で直せます)。"],
            },
        ],
    },
]

CHECKS = [
    "一歩ごとに視点が上下・左右に揺れる",
    "止まると揺れが収まる",
    "凍った湖の上で滑る",
    "美術館に戻ると、ふつうに歩ける (滑らない)",
]

TROUBLE = [
    ("揺れが強すぎる・酔う",
     "Player の FirstPersonController にある「視点の上下の揺れ」「左右の揺れ」「傾き」を小さくしてください (0 にすると揺れなくなります)。"),
    ("滑りすぎる・滑らなさすぎる",
     "Player の DioramaWorld にある「氷の上のすべりにくさ」を変えてください (0.08 から、大きいほど滑らない)。"),
    ("一歩の速さの波が気になる",
     "FirstPersonController の「一歩の中で、速さがどれだけ増えたり減ったりするか」を小さくしてください。"),
]

NEXT = "月の間のジオラマのスクリーンショットと FPS を見て、見た目を詰めます。そのあと、次の部屋に進みます。"
