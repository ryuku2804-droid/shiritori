"""段階20 (海の間をリアルに・深海の生き物) のページの中身。make_source_page.py が読み込む。"""

from step5 import museum_map  # 平面図は段階5と同じ

STEP_LABEL = "STEP 20"
STEP_TITLE = "段階20:海の間をリアルに。立体の魚・クラゲと、ダイオウグソクムシたち"

# 貼る順に並べる。(Assets からのパス, 状態, 説明)
FILES = [
    ("Assets/NightShards/Museum/Shaders/DioramaAtoll.shader", "変更",
     "水の屈折と色の吸収・3 重の波・砂の波紋と海草・くっきりした光の網目・白い砕け波・魚の影・砂浜の質感"),
    ("Assets/NightShards/Museum/Shaders/DioramaDeepSea.shader", "変更",
     "本物の海の光り方 (赤から消える)・マリンスノー・立体の魚とクラゲ・ダイオウグソクムシ・ナマコ・クモヒトデ・チョウチンアンコウ"),
    ("Assets/NightShards/Museum/Scripts/DioramaTerrain.cs", "そのまま",
     "環礁と海の断面の地形 (歩く地面と立つ場所) を足した"),
    ("Assets/NightShards/Museum/Scripts/DioramaWork.cs", "そのまま",
     "潮が引く音・深海の光の音と、部屋の照明を染める色を足した"),
    ("Assets/NightShards/Museum/Scripts/MuseumLayout.cs", "そのまま",
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
    "title": "貼り直すのはシェーダー 2 つだけです",
    "body": ["`DioramaDeepSea.shader` と `DioramaAtoll.shader` の中身を全部置き換えてください。組み立て直しは要りません。"],
}

OVERVIEW = ("**海の断面**: 水の光り方を本物の海に近づけました。水は赤い光ほど早く吸い込むので、深くなるほど赤が消えて青だけが残り、やがて真っ暗になります "
            "(水のにごりを赤・緑・青で別々に計算)。白いマリンスノーがゆっくり沈み、砂には波紋、珊瑚には脳みそのような筋と小さな粒 (ポリプ) が入りました。"
            "生き物は光の点をやめて、**立体の形**にしました。魚は尾びれ・背びれ・目があり、体をくねらせて泳ぎます (背中は暗い青、おなかは銀色、うろこがきらめく)。"
            "クラゲは半透明のかさが拍動して縁が光り、8 本の長い触手と、ひらひらした 4 本の口腕がゆれます。"
            "深い底には、**ダイオウグソクムシ** 2 匹 (節のある殻・しっぽの扇・触角・14 本の脚で、底をゆっくり歩きまわる)、ナマコ 3 匹、"
            "クモヒトデ 3 匹 (腕がうねる)、竿の先が光る**チョウチンアンコウ**。生物発光の仕掛けでは、深海の生き物たちが青い光に浮かび上がります。"
            "**環礁**: 水面で光が曲がって (屈折して) 底がゆらいで見え、深さで色が変わります (浅い所は透明、そこからターコイズ、深い青)。"
            "波は大きさと向きのちがう 3 つの重ね合わせ。底は白い砂の波紋・海草の茂み・サンゴのかたまりで、くっきりした光の網目が動き、魚の影が横切ります。"
            "サンゴ礁と小島の縁では白い波が砕け、砂浜は砂粒のむらと濡れた波打ち際が見えます。")

FLOW = [
    ("水 (DeepSea)", "にごりを赤・緑・青で別々にかける。日の光も深さで赤から消える。白いマリンスノーを足す"),
    ("生き物を探す (DeepSea)", "38 匹それぞれを包む球に線が当たるかを先に調べ、当たった球の中だけで、その生き物の形 (距離の式) を進む。だから数が多くても軽い"),
    ("生き物の形 (DeepSea)", "だ円体・カプセルを組み合わせる。魚は体を波打たせ、ダイオウグソクムシは脚を左右互い違いに動かし、クラゲはかさを拍動させる"),
    ("生き物の色 (DeepSea)", "魚は背中と腹で色を変え、うろこのきらめきと目。クラゲは半透明で縁ほど光る。ダイオウグソクムシは殻のつやと節のみぞ"),
    ("水面 (Atoll)", "3 つの波を重ねた水面で、線を曲げて底のずれた所を見る。底までの道のりで色を吸い、空と日のきらめきを映す"),
]

SEE = [
    "海の断面: 深くなるほど青く暗くなり、白い粒がゆっくり沈む",
    "浅瀬に、立体の魚の群れが体をくねらせて泳ぐ (近くで見ると、ひれと目が見える)",
    "半透明のクラゲが拍動し、長い触手がゆれる",
    "深い底を、ダイオウグソクムシが脚を動かして歩いている。ナマコ、クモヒトデ、光る竿のチョウチンアンコウ",
    "Space で、深海の生き物たちが青い光に浮かび上がる",
    "環礁: 浅瀬の底が波でゆらいで見え、光の網目が動き、魚の影が横切る。縁では白い波が砕ける",
]

PHASES = [
    {
        "title": "入れて見る",
        "steps": [
            {
                "title": "シェーダー 2 つを貼り直す",
                "body": ["右のタブで ● の付いた `DioramaDeepSea.shader` と `DioramaAtoll.shader` を貼り直す。"],
                "ok": "2 つのシェーダーの Inspector にエラーがない。",
            },
            {
                "title": "海の断面を近くで見る",
                "body": [
                    "E で鑑賞し、ホイールで近づいて、浅瀬の魚、クラゲ、深い底の生き物を見る。",
                    "Space で生物発光を起こす。クリックで中に入って、深い底まで降りてみる。",
                ],
                "ok": "生き物が立体に見え、動いている。",
            },
            {
                "title": "環礁を見る",
                "body": ["E で鑑賞して、浅瀬を近くで見る。"],
                "ok": "底がゆらいで見え、光の網目と魚の影が動く。",
            },
            {
                "title": "スクリーンショットと FPS を送る",
                "body": ["生き物のアップと、2 作品の全体のスクリーンショット、FPS (F1) を送ってください。"],
            },
        ],
    },
]

CHECKS = [
    "深くなるほど赤が消え、青く暗くなる",
    "魚・クラゲが立体に見える",
    "ダイオウグソクムシが底を歩いている",
    "環礁の浅瀬で、底がゆらいで見える",
]

TROUBLE = [
    ("ジオラマがピンク",
     "Project でそのシェーダーを選ぶと、Inspector にエラーの行が出ます。その文を送ってください。"),
    ("深い底が暗すぎて生き物が見えない",
     "深海のほのかな明るさを上げます。スクリーンショットを送ってください (Space の生物発光のときは、よく見えます)。"),
    ("重くなった",
     "生き物が多いので、少し重くなります。FPS を送ってください。数を減らしたり、遠くでは省いたりできます。"),
]

NEXT = "スクリーンショットを見て、生き物と水の見た目を詰めます。そのあと、夕の間に進みます。"
