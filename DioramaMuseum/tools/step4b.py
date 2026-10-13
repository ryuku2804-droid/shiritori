"""段階4+ (重さの原因を調べる) のページの中身。make_source_page.py が読み込む。"""

from step1 import museum_map  # 平面図は段階1と同じ

STEP_LABEL = "STEP 4+"
STEP_TITLE = "段階4+:20fps の原因を突き止める"

# 貼る順に並べる。(Assets からのパス, 状態, 説明)
FILES = [
    ("Assets/NightShards/Museum/Scripts/PerfDebug.cs", "新規",
     "重さを調べる道具。F1 で FPS を表示し、F2〜F5 で重そうなものを1つずつ止める"),
    ("Assets/NightShards/Museum/Scripts/DioramaLOD.cs", "変更",
     "すべてのジオラマを止めるスイッチ (HideAll) を追加。描いていないジオラマの判定を確実にした"),
    ("Assets/NightShards/Museum/Scripts/MuseumBuilder.cs", "変更",
     "プレイヤーに PerfDebug を付ける"),
    ("Assets/NightShards/Museum/Scripts/MuseumInput.cs", "変更",
     "F1〜F5 のキーを読めるようにした"),
    ("Assets/NightShards/Museum/Shaders/MuseumDiorama.shader", "そのまま",
     "ガラスケースのジオラマ"),
    ("Assets/NightShards/Museum/Editor/MuseumMenu.cs", "そのまま",
     "組み立てるとき、MuseumDiorama でマテリアル (Museum Diorama.mat) を作る"),
    ("Assets/NightShards/Museum/Scripts/ExhibitStand.cs", "そのまま",
     "ジオラマの箱に、種類 (_Biome) と作品名から決めた形 (_Seed) を渡す"),
    ("Assets/NightShards/Museum/Shaders/MuseumArt.shader", "そのまま",
     "天井の光のスリット (モード 4) を追加"),
    ("Assets/NightShards/Museum/Scripts/RoomArt.cs", "そのまま",
     "板とアートのマテリアルを作る関数を、MuseumBuilder からも使えるようにした"),
    ("Assets/NightShards/Museum/Scripts/CaptionText.cs", "そのまま",
     "中央そろえの文字を置けるようにした (入口の上のサイン用)"),
    ("Assets/NightShards/Museum/Shaders/MuseumSurface.shader", "そのまま",
     "黒曜石と溶岩のひび・水盤・水の光の3種類を追加"),
    ("Assets/NightShards/Museum/Scripts/MuseumMaterials.cs", "そのまま",
     "水盤・黒曜石・玄武岩の壁・水の光の壁と床の5つのマテリアルを追加"),
    ("Assets/NightShards/Museum/Scripts/LightThreads.cs", "そのまま",
     "月の間の、天井から下がる光の糸のメッシュを作る"),
    ("Assets/NightShards/Museum/Scripts/ShojiSun.cs", "そのまま",
     "夕の間の夕日"),
    ("Assets/NightShards/Museum/Shaders/MuseumText.shader", "そのまま",
     "キャプションの文字"),
    ("Assets/NightShards/Museum/Scripts/ExhibitViewer.cs", "そのまま",
     "鑑賞モード"),
    ("Assets/NightShards/Museum/Scripts/MuseumHUD.cs", "そのまま",
     "画面の表示"),
    ("Assets/NightShards/Museum/Scripts/MuseumLayout.cs", "そのまま",
     "館の設計図"),
    ("Assets/NightShards/Museum/Scripts/MuseumGeometry.cs", "そのまま",
     "床・壁・天井を Cube で組む道具"),
    ("Assets/NightShards/Museum/Scripts/FirstPersonController.cs", "そのまま",
     "一人称で歩く"),
]

NOTICE = {
    "title": "まず Scene ビューを止めてから測ってください",
    "body": [
        "段階3で「Scene ビューの **Always Refresh** をオンに」とお願いしました。これがオンのままだと、再生中も Scene ビューが毎フレーム館全体を描き直すので、Game ビューが半分以下の速さになります。",
        "Scene ビューの上のエフェクトのボタン (山と太陽のアイコン) の ▼ で **Always Refresh をオフ** にし、Game ビューの **Play Maximized** をオンにしてから再生してください。これだけで大きく変わる可能性があります。",
    ],
}

OVERVIEW = ("どこでも 20fps ということは、ジオラマだけでなく、館全体に重いものがあります。"
            "当て推量で直すより、再生中に重そうなものを1つずつ止めて、FPS がどれだけ上がるかを測るほうが確実です。"
            "そのための道具 (PerfDebug) を入れました。測った数字を送ってもらえれば、効いているものから直します。")

FLOW = [
    ("PerfDebug", "毎フレームの時間をならして、左上に FPS と ms (1フレームにかかった時間) を出す"),
    ("F2", "DioramaLOD.HideAll で、すべてのジオラマを描かない"),
    ("F3", "影の付いたライト (台座の上のスポットライト8つ) の影を外す"),
    ("F4", "URP の Render Scale を 100% → 75% → 50% と下げる。画面の画素の数が減るので、床・壁・ジオラマの計算がまとめて減る"),
    ("F5", "部屋のアート (火の粉・光の糸・月・障子・天井の光のスリット) を消す"),
]

SEE = [
    "再生すると、画面の左上に「〇〇 fps　〇〇 ms　画面 〇〇×〇〇」と、F2〜F5 の今の状態が出る",
    "F2〜F5 を押すと、それぞれのものが消えたり戻ったりして、FPS の数字が変わる",
    "再生をやめると、Render Scale などは元に戻る",
]

PHASES = [
    {
        "title": "準備",
        "steps": [
            {
                "title": "Scene ビューを止める",
                "body": [
                    "Scene ビューの上のエフェクトのボタン (山と太陽のアイコン) の ▼ で **Always Refresh** のチェックを外す。",
                    "Game ビューの上の **Play Maximized** (または Play Focused) を選び、再生中は Game ビューだけが大きく出るようにする。",
                ],
                "ok": "再生すると Game ビューが画面いっぱいに出る。",
            },
            {
                "title": "ファイルを入れる",
                "body": [
                    "`Scripts` に **Create > MonoBehaviour Script** で `PerfDebug` を作り、中身を置き換える。",
                    "`MuseumInput.cs`・`DioramaLOD.cs`・`MuseumBuilder.cs` を右の新しいものに置き換える。",
                    "**Tools > Diorama Museum > 美術館を組み立てる** を選ぶ (プレイヤーは再生時に作られるので、組み立て直さなくても動く)。",
                ],
                "ok": "Console に赤いエラーがない。",
            },
        ],
    },
    {
        "title": "測る",
        "steps": [
            {
                "title": "そのままの FPS を見る",
                "body": [
                    "再生して、スタート位置で 5 秒ほど待つ。左上の fps と、画面の大きさ (〇〇×〇〇) をメモする。",
                ],
                "ok": "左上に fps が出ている。",
            },
            {
                "title": "1つずつ止める",
                "body": [
                    "**F2** を押してジオラマを消し、fps をメモする。もう一度 F2 で戻す。",
                    "**F3** で影を外して fps をメモ、F3 で戻す。",
                    "**F5** でアートを消して fps をメモ、F5 で戻す。",
                    "**F4** を1回押して 75%、もう1回押して 50% にし、それぞれの fps をメモする。",
                ],
                "ok": "表 (下の「送ってほしい数字」) が埋まった。",
            },
            {
                "title": "送ってほしい数字",
                "body": [
                    "①そのまま ②F2 ジオラマなし ③F3 影なし ④F5 アートなし ⑤F4 75% ⑥F4 50% の6つの fps と、画面の大きさ。",
                    "わかれば、パソコンのグラフィック (GPU) の名前も (Windows の タスク マネージャー > パフォーマンス > GPU に出ている名前)。",
                ],
            },
        ],
    },
]

CHECKS = [
    "左上に fps と ms と画面の大きさが出る",
    "F2 でジオラマが消え、もう一度押すと戻る",
    "F3 で床の影が消える",
    "F4 で画面が少しぼやける (解像度が下がる)",
    "F5 で月・障子・光の糸・火の粉・天井の光の線が消える",
    "再生をやめたあと、Game ビューの解像度が元に戻っている",
]

TROUBLE = [
    ("F キーを押しても何も起きない",
     "Game ビューを1回クリックして、キー入力が Game ビューに行くようにする。ノートパソコンでは Fn キーを押しながら F1〜F5 を押す必要があることがある。"),
    ("左上の表示が出ない",
     "F1 を押す。それでも出ないときは、`Player` に PerfDebug が付いているか、再生中の Hierarchy で確認する。"),
    ("F4 を押しても変わらない",
     "URP のアセットの設定によっては Render Scale が効かないことがある。そのまま F4 の結果を「変わらない」と送ってください。"),
]

NEXT = ("数字がそろったら、いちばん効いているものから直します。"
        "例えばジオラマが重いなら、ジオラマだけを低い解像度で描いて拡大する方式に、影が重いなら影の数を絞る、"
        "床や壁の模様が重いなら模様の計算を軽くする、という具合です。"
        "その上で、余裕のぶんだけ見ている所を細かくする仕組み (視線の中心ほど細かく・自動で品質を上げ下げ) を入れます。")
