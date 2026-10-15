"""段階19 (海の間の 2 作品) のページの中身。make_source_page.py が読み込む。"""

from step5 import museum_map  # 平面図は段階5と同じ

STEP_LABEL = "STEP 19"
STEP_TITLE = "段階19:海の間「空に浮かぶ環礁」と「海の断面」"

# 貼る順に並べる。(Assets からのパス, 状態, 説明)
FILES = [
    ("Assets/NightShards/Museum/Shaders/DioramaAtoll.shader", "新規",
     "作品「環礁」。空に浮かぶ環礁・ヤシの小島・縁からこぼれる滝・雲。仕掛けは潮が引いて砂の道が現れる"),
    ("Assets/NightShards/Museum/Shaders/DioramaDeepSea.shader", "新規",
     "作品「海の断面」。珊瑚の浅瀬から深海までの水槽・魚の群れ・クラゲ。仕掛けは生物発光"),
    ("Assets/NightShards/Museum/Scripts/DioramaTerrain.cs", "変更",
     "環礁と海の断面の地形 (歩く地面と立つ場所) を足した"),
    ("Assets/NightShards/Museum/Scripts/DioramaWork.cs", "変更",
     "潮が引く音・深海の光の音と、部屋の照明を染める色を足した"),
    ("Assets/NightShards/Museum/Scripts/MuseumLayout.cs", "変更",
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
    "title": "シェーダーを 2 つ新しく作ります",
    "body": [
        "`Shaders` フォルダで右クリック → **Create > Shader > Unlit Shader** を 2 回。名前を `DioramaAtoll` と `DioramaDeepSea` にして、中身を全部置き換えてください。",
        "スクリプトは 3 つ貼り直し。キャプションの説明文も新しくなったので、**Tools > Diorama Museum > 設計図を初期設定に戻して組み立てる** で組み立ててください (ふつうの「組み立てる」でも作品は変わりますが、説明文は前のままです)。",
    ],
}

OVERVIEW = ("海の間の 2 作品です。どちらも昼の明るい海で、夜の作品が多い美術館の中で、ぱっと目を引きます。"
            "**環礁**: 丸い海のかけらが、ケースの中に浮かんでいます。下は岩が根のように細くなる土台。白い砂のサンゴ礁の輪の上に、ヤシの生えた小島が 5 つ。"
            "輪の内側は明るいターコイズの礁湖、外側は濃い青で、浅瀬の底には光の網目、水面には雲の影が流れます。島の縁の 4 か所からは、海の水が滝になって空中へこぼれ落ち、"
            "下で霧になって消えます。まわりには小さな雲。Space で**潮が引き**、白い砂の道 (サンゴ礁の輪) が小島と小島をつなぐように現れます。"
            "**海の断面**: ケースいっぱいの水槽です。左は色とりどりの珊瑚の棚、その先は切り立った崖で、右は深い海の底へ落ちていきます。"
            "水は上ほど明るい青、下ほど暗い紺で、水面から光の筋が差し込みます。浅瀬には銀色の魚の群れ、深いところにはほのかに光るクラゲとプランクトン。"
            "Space で**生物発光**: 真ん中から青い光の波が広がり、プランクトンもクラゲも魚も一斉に光って、深海の闇が輝きます。")

FLOW = [
    ("環礁の形 (Atoll)", "海の底の高さ (サンゴ礁の輪・小島・縁の堤) を高さの表で速く描き、その下に、下へ細る岩の土台をつける。水は、縁の内側の底から水面まで"),
    ("滝と雲 (Atoll)", "4 つの滝は、それぞれの向きにそろえた箱の中で、薄い水の幕を進みながら重ねる。下ほど広がって霧になる。雲は 6 つの平たいかたまり"),
    ("水槽 (DeepSea)", "地形 (珊瑚の棚と崖と深い底) に当たるまでの水の中を進み、にごりで後ろを隠しながら、深さの色・光の筋・プランクトンの光を足す"),
    ("生き物 (DeepSea)", "魚 36 匹は細長い小さな光、クラゲ 5 匹は光るかさと触手。水のにごりの分だけ弱めて足す"),
    ("仕掛け", "環礁: 水面を下げて、輪を出す。海の断面: 真ん中から広がる光の波 (GlowWave) で、すべてを光らせる"),
]

SEE = [
    "海の間に、浮かぶ環礁と、深海までの水槽が並ぶ",
    "環礁: ターコイズの礁湖とヤシの小島、縁からこぼれる滝、まわりの雲",
    "環礁で Space: 水が引いて、白い砂の輪が小島をつなぐ。滝が細くなる",
    "海の断面: 上は明るく下は暗い水、珊瑚、魚の群れ、光るクラゲ",
    "海の断面で Space: 青い光の波が広がり、深海が輝く",
    "クリックで中に入れる (環礁は小島の上。縁から外へ出ると空へ落ちて、小島に戻る。海の断面は水の中の珊瑚の棚の上)",
]

PHASES = [
    {
        "title": "ファイルを入れる",
        "steps": [
            {
                "title": "シェーダーを 2 つ作る",
                "body": [
                    "`Shaders` フォルダで右クリック → **Create > Shader > Unlit Shader**。名前を `DioramaAtoll` にして、中身を全部置き換える。",
                    "同じように `DioramaDeepSea` を作って、中身を置き換える。",
                ],
                "ok": "2 つのシェーダーの Inspector に、エラーが出ていない。",
            },
            {
                "title": "スクリプトを 3 つ貼り直す",
                "body": ["右のタブで ● の付いた `DioramaTerrain.cs`・`DioramaWork.cs`・`MuseumLayout.cs` を貼り直す。"],
                "ok": "Console に赤いエラーがない。",
            },
            {
                "title": "組み立て直す",
                "body": ["**Tools > Diorama Museum > 設計図を初期設定に戻して組み立てる** を選ぶ。"],
                "ok": "海の間の 2 つの台座が、新しいジオラマになっている。",
            },
        ],
    },
    {
        "title": "見る",
        "steps": [
            {
                "title": "環礁",
                "body": ["E で鑑賞して、横・下からも見る。Space で潮を引かせる。クリックで中に入り、小島から礁湖を歩く。"],
                "ok": "島が浮かんで見え、滝が下へこぼれる。潮が引くと砂の輪が出る。",
            },
            {
                "title": "海の断面",
                "body": ["E で鑑賞し、Space で生物発光を起こす。クリックで中に入り、崖の先へ歩いてみる。"],
                "ok": "水の色が深さで変わり、生き物が見える。Space で深海が青く輝く。",
            },
            {
                "title": "スクリーンショットと FPS を送る",
                "body": ["2 作品それぞれ、外から (ふだん・仕掛けの最中) と中からのスクリーンショットと、FPS (F1) を送ってください。"],
            },
        ],
    },
]

CHECKS = [
    "環礁が浮かんでいて、下から見ると岩の土台が見える",
    "環礁の滝がこぼれ落ち、Space で潮が引く",
    "海の断面の水が、上は明るく下は暗い",
    "海の断面で Space を押すと、生き物が一斉に光る",
    "どちらもクリックで中に入れる",
]

TROUBLE = [
    ("ジオラマがピンク",
     "Project でそのシェーダーを選ぶと、Inspector にエラーの行が出ます。その文を送ってください。"),
    ("環礁の水面がちらつく・縁がギザギザ",
     "スクリーンショットを送ってください。"),
    ("海の断面が真っ暗・真っ白",
     "水のにごりと明るさの調整が必要です。スクリーンショットを送ってください。"),
    ("中に入ったら、すぐ落ちる",
     "環礁の縁から外は空なので、落ちると小島に戻ります。小島の上で落ちるなら、教えてください。"),
]

NEXT = ("スクリーンショットを見て、2 作品の見た目を詰めます。そのあと、夕の間に進みます。")
