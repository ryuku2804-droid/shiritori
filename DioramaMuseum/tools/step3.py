"""段階3のページの中身。make_source_page.py が読み込む。"""

from step1 import museum_map  # 平面図は段階1と同じ

STEP_LABEL = "STEP 3"
STEP_TITLE = "段階3:展示室そのものをアートにする"

# 貼る順に並べる。(Assets からのパス, 状態, 説明)
FILES = [
    ("Assets/NightShards/Museum/Shaders/MuseumSurface.shader", "変更",
     "黒曜石と溶岩のひび・水盤・水の光の3種類を追加。光の型紙 (クッキー) にも対応"),
    ("Assets/NightShards/Museum/Shaders/MuseumArt.shader", "新規",
     "自分で光るアート用。月の円盤・光の糸・夕日の透ける障子・火の粉"),
    ("Assets/NightShards/Museum/Scripts/MuseumMaterials.cs", "変更",
     "水盤・黒曜石・玄武岩の壁・水の光の壁と床の5つのマテリアルを追加"),
    ("Assets/NightShards/Museum/Scripts/LightThreads.cs", "新規",
     "月の間の、天井から下がる光の糸のメッシュを作る"),
    ("Assets/NightShards/Museum/Scripts/ShojiSun.cs", "新規",
     "夕の間の夕日。格子の型紙を作ってスポットライトに付け、日をゆっくり傾ける"),
    ("Assets/NightShards/Museum/Scripts/RoomArt.cs", "新規",
     "部屋ごとのアートを置く (月・光の糸・反射・溶岩の照り返し・火の粉・障子・夕日・海の光)"),
    ("Assets/NightShards/Museum/Scripts/MuseumBuilder.cs", "変更",
     "部屋のテーマで床・壁・天井を選び、RoomArt を呼ぶ。アートのライトにも Brightness が効く"),
    ("Assets/NightShards/Museum/Editor/MuseumMenu.cs", "変更",
     "MuseumArt シェーダーを MuseumBuilder の欄に入れる"),
    ("Assets/NightShards/Museum/Shaders/MuseumText.shader", "そのまま", "キャプションの文字"),
    ("Assets/NightShards/Museum/Scripts/CaptionText.cs", "そのまま", "キャプションの文字を置く道具"),
    ("Assets/NightShards/Museum/Scripts/ExhibitStand.cs", "そのまま", "展示1点分"),
    ("Assets/NightShards/Museum/Scripts/ExhibitViewer.cs", "そのまま", "鑑賞モード"),
    ("Assets/NightShards/Museum/Scripts/MuseumHUD.cs", "そのまま", "画面の表示"),
    ("Assets/NightShards/Museum/Scripts/MuseumLayout.cs", "そのまま", "館の設計図"),
    ("Assets/NightShards/Museum/Scripts/MuseumGeometry.cs", "そのまま", "床・壁・天井を Cube で組む道具"),
    ("Assets/NightShards/Museum/Scripts/MuseumInput.cs", "そのまま", "キーとマウスの読み取り"),
    ("Assets/NightShards/Museum/Scripts/FirstPersonController.cs", "そのまま", "一人称で歩く"),
]

NOTICE = {
    "title": "MuseumNoise.hlsl は不要になりました",
    "body": [
        "`MuseumNoise.hlsl` は Unity のメニューから作れないので、使わない形に変えました。作りかけていたら消してかまいません。",
        "新しく作るのは `MuseumArt` (**右クリック > Create > Shader > Unlit Shader**) だけです。`MuseumSurface.shader` と `MuseumArt.shader` は、右の最新のものを貼ってください (すでに貼っていても、もう一度貼り直してください)。",
    ],
}

OVERVIEW = ("4つの展示室を、それぞれのジオラマから生まれたインスタレーションにします。"
            "**月の間**は揺れる黒い水盤と、壁の大きな月、天井から下がる無数の光の糸。"
            "**火の間**は黒曜石の床を走る溶岩のひびと、舞い上がる火の粉。"
            "**夕の間**は奥の壁一面の障子に夕日が透け、格子の影が床にのびる。"
            "**海の間**は白い部屋の壁・天井・床に、水面の光がゆらゆら映る。"
            "どれも画像ファイルは使わず、シェーダーと C# で作っています。")

FLOW = [
    ("MuseumBuilder", "部屋のテーマ (Moon / Fire / Dusk / Sea) で床・壁・天井のマテリアルを選んで部屋を組み、**RoomArt** に部屋の寸法を渡す"),
    ("MuseumSurface", "床・壁の質感。水盤はさざ波で光の映り込みを揺らし、黒曜石はひびを光らせ、水の光の漆喰は網目の光を浮かべる"),
    ("RoomArt", "テーマごとに置くものを作る。月と障子は壁に貼った板、光の糸は LightThreads、夕日は ShojiSun、火の粉はパーティクル"),
    ("MuseumArt", "月・光の糸・障子・火の粉を描く。自分で光るので、Global Volume のブルームがあればにじんで見える"),
    ("LightThreads / ShojiSun", "光の糸のメッシュと、夕日の格子の型紙を作る。シーンを開き直したときも自動で作り直す"),
    ("MuseumBuilder", "アートのライトの明るさを覚えておき、Brightness をかける"),
]

SEE = [
    "月の間: 床がほぼ黒い水面になり、スポットライトの光がさざ波で揺れて映る。奥の壁に青白い大きな月。天井から光の糸が下がり、光の粒がゆっくり流れ落ちる",
    "月の間: 再生すると、水盤に月と光の糸がぼんやり映る (反射プローブ)",
    "火の間: 黒く光る床に橙のひびが走り、ひびごとにずれて脈打つ。壁の下のほうが赤く照らされ、火の粉が舞い上がる",
    "夕の間: 奥の壁が一面の障子になり、橙の夕日が透けている。床に格子の影が落ち、再生中は2分ほどで影がのびて、また縮む",
    "海の間: 壁・天井・床に、水の底のような光の網目がゆっくり揺れる",
    "Brightness を動かすと、アートのライトも一緒に明るさが変わる",
]

PHASES = [
    {
        "title": "ファイルを入れる",
        "steps": [
            {
                "title": "シェーダーを足す・貼り直す",
                "body": [
                    "`Shaders` フォルダを右クリック > **Create > Shader > Unlit Shader**。名前を `MuseumArt` にして、中身を右のものに置き換える。",
                    "`MuseumSurface.shader` は中身を右の新しいものに置き換える。",
                ],
                "ok": "`MuseumSurface` と `MuseumArt` を選ぶと、どちらも Inspector に赤いエラーがない。",
            },
            {
                "title": "新しいスクリプトを3つ足す",
                "body": [
                    "`Scripts` で **Create > MonoBehaviour Script** を3回。名前は `LightThreads`、`ShojiSun`、`RoomArt`。中身を右のものに置き換える。",
                ],
                "ok": "3つのファイルが Scripts フォルダにある。",
            },
            {
                "title": "変更のあった3つを貼り直す",
                "body": [
                    "`MuseumMaterials.cs`、`MuseumBuilder.cs`、`Editor/MuseumMenu.cs` の中身を、右の新しいものに置き換える。",
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
                    "Generated フォルダに、`Water`・`Obsidian`・`Basalt Wall`・`Caustic Wall`・`Caustic Floor` の5つのマテリアルが増える。",
                ],
                "ok": "Scene ビューで、月の間の奥の壁に月、夕の間の奥に障子が見える。各部屋の Hierarchy に `Art` がある。",
            },
            {
                "title": "Scene ビューで動きを見る",
                "body": [
                    "Scene ビュー上の **エフェクトのボタン** (山と太陽の形のアイコン) の ▼ から **Always Refresh** をオンにすると、溶岩の脈動や水の光の揺れが編集中も動いて見える。",
                ],
                "ok": "火の間のひびが脈打ち、海の間の光がゆっくり揺れている。",
            },
        ],
    },
    {
        "title": "再生して見て回る",
        "steps": [
            {
                "title": "4つの部屋を回る",
                "body": [
                    "再生して、ホールから4つの部屋を順に回る。夕の間では少し待って、格子の影がのびていくのを見る。",
                    "明るさが合わない部屋があれば、`Museum` の Brightness か、Generated のマテリアルの **Emission** (溶岩・水の光の強さ) を調整する。",
                ],
                "ok": "4つの部屋が、それぞれ違う光と質感の空間になっている。",
            },
        ],
    },
    {
        "title": "結果を送る",
        "steps": [
            {
                "title": "スクリーンショットとエラーを送る",
                "body": [
                    "Console の赤いエラー・黄色の警告は全文を貼ってください。",
                    "今回は見た目が中心なので、**4つの部屋のスクリーンショット**があると、明るさや色の調整をこちらで詰められます。",
                ],
            },
        ],
    },
]

CHECKS = [
    "月の間の床が水面のように見え、スポットライトの映り込みがゆっくり揺れる",
    "月の間の奥の壁に月があり、光の糸が天井から下がっている。糸は頭より上にあり、作品の真上にはない",
    "火の間の床のひびが光って脈打ち、火の粉が舞っている",
    "夕の間の床に格子の影が落ち、時間とともに形が変わる",
    "海の間の壁・天井・床に光の網目が揺れている",
    "どの部屋でも、キャプションと鑑賞モード (段階2) がそのまま使える",
    "Brightness を変えると、アートのライトも含めて明るさが変わる",
]

TROUBLE = [
    ("床や壁がピンク色 (段階3から)",
     "`MuseumSurface` を選んで Inspector のエラー文を見て、その文を貼ってください。"),
    ("[Museum] シェーダー NightShards/MuseumArt が見つかりません",
     "`MuseumArt.shader` の1行目が `Shader \"NightShards/MuseumArt\"` になっているか確認する。"),
    ("夕の間の床に格子の影が出ない",
     "URP のアセットで Light Cookies が切られている可能性。URP のアセット (Settings フォルダの PC_RPAsset など) の Lighting > Light Cookies を確認する。"),
    ("月の間の水盤に何も映らない",
     "反射は再生した瞬間に1回だけ撮るので、編集中は映らない。再生しても映らないときは、URP のアセットの Lighting > Reflection Probes 関係の設定を教えてください。"),
    ("火の粉が出ない",
     "Scene ビューでは Embers を選んだときだけ動く。再生中も出ないときは、Console のエラーを貼ってください。"),
    ("光るものがにじまない (ブルームがない)",
     "シーンの Global Volume の Profile に Bloom が入っていない。Global Volume を選んで **Add Override > Post-processing > Bloom** を足すと、月や溶岩がにじむ。"),
    ("全体に明るすぎる・暗すぎる部屋がある",
     "部屋ごとのスクリーンショットを送ってください。マテリアルの色・Emission・ライトの明るさを調整した値を返します。"),
]

NEXT = ("段階4では、ジオラマに触れるとその世界に入れるようにします (ズームしながらジオラマが大きくなり、その地面に立つ)。"
        "これは既存の Diorama.shader の中身に強く依存するので、ここで `Assets/NightShards/Diorama` の6ファイルが必要になります。"
        "あわせて、距離による steps の調整と、画面に映っていないジオラマを止める工夫 (パフォーマンス) も入れます。")
