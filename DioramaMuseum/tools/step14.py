"""段階14 (白い点滅を、ジオラマの側で直す) のページの中身。make_source_page.py が読み込む。"""

from step5 import museum_map  # 平面図は段階5と同じ

STEP_LABEL = "STEP 14"
STEP_TITLE = "段階14:白い点滅を直す (ジオラマの計算の守り)"

# 貼る順に並べる。(Assets からのパス, 状態, 説明)
FILES = [
    ("Assets/NightShards/Museum/Shaders/DioramaBlueFire.shader", "変更",
     "壊れた値のピクセルが出ないようにした (画面の白い点滅を直す)"),
    ("Assets/NightShards/Museum/Shaders/DioramaEruption.shader", "変更",
     "同じ守りを、大噴火にも入れた"),
    ("Assets/NightShards/Museum/Scripts/DioramaTerrain.cs", "そのまま",
     "焦土の地形に合わせて、歩く地面と立つ場所を直した"),
    ("Assets/NightShards/Museum/Scripts/MuseumLayout.cs", "そのまま",
     "作品名を「青い火の焦土」にし、説明文を変えた"),
    ("Assets/NightShards/Museum/Shaders/MuseumArt.shader", "そのまま",
     "カメラのすぐ前を通る火の粉を消す (画面が白く点滅するのを直す)"),
    ("Assets/NightShards/Museum/Scripts/DioramaWork.cs", "そのまま",
     "青い炎の音 (ガスが燃える音) と、部屋の照明を青に染める色を足した"),
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
    "title": "貼り直すのはシェーダー 2 つだけです",
    "body": ["`DioramaBlueFire.shader` と `DioramaEruption.shader`。組み立て直しは要りません。"],
}

OVERVIEW = ("新しい動画を 1 コマずつ調べると、白い光は**ジオラマを中心に**広がり、その真ん中に小さな黒い点がありました。"
            "これは、ジオラマの計算で 1 ピクセルだけ値が壊れて (「数でない値」や「無限に明るい値」になって)、"
            "ブルーム (明るい所をにじませる仕上げ) がそれを画面いっぱいに広げていた、という印です。"
            "前回の火の粉は本当の原因ではありませんでした (火の粉の直しは、そのまま入れておいて大丈夫です)。"
            "壊れる原因になりやすい「地面の向き」の計算に守りを入れ、さらに最後に色と不透明度を決まった範囲に収めて、"
            "どこかで値が壊れても画面には出ないようにしました。")

FLOW = [
    ("SceneNormal (地面の向き)", "まわりの 4 点の距離の差から向きを出す。差がちょうど 0 になると 0 で割って値が壊れていたので、割る数を小さな値より小さくしない"),
    ("Frag の最後 (仕上げ)", "色を 0〜64、不透明度を 0〜1 に収める。値が壊れていたときは 0 になるので、ブルームに広がらない"),
]

SEE = [
    "火の間で、ジオラマのまわりから画面が白く光る点滅が出ない",
    "ジオラマの見た目は、今までと変わらない",
]

PHASES = [
    {
        "title": "直す",
        "steps": [
            {
                "title": "シェーダー 2 つを貼り直す",
                "body": ["右のタブで ● の付いた `DioramaBlueFire.shader` と `DioramaEruption.shader` を貼り直す。"],
                "ok": "Console にエラーがなく、シェーダーを選んだ Inspector にもエラーがない。",
            },
            {
                "title": "火の間で確かめる",
                "body": ["再生して火の間に入り、2 つのジオラマのまわりを 30 秒ほど歩いたり見回したりする。"],
                "ok": "画面が白く点滅しない。",
            },
        ],
    },
]

CHECKS = [
    "ジオラマのまわりで画面が白く点滅しない",
    "ジオラマの見た目は変わらない",
]

TROUBLE = [
    ("まだ白く点滅する",
     "点滅したときの動画をもう一度送ってください。どちらのジオラマの近くで起きたかも教えてください。"),
]

NEXT = "点滅が消えたら、段階13 の「青い火の焦土」のスクリーンショットと FPS を見て、見た目を詰めます。"
