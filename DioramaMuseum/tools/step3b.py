"""段階3+ (ホールの空間デザイン) のページの中身。make_source_page.py が読み込む。"""

from step1 import museum_map  # 平面図は段階1と同じ

STEP_LABEL = "STEP 3+"
STEP_TITLE = "段階3+:中央ホールの空間デザイン"

# 貼る順に並べる。(Assets からのパス, 状態, 説明)
FILES = [
    ("Assets/NightShards/Museum/Shaders/MuseumArt.shader", "変更",
     "天井の光のスリット (モード 4) を追加"),
    ("Assets/NightShards/Museum/Scripts/RoomArt.cs", "変更",
     "板とアートのマテリアルを作る関数を、MuseumBuilder からも使えるようにした"),
    ("Assets/NightShards/Museum/Scripts/MuseumBuilder.cs", "変更",
     "ホールに、壁を照らす光・天井の光のスリット・入口の上のサインを追加。Wash Intensity で明るさを変えられる"),
    ("Assets/NightShards/Museum/Scripts/CaptionText.cs", "変更",
     "中央そろえの文字を置けるようにした (入口の上のサイン用)"),
    ("Assets/NightShards/Museum/Shaders/MuseumSurface.shader", "そのまま",
     "黒曜石と溶岩のひび・水盤・水の光の3種類を追加"),
    ("Assets/NightShards/Museum/Scripts/MuseumMaterials.cs", "そのまま",
     "水盤・黒曜石・玄武岩の壁・水の光の壁と床の5つのマテリアルを追加"),
    ("Assets/NightShards/Museum/Scripts/LightThreads.cs", "そのまま",
     "月の間の、天井から下がる光の糸のメッシュを作る"),
    ("Assets/NightShards/Museum/Scripts/ShojiSun.cs", "そのまま",
     "夕の間の夕日"),
    ("Assets/NightShards/Museum/Editor/MuseumMenu.cs", "そのまま",
     "MuseumArt シェーダーを MuseumBuilder の欄に入れる"),
    ("Assets/NightShards/Museum/Shaders/MuseumText.shader", "そのまま",
     "キャプションの文字"),
    ("Assets/NightShards/Museum/Scripts/ExhibitStand.cs", "そのまま",
     "展示1点分"),
    ("Assets/NightShards/Museum/Scripts/ExhibitViewer.cs", "そのまま",
     "鑑賞モード"),
    ("Assets/NightShards/Museum/Scripts/MuseumHUD.cs", "そのまま",
     "画面の表示"),
    ("Assets/NightShards/Museum/Scripts/MuseumLayout.cs", "そのまま",
     "館の設計図"),
    ("Assets/NightShards/Museum/Scripts/MuseumGeometry.cs", "そのまま",
     "床・壁・天井を Cube で組む道具"),
    ("Assets/NightShards/Museum/Scripts/MuseumInput.cs", "そのまま",
     "キーとマウスの読み取り"),
    ("Assets/NightShards/Museum/Scripts/FirstPersonController.cs", "そのまま",
     "一人称で歩く"),
]

NOTICE = {
    "title": "今回の変更:暗く沈んでいたホールを仕上げる",
    "body": [
        "スクリーンショットでは、ホールの壁がほぼ真っ黒で、空間の形がわかりませんでした。そこでホールに3つを足しました。",
        "**変更** の4ファイル (`MuseumArt.shader`・`CaptionText.cs`・`RoomArt.cs`・`MuseumBuilder.cs`) を貼り直し、**Tools > Diorama Museum > 美術館を組み立てる** を選んでください。",
    ],
}

OVERVIEW = ("美術館の第一印象を決めるホールを、ただの暗い箱から「どこへ向かうかがわかる、静かな広間」にします。"
            "**壁を照らす光**で打ち放しコンクリートの継ぎ目とセパ穴を浮かび上がらせ、"
            "**天井の光のスリット**を中心から4つの部屋へ十字に走らせて、歩く向きへ目を導きます。"
            "各入口の上には、**部屋の名前と作品名のサイン**を出します。")

FLOW = [
    ("MuseumBuilder", "ホールと4つの部屋を組んだあと、**BuildHallDecor** でホールの仕上げを足す"),
    ("壁を照らす光", "各面の出入口の両わきに1つずつ、天井近くから壁に沿って下へ向けたスポットライト。明るさは Wash Intensity"),
    ("天井の光のスリット", "MuseumArt のモード 4 (光の線) の細長い板を、天井の中心から各部屋の入口へ向けて貼る"),
    ("入口の上のサイン", "CaptionText で、部屋の名前 (大) と作品名 (小) を中央そろえで置く。文字は光を受けない MuseumText で描くので暗くても読める"),
]

SEE = [
    "ホールの4つの壁が、上から下へ流れる光で照らされ、コンクリートの継ぎ目と丸い穴が見える",
    "天井に、中心から4方向へのびる細い光の線がある",
    "各入口の上に「月の間」などの部屋の名前と、その下に小さく作品名が出ている",
    "Brightness や Wash Intensity を動かすと、壁の明るさがその場で変わる",
]

PHASES = [
    {
        "title": "貼り直して組み立てる",
        "steps": [
            {
                "title": "変更の4ファイルを貼り直す",
                "body": [
                    "右のタブで ● の付いた `MuseumArt.shader`・`CaptionText.cs`・`RoomArt.cs`・`MuseumBuilder.cs` の中身を入れ替える。",
                ],
                "ok": "Console に赤いエラーがない。",
            },
            {
                "title": "Tools で組み立て直す",
                "body": ["**Tools > Diorama Museum > 美術館を組み立てる** を選ぶ。"],
                "ok": "Hierarchy の `Museum (Generated)` に `Hall Decor` があり、Scene ビューでホールの天井に十字の光の線が見える。",
            },
        ],
    },
    {
        "title": "再生して見る",
        "steps": [
            {
                "title": "スタート位置から見回す",
                "body": [
                    "再生して、スタート位置でゆっくり一周見回す。",
                    "壁が明るすぎる・暗すぎるときは、`Museum` の **Wash Intensity** を変える (再生中でもその場で変わる)。",
                ],
                "ok": "ホールの形 (4つの壁と天井の高さ) がわかり、正面の入口の上に「月の間」と読める。",
            },
            {
                "title": "スクリーンショットを送る",
                "body": ["スタート位置からの1枚と、気になるところがあればその場所の1枚を送ってください。"],
            },
        ],
    },
]

CHECKS = [
    "ホールの壁に光が流れ、コンクリートの質感が見える",
    "天井の光の線が、各部屋の入口の方向にのびている",
    "入口の上のサインが左右反転せずに読める",
    "サインの文字が、ホールの外 (通路や部屋) から壁を透けて見えない",
]

TROUBLE = [
    ("サインの文字が左右反転している",
     "向きの計算の間違い。スクリーンショットを送ってください。"),
    ("天井の光の線が見えない",
     "`Museum` の Inspector の **Art Shader** に MuseumArt が入っているか確認する。空なら Tools で組み立て直すと入る。"),
    ("Assets\\...\\MuseumBuilder.cs: error CS1501 / CS1061 (CaptionText の Add について)",
     "`CaptionText.cs` が古いまま。右の新しいものに入れ替える。"),
]

NEXT = ("次は、ジオラマの機能と見た目を仕上げます (触れるとその世界に入る・距離で steps を調整・画面外のジオラマを止める)。"
        "ここから先は既存の `Assets/NightShards/Diorama` の6ファイルが必要です。")
