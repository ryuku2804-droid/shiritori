"""段階13 (2 作品目を「青い火の焦土」に作り直す) のページの中身。make_source_page.py が読み込む。"""

from step5 import museum_map  # 平面図は段階5と同じ

STEP_LABEL = "STEP 13"
STEP_TITLE = "段階13:2 作品目を「青い火の焦土」に作り直す"

# 貼る順に並べる。(Assets からのパス, 状態, 説明)
FILES = [
    ("Assets/NightShards/Museum/Shaders/DioramaBlueFire.shader", "変更",
     "作り直し: 青い炎に焼かれた焦土。青く光る割れ目・焼け残った木・青い炎と火の粉・地をはう煙。仕掛けは広がる炎の輪"),
    ("Assets/NightShards/Museum/Scripts/DioramaTerrain.cs", "変更",
     "焦土の地形に合わせて、歩く地面と立つ場所を直した"),
    ("Assets/NightShards/Museum/Scripts/MuseumLayout.cs", "変更",
     "作品名を「青い火の焦土」にし、説明文を変えた"),
    ("Assets/NightShards/Museum/Shaders/MuseumArt.shader", "そのまま",
     "カメラのすぐ前を通る火の粉を消す (画面が白く点滅するのを直す)"),
    ("Assets/NightShards/Museum/Scripts/DioramaWork.cs", "そのまま",
     "青い炎の音 (ガスが燃える音) と、部屋の照明を青に染める色を足した"),
    ("Assets/NightShards/Museum/Scripts/DioramaWorld.cs", "そのまま",
     "作品が決めた場所 (火口の縁) に立てるようにした"),
    ("Assets/NightShards/Museum/Scripts/RoomReactor.cs", "そのまま",
     "仕掛けの最中、照明と床の光を作品の色 (青い炎なら青) に寄せる"),
    ("Assets/NightShards/Museum/Shaders/DioramaEruption.shader", "そのまま",
     "厚みのある溶岩が流れ下って海で広がる・湯気の柱・傘のように広がる噴煙・球の噴石と光の尾。空の所は透明に"),
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
    "title": "今回は「設計図を初期設定に戻して組み立てる」で組み立ててください",
    "body": [
        "作品名が「青い火の焦土」に変わったので、ふつうの「組み立てる」だと、キャプションに前の名前と説明が残ります。",
        "**Tools > Diorama Museum > 設計図を初期設定に戻して組み立てる** を使うと、新しい名前と説明になります (MuseumBuilder の Inspector で自分で変えた設定は、初期設定に戻ります)。",
    ],
}

OVERVIEW = ("火の間の 2 作品目を、**青い炎に焼かれて黒く焦げた大地**に作り直しました。"
            "焼け野原にゆるやかな丘と干上がった川の跡。地面は黒い板のようにひび割れ、**割れ目の奥がまだ冷めない熱で青く光り**、"
            "ゆっくり息をするように明るさが変わります。板の真ん中には白っぽい灰。焼け残った黒い枯れ木の割れ目には、青い燠火がくすぶっています。"
            "あちこちで青い炎が燃え続け、青い火の粉が舞い上がり、地をはう煙が下から青く照らされます。"
            "Space で、**青い炎の輪が真ん中から大地いっぱいに燃え広がり**、輪が通った所は割れ目も木も強く燃え上がります。")

FLOW = [
    ("Height と Trees (形)", "焼け野原の地形 (丘 2 つと川の跡) と、ます目ごとにくじを引いて立てる枯れ木 (幹 1 本と枝 3 本)。地形の式は C# にも書き写して、中で歩く地面にする"),
    ("Cracks (ひび割れ)", "ボロノイという模様で、地面を大小の板に割る。割れ目までの距離が近いほど黒く、奥から青く光らせる"),
    ("Fires / Sparks (炎と火の粉)", "7 か所で、4 枚ずつの炎の舌がゆらめく。火の粉は炎から昇りながら、風下へ流されて消える"),
    ("Smoke (煙)", "地面すれすれの煙の層と、炎の上に立つ煙の柱。下のほうほど青く照らされる"),
    ("FrontFlames (仕掛け)", "真ん中から 7 秒かけて広がる炎の輪を、地面のすぐ上の薄い層を進んで描く。通った所は Burned が 1 になり、割れ目と木が強く光る"),
]

SEE = [
    "火の間の右の台座に、黒く焦げた夜の大地。地面の割れ目が網目のように青く光っている",
    "割れ目の明るさが、場所ごとにゆっくり強くなったり弱くなったりする",
    "焼け残った黒い枯れ木が立っていて、幹の割れ目が青くくすぶる",
    "あちこちで青い炎がゆらめき、青い火の粉が昇っていく。地面すれすれに煙が流れる",
    "Space で、真ん中から青い炎の輪が広がり、通った所が強く燃え上がる。部屋の照明も青くなる",
    "クリックで中に入ると、焼け野原の手前の端に立ち、奥へ広がる焦土を見渡す",
]

PHASES = [
    {
        "title": "ファイルを入れる",
        "steps": [
            {
                "title": "3 つを貼り直す",
                "body": ["右のタブで ● の付いた `DioramaBlueFire.shader`・`DioramaTerrain.cs`・`MuseumLayout.cs` を貼り直す (シェーダーは中身を全部置き換え)。"],
                "ok": "Console に赤いエラーがなく、シェーダーを選んだ Inspector にもエラーがない。",
            },
            {
                "title": "初期設定に戻して組み立てる",
                "body": ["**Tools > Diorama Museum > 設計図を初期設定に戻して組み立てる** を選ぶ。"],
                "ok": "火の間の右の台座が、焦げた大地のジオラマになり、キャプションが「青い火の焦土」になっている。",
            },
        ],
    },
    {
        "title": "見る",
        "steps": [
            {
                "title": "外から見る",
                "body": ["E で鑑賞し、いろいろな向きから、近づいたり離れたりして見る。"],
                "ok": "青く光る割れ目・枯れ木・青い炎・火の粉・煙が見える。",
            },
            {
                "title": "仕掛けを動かす",
                "body": ["Space を押して、15 秒ほど見る。"],
                "ok": "青い炎の輪が真ん中から広がり、通った所が強く光る。おさまると元に戻る。",
            },
            {
                "title": "中に入る",
                "body": ["クリックで中に入り、焼け野原を歩く。クリックで仕掛けを動かす。"],
                "ok": "足が地面に合っていて、炎の輪が自分のほうへ迫ってくる。",
            },
            {
                "title": "スクリーンショットを送る",
                "body": ["外から (ふだん・仕掛けの最中) と、中からのスクリーンショット、FPS (F1) を送ってください。"],
            },
        ],
    },
]

CHECKS = [
    "割れ目が青く光り、ゆっくり明るさが変わる",
    "枯れ木が立っていて、割れ目が青くくすぶる",
    "青い炎・火の粉・煙が見える",
    "Space で炎の輪が広がる",
    "中に入ると、焼け野原に立って歩ける",
]

TROUBLE = [
    ("ジオラマがピンク",
     "Project で DioramaBlueFire.shader を選ぶと、Inspector にエラーの行が出ます。その文を送ってください。"),
    ("キャプションが「青い火の火口湖」のまま",
     "ふつうの「組み立てる」を使うと、前の名前が残ります。「設計図を初期設定に戻して組み立てる」を使ってください。"),
    ("枯れ木が途中で切れて見える・ちらつく",
     "木を描く計算の細かさの問題です。スクリーンショットを送ってください。"),
    ("中で枯れ木にぶつからない",
     "枯れ木には当たり判定を付けていません (通り抜けられます)。ぶつかるようにしたければ言ってください。"),
]

NEXT = ("スクリーンショットを見て、割れ目の光り方・木の数・炎の量を詰めます。火の間が仕上がったら、次の部屋に進みます。")
