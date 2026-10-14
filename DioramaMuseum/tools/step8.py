"""段階8 (大噴火を作り込む・見た目の不具合を直す) のページの中身。make_source_page.py が読み込む。"""

from step5 import museum_map  # 平面図は段階5と同じ

STEP_LABEL = "STEP 8"
STEP_TITLE = "段階8:溶岩・噴煙・噴石を立体に (と、ケースの不具合とぼやけを直す)"

# 貼る順に並べる。(Assets からのパス, 状態, 説明)
FILES = [
    ("Assets/NightShards/Museum/Shaders/DioramaEruption.shader", "変更",
     "厚みのある溶岩が流れ下って海で広がる・湯気の柱・傘のように広がる噴煙・球の噴石と光の尾。空の所は透明に"),
    ("Assets/NightShards/Museum/Scripts/ExhibitStand.cs", "変更",
     "ジオラマの箱を台座から 2mm 浮かせた (台座が透けて見えるちらつきを直す)"),
    ("Assets/NightShards/Museum/Scripts/MuseumPost.cs", "変更",
     "鑑賞モードのぼかし (被写界深度) をやめた"),
    ("Assets/NightShards/Museum/Scripts/DioramaTerrain.cs", "そのまま",
     "ジオラマの地形の高さを C# でも計算する (世界の中で歩く地面)"),
    ("Assets/NightShards/Museum/Scripts/DioramaWorld.cs", "そのまま",
     "ジオラマの世界に入る・出る"),
    ("Assets/NightShards/Museum/Scripts/DioramaWork.cs", "そのまま",
     "世界の中では音を場所に関係なく鳴らせるようにした"),
    ("Assets/NightShards/Museum/Scripts/MuseumBuilder.cs", "そのまま",
     "プレイヤーに DioramaWorld を付ける"),
    ("Assets/NightShards/Museum/Scripts/ExhibitViewer.cs", "そのまま",
     "クリックでジオラマの世界に入る (歩いているときも鑑賞中も)。入る直前の吸い込みとリセット"),
    ("Assets/NightShards/Museum/Scripts/MuseumInput.cs", "そのまま",
     "左ボタンを離した瞬間 (クリックとドラッグを見分ける) を追加"),
    ("Assets/NightShards/Museum/Scripts/MuseumHUD.cs", "そのまま",
     "画面全体を白や黒で覆う「場面の切り替え」の表示を追加"),
    ("Assets/NightShards/Museum/Scripts/RoomReactor.cs", "そのまま",
     "部屋とジオラマの連動"),
    ("Assets/NightShards/Museum/Scripts/MuseumLayout.cs", "そのまま",
     "作品ごとに専用シェーダーの名前 (work) を持てるようにし、「大噴火」を Eruption にした"),
    ("Assets/NightShards/Museum/Scripts/MuseumDome.cs", "そのまま",
     "ドームの形をメッシュで作る道具 (円の床・出入口つきの円い壁・半球の天井・光の柱)"),
    ("Assets/NightShards/Museum/Scripts/DioramaLOD.cs", "そのまま",
     "描く距離を 30m に広げた (ドームから通路の奥の作品が見えるように)"),
    ("Assets/NightShards/Museum/Editor/MuseumMenu.cs", "そのまま",
     "「設計図を初期設定に戻して組み立てる」を追加"),
    ("Assets/NightShards/Museum/Shaders/MuseumArt.shader", "そのまま",
     "天窓から見える夜空 (モード 5) と、天窓から落ちる光の柱 (モード 6) を追加"),
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
    "title": "貼り直すのは 3 つだけです",
    "body": [
        "シェーダー `DioramaEruption` と、スクリプト `ExhibitStand`・`MuseumPost` の 3 つ。貼ったら **Tools > Diorama Museum > 美術館を組み立てる** で組み立て直してください (台座の高さが変わるので、組み立て直しが必要です)。",
    ],
}

OVERVIEW = ("スクリーンショットの茶色い大きな板は、**ジオラマの中の空**でした。ケースの中の「何もない所」に夜空の色を塗っていたので、"
            "目の高さから見ると、地平線の赤い空が茶色い壁のように見えていました。外から見るときは空を透明にして、ガラスケースの向こうの部屋が見えるようにしました "
            "(中に入ったときは、今まで通り空を描きます)。ベージュの四角は、ケースの底と台座の上の面が同じ高さで**ちらついて台座が透けていた**もの。箱を 2mm 浮かせて直しました。"
            "E でぼやけるのは、鑑賞モードの被写界深度 (ぼかし) が、ジオラマの奥行きを正しく知らないためでした。ぼかしはやめました。"
            "そのうえで、大噴火を作り込みました: 溶岩は厚みのある流れになり、噴火が始まるとゆっくり山を下って海に入り、扇のように広がって湯気の柱が立ちます。"
            "噴煙は高く昇って、てっぺんで傘のように広がります。噴石は球になり、割れ目から赤く光りながら光の尾を引いて飛びます。")

FLOW = [
    ("Map (形)", "地面の上に、溶岩の流れを数 mm の厚みで盛る。海の上では水面に浮かぶ。表面のふくらみは、流れに乗ってゆっくり下る"),
    ("LavaAt (溶岩)", "流れ 3 本の向き・幅・先端の位置を計算。噴火してからの時間で先端が進み、約 6 秒で海に届き、海では扇のように広がる。先端は指のような舌に分かれる"),
    ("BombHit / BombTrails (噴石)", "噴石 22 個 (ふだんは 3 個) を放物線で飛ばし、線と球の交わりで当たりを調べる。少し前の位置をたどって光の尾を描く"),
    ("Plume (雲)", "噴煙 (火山灰) と湯気を、前から順に重ねる。噴煙は上で傘のように広がり、湯気は溶岩が海に入る所から立って風下へ流れる"),
    ("Frag (仕上げ)", "外から見て何にも当たらない線は透明にする。噴煙が濃い所だけ不透明になり、ケースの向こうの部屋が透けて見える"),
]

SEE = [
    "ケースの上の茶色い大きな板がなくなり、ガラスの向こうに部屋が見える",
    "台座のベージュがジオラマに透けて見えなくなる",
    "E で鑑賞しても、ジオラマがくっきり見える",
    "ふだん: 火口から短い溶岩の流れが 3 本。小さな噴石が、ときどき光の尾を引いて上がる",
    "Space で大噴火: 噴煙が昇って傘のように広がり、噴石がたくさん飛び、溶岩がゆっくり山を下って海に入り、白い湯気が立つ",
]

PHASES = [
    {
        "title": "ファイルを入れる",
        "steps": [
            {
                "title": "変更のあった 3 つを貼り直す",
                "body": ["右のタブで ● の付いたもの (シェーダー 1 つとスクリプト 2 つ) を貼り直す。"],
                "ok": "Console に赤いエラーがない。シェーダーのエラーは、DioramaEruption を選んだ Inspector にも出る。",
            },
            {
                "title": "組み立て直す",
                "body": ["**Tools > Diorama Museum > 美術館を組み立てる** を選ぶ。"],
                "ok": "エラーなく組み上がる。",
            },
        ],
    },
    {
        "title": "見る",
        "steps": [
            {
                "title": "前と同じ場所から見る",
                "body": ["火の間の「大噴火」を、前のスクリーンショットと同じくらいの近さ・高さから見る。"],
                "ok": "茶色い板とベージュの四角がない。ケースの中の空の所から、奥の部屋が見える。",
            },
            {
                "title": "鑑賞して、大噴火させる",
                "body": [
                    "E で鑑賞し、Space で大噴火させて、15 秒ほど見る。ドラッグでいろいろな向きから見る。",
                ],
                "ok": "ぼやけない。溶岩が海まで届いて広がり、湯気が立つ。噴煙が上で広がる。噴石が球として飛ぶ。",
            },
            {
                "title": "中に入って見る",
                "body": ["クリックで中に入り、クリックで大噴火させる。"],
                "ok": "溶岩の流れに厚みがあり、頭の上を噴石が飛んでいく。",
            },
            {
                "title": "スクリーンショットを送る",
                "body": ["外から (ふだん・大噴火の最中) と、中から (大噴火の最中) のスクリーンショットと、それぞれの FPS (F1) を送ってください。"],
            },
        ],
    },
]

CHECKS = [
    "ケースの上に茶色い板が出ない。空の所が透けて、部屋が見える",
    "台座がジオラマに透けて見えない",
    "E で鑑賞しても、ぼやけない",
    "大噴火で、溶岩がゆっくり山を下って海に入り、扇のように広がる",
    "溶岩が海に入る所から、白い湯気の柱が立つ",
    "噴煙が高く昇り、上で傘のように広がる",
    "噴石が球として飛び、光の尾を引く",
]

TROUBLE = [
    ("ジオラマがピンク (シェーダーのエラー)",
     "Project で DioramaEruption.shader を選ぶと、Inspector にエラーの行が出ます。その文を送ってください。"),
    ("ケースが真っ黒・何も見えない",
     "スクリーンショットを送ってください。透明にする計算か、重ねる順番の問題です。"),
    ("まだ台座がちらついて透ける",
     "組み立て直したか確認してください (箱の高さは組み立てるときに決まります)。"),
    ("とても重くなった",
     "溶岩と噴石の計算が増えたので、少し重くなります。FPS を前と比べて送ってください (あとの軽量化でまとめて直します)。"),
]

NEXT = ("スクリーンショットを見て、溶岩の太さ・明るさ、噴煙の広がり方、噴石の数を詰めます。大噴火が仕上がったら、同じ水準で残りの作品を 1 部屋ずつ作ります。")
