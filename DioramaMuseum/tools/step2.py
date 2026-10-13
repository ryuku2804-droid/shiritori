"""段階2のページの中身。make_source_page.py が読み込む。"""

from step1 import museum_map  # 平面図は段階1と同じ

STEP_LABEL = "STEP 2"
STEP_TITLE = "段階2:作品名のプレートと、E で鑑賞するモード"

# 貼る順に並べる。(Assets からのパス, 状態, 説明)
FILES = [
    ("Assets/NightShards/Museum/Shaders/MuseumText.shader", "新規",
     "キャプションの文字用のシェーダー。壁の向こうから透けて見えないようにしたもの"),
    ("Assets/NightShards/Museum/Scripts/CaptionText.cs", "新規",
     "キャプションの文字 (TextMesh) を置く道具。日本語の折り返しもここ"),
    ("Assets/NightShards/Museum/Scripts/ExhibitStand.cs", "新規",
     "展示1点分。台座・ジオラマ・キャプションのプレートを作り、鑑賞の中心と距離を持つ"),
    ("Assets/NightShards/Museum/Scripts/ExhibitViewer.cs", "新規",
     "鑑賞モード。近くの作品を探して「E で鑑賞」を出し、カメラを作品の周りで回す"),
    ("Assets/NightShards/Museum/Scripts/MuseumHUD.cs", "変更",
     "画面の下に操作の案内 (Hint) を出せるようにし、操作説明に「E で鑑賞」を足した"),
    ("Assets/NightShards/Museum/Scripts/MuseumBuilder.cs", "変更",
     "台座を ExhibitStand で作るようにし、プレイヤーに ExhibitViewer を付ける。ジオラマとキャプションの設定を追加"),
    ("Assets/NightShards/Museum/Editor/MuseumMenu.cs", "変更",
     "組み立てるとき、プロジェクトから Diorama.shader を探してマテリアルを作り、台座に置く"),
    ("Assets/NightShards/Museum/Shaders/MuseumSurface.shader", "そのまま", "壁・床・天井の質感 (URP 用)"),
    ("Assets/NightShards/Museum/Scripts/MuseumLayout.cs", "そのまま", "館の設計図"),
    ("Assets/NightShards/Museum/Scripts/MuseumMaterials.cs", "そのまま", "館のマテリアル7種"),
    ("Assets/NightShards/Museum/Scripts/MuseumGeometry.cs", "そのまま", "床・壁・天井を Cube で組む道具"),
    ("Assets/NightShards/Museum/Scripts/MuseumInput.cs", "そのまま", "キーとマウスの読み取り"),
    ("Assets/NightShards/Museum/Scripts/FirstPersonController.cs", "そのまま", "一人称で歩く"),
]

NOTICE = {
    "title": "ジオラマのコードについて",
    "body": [
        "既存の `Assets/NightShards/Diorama` のコードはまだ読めていないので、今回はジオラマの中身に頼らずに作れる部分 (キャプションと鑑賞モード) を進めました。",
        "ジオラマは、Tools で組み立てるときにプロジェクトから **Diorama.shader** を自動で探し、そのシェーダーでマテリアル (`Generated/Diorama.mat`) を作って台座に置きます。作品ごとの違いは `_Biome` (0〜3) で渡します。見つからなければ、バイオームの色を付けた仮の箱を置きます。",
        "`DioramaPiece` (グリッチ演出や steps の設定) はまだ使っていません。ジオラマが正しく描かれない・大きさが合わない・ピンク色になる、といったときは、6ファイルの中身を見せてもらえれば合わせます。",
    ],
}

OVERVIEW = ("各台座の手前に、美術館のキャプションのようなプレートを付けます (作品名・バイオーム・短い説明)。"
            "作品に近づいて見ると画面に「E で鑑賞」が出て、E を押すとカメラがなめらかに作品の前へ移ります。"
            "そこでは**ドラッグで 360° 回し、ホイールで寄ったり離れたり**できます。もう一度 E か Esc で、目の位置に戻って歩きを再開します。")

FLOW = [
    ("MuseumBuilder", "展示ごとに **ExhibitStand** を作って、台座・ジオラマ・キャプションを任せる。プレイヤーには **ExhibitViewer** を付ける"),
    ("ExhibitStand", "台座の上にジオラマ (または仮の箱) を置き、正面にプレートを付ける。**見る中心**と**見る距離**を覚えておく"),
    ("CaptionText", "プレートの文字を TextMesh で置く。文字は **MuseumText** シェーダーで描くので、壁の向こうからは見えない"),
    ("ExhibitViewer", "毎フレーム、近くて視線の先にある ExhibitStand を探す。見つかれば HUD に「E で鑑賞」を出す"),
    ("ExhibitViewer (鑑賞中)", "歩きを止め、カメラを目の位置から作品の周りへ**混ぜながら**動かす。ドラッグ・ホイールで回す・寄る"),
    ("MuseumHUD", "「E で鑑賞」(画面中央の下) と、鑑賞中の操作の案内 (画面の一番下) を出す"),
]

SEE = [
    "各台座の正面に、黒いプレートが少し上を向いて付いていて、作品名・バイオーム名・説明が白い文字で書かれている",
    "台座の上に、ジオラマ (Diorama.shader が見つかったとき) か、バイオームの色の仮の箱が載っている",
    "作品に近づいて見ると、画面中央の少し下に「E で鑑賞　作品名」と出る",
    "E を押すと、カメラが1秒ほどかけて作品の前へ移る。画面の一番下に操作の案内が出る",
    "ドラッグで作品の周りを 360° 回れる。ホイールで寄ったり離れたりできる",
    "もう一度 E か Esc を押すと、カメラが目の位置へなめらかに戻り、また歩ける",
]

PHASES = [
    {
        "title": "ファイルを入れる",
        "steps": [
            {
                "title": "シェーダーを1つ足す",
                "body": [
                    "`Shaders` フォルダで右クリック > **Create > Shader > Unlit Shader**。名前を `MuseumText` にする。",
                    "中身を全部消して、右の `MuseumText.shader` を貼って保存。",
                ],
                "ok": "シェーダーを選ぶと、Inspector の一番上に `NightShards/MuseumText` と出て、赤いエラーがない。",
            },
            {
                "title": "新しいスクリプトを3つ足す",
                "body": [
                    "`Scripts` フォルダで **Create > MonoBehaviour Script** を3回。名前は `CaptionText`、`ExhibitStand`、`ExhibitViewer`。",
                    "それぞれ中身を全部消して、右のコード台から同じ名前のファイルを貼って保存。",
                ],
                "ok": "3つのファイルが Scripts フォルダにある。",
            },
            {
                "title": "変更のあった3つを貼り直す",
                "body": [
                    "`MuseumHUD.cs`、`MuseumBuilder.cs`、`Editor/MuseumMenu.cs` を開き、中身を全部消して右の新しいものを貼る。",
                    "**そのまま** のファイルは触らなくてよい。",
                ],
                "ok": "Unity に戻ると、Console に赤いエラーがない。",
            },
        ],
    },
    {
        "title": "組み立て直す",
        "steps": [
            {
                "title": "Tools で組み立てる",
                "body": [
                    "**Tools > Diorama Museum > 美術館を組み立てる** を選ぶ。",
                    "Console に「[Museum] ジオラマのシェーダー「…」を見つけ、…/Diorama.mat を使います。」と出れば、既存のジオラマが台座に載る。「見つからないので、台座には仮の箱を置きます」と出たら、仮の箱になる。",
                ],
                "ok": "Scene ビューで、台座の正面にプレートが付き、上にジオラマか色の付いた箱が載っている。",
            },
            {
                "title": "キャプションを確かめる",
                "body": [
                    "Scene ビューでプレートに近づき、文字が左から右へ正しく読めるか (左右が反転していないか) を見る。",
                    "文字が大きすぎる・小さすぎるときは、`Museum` の Inspector の **Caption Text Scale** を変えて **組み立て直す**。",
                ],
                "ok": "作品名・バイオーム名・説明の3段が、プレートからはみ出さずに読める。",
            },
        ],
    },
    {
        "title": "再生して鑑賞する",
        "steps": [
            {
                "title": "鑑賞モードに入る",
                "body": [
                    "再生して、どれかの作品に近づき、作品を見る。",
                    "画面に「E で鑑賞」が出たら E を押す。",
                ],
                "ok": "カメラがなめらかに作品の前へ移り、カーソルが出て、画面の一番下に操作の案内が出る。",
            },
            {
                "title": "回す・寄る・戻る",
                "body": [
                    "左ボタンを押したままドラッグして、作品の周りを一周する。ホイールで寄ったり離れたりする。A/D・W/S のキーでも回せる。",
                    "E か Esc を押して戻る。",
                ],
                "ok": "目の位置へなめらかに戻り、カーソルが消えて、また WASD で歩ける。",
            },
        ],
    },
    {
        "title": "結果を送る",
        "steps": [
            {
                "title": "エラーと見た目を教える",
                "body": [
                    "Console の赤いエラー・黄色の警告は全文を貼ってください。",
                    "ジオラマの見た目 (ピンク色、大きさ、位置) やキャプションの読みやすさは、スクリーンショットがあると確実です。",
                    "そしてできれば、`Assets/NightShards/Diorama` の6ファイルの中身もお願いします。",
                ],
            },
        ],
    },
]

CHECKS = [
    "8つの台座すべてに、プレートとジオラマ (または仮の箱) がある",
    "プレートの文字が左右反転せず、プレートからはみ出していない",
    "プレートの文字が、壁の向こうから透けて見えない",
    "作品に近づいて見たときだけ「E で鑑賞」が出る。作品から目をそらすと消える",
    "E で鑑賞モードに入り、ドラッグで一周回れる。ホイールで寄れる",
    "E でも Esc でも鑑賞モードから戻れる。戻ったあと、Esc を押さなくても普通に見回せる",
    "鑑賞中は WASD で歩かない (A/D・W/S は作品を回す)",
]

TROUBLE = [
    ("[Museum] Diorama.shader が見つからないので、台座には仮の箱を置きます。",
     "プロジェクトに `Diorama.shader` という名前のファイルがない。ファイル名が違う場合は、そのシェーダーでマテリアルを作り、`Museum` の Inspector の **Diorama Material** に入れて組み立て直す。"),
    ("ジオラマがピンク色",
     "既存の Diorama.shader が URP で動いていない。6ファイルの中身を見せてもらえれば URP 用に直します。"),
    ("ジオラマが大きすぎる・小さすぎる・台座から浮いている",
     "`Museum` の **Diorama Size** を変えて組み立て直す。それでも合わないときは、Diorama.shader が想定している箱の大きさが違うので、中身を見せてください。"),
    ("キャプションの文字が □ になる・表示されない",
     "OS のフォントから日本語を補えていない。お使いの OS を教えてください。"),
    ("キャプションの文字が左右反転している",
     "向きの計算の間違い。スクリーンショットを送ってください。"),
    ("[Museum] シェーダー NightShards/MuseumText が見つかりません",
     "`MuseumText.shader` の1行目が `Shader \"NightShards/MuseumText\"` になっているか確認する。"),
    ("「E で鑑賞」が出ない",
     "作品から 3m 以内で、作品の中心を見ているか確認する。`Player` の **Exhibit Viewer** の Reach (距離) と Look Cone (向きのずれ) で調整できる。"),
    ("鑑賞モードでドラッグしても回らない",
     "左ボタンを押したまま動かしているか確認する。キーボードの A/D でも回るか試して、結果を教えてください。"),
]

NEXT = ("段階3では、部屋そのものをアートにします (月の間の水盤と月、火の間の溶岩のひび、夕の間の障子越しの光、海の間の水のゆらめき)。"
        "ジオラマのコードが届けば、あわせて距離による steps の調整と、画面に映っていないジオラマを止める工夫も入れます。")
