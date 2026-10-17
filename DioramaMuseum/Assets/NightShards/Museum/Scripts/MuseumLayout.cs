using System;
using System.Collections.Generic;
using UnityEngine;

namespace NightShards.Museum
{
    // 壁の面の向き (長方形の部屋の4つの壁を区別するのに使う)
    public enum RoomDirection { North, East, South, West }

    // 展示室のテーマ。床・壁の質感と、部屋のアートをこれで選ぶ
    //   自然の部屋: Moon 月 / Fire 火 / Dusk 夕 / Sea 海
    //   世界の部屋: Asia アジア / Europe ヨーロッパ / Desert 砂漠と塩 / Andes アンデス
    public enum RoomTheme { Moon, Fire, Dusk, Sea, Asia, Europe, Desert, Andes }

    // ジオラマ1点分の設定
    [Serializable]
    public class ExhibitSpec
    {
        public string title = "無題";
        [Tooltip("キャプションの2行目に出す場所の名前")]
        public string place = "";
        [TextArea(2, 4)] public string description = "";
        [Tooltip("作品専用のシェーダーの名前 (例: Eruption → NightShards/Diorama/Eruption)。空なら下の biome で共通のジオラマを描く")]
        public string work = "";
        [Tooltip("共通のジオラマの描き方。0 雪山 / 1 火山 / 2 日本 / 3 南の海。-1 はまだ作っていない作品 (仮の箱を置く)")]
        [Range(-1, 3)] public int biome = 0;
    }

    // 展示室1つ分の設定
    [Serializable]
    public class RoomSpec
    {
        public string name = "展示室";
        public RoomTheme theme = RoomTheme.Moon;
        [Tooltip("ドームのまわりの位置。0 が正面 (北)、そこから時計回りに 45° ずつ 1〜7")]
        [Range(0, 7)] public int slot = 0;
        [Tooltip("部屋の幅 (通路と直角の向き、m)")] public float width = 12f;
        [Tooltip("部屋の奥行き (通路の向き、m)")] public float depth = 10f;
        [Tooltip("天井の高さ (m)")] public float height = 6f;
        [Tooltip("部屋の差し色。通路から漏れる光と、部屋のほのかな光に使う")]
        public Color accent = Color.white;
        public List<ExhibitSpec> exhibits = new List<ExhibitSpec>();
    }

    // 美術館全体の設定。MuseumBuilder の Inspector でこれを書き換えると、配置が自動で変わる
    [Serializable]
    public class MuseumLayout
    {
        public const int SlotCount = 8;

        [Header("中央のドーム")]
        [Tooltip("ドームの内側の半径 (m)")]
        public float domeRadius = 13f;
        [Tooltip("ドームの丸い天井が始まるまでの、まっすぐな壁の高さ (m)")]
        public float drumHeight = 4.5f;
        [Tooltip("天井のてっぺんの丸い天窓の半径 (m)")]
        public float oculusRadius = 1.6f;

        [Header("通路")]
        public float corridorLength = 5f;
        public float corridorWidth = 3f;
        public float corridorHeight = 3.2f;

        [Header("共通")]
        public float wallThickness = 0.3f;
        [Tooltip("台座の上に当てるスポットライトに影を付けるか (重さに効く)")]
        public bool spotShadows = true;

        [Header("展示室 (ドームのまわりの 8 か所に1室ずつ)")]
        public List<RoomSpec> rooms = new List<RoomSpec>();

        // スロットの番号から、ドームの中心から見た向き (度)。0 = 北 (+z)、時計回り
        public static float SlotAngle(int slot) => slot * (360f / SlotCount);

        // 初期設定: 自然の部屋と世界の部屋を交互に、雰囲気の近いもの同士が隣になるように並べる
        public static MuseumLayout CreateDefault()
        {
            var layout = new MuseumLayout();
            layout.rooms.Add(MakeRoom("月の間", RoomTheme.Moon, 0, new Color(0.55f, 0.68f, 1f),
                ("月下の氷河", "スイス・アルプス", "稜線から月が昇り、氷河と雪の峰が青白く輝く。湖に一本の光の道。", 0),
                ("オーロラの夜", "北極圏", "凍った湖の上で、オーロラが空いっぱいに揺れる。", 0)));
            layout.rooms.Add(MakeRoom("ヨーロッパの間", RoomTheme.Europe, 1, new Color(0.95f, 0.8f, 0.55f),
                ("夜のパリ", "フランス・パリ", "凱旋門からのびる光の通りの先で、エッフェル塔がきらめく。", -1),
                ("ピサの斜塔", "イタリア・ピサ", "奇跡の広場の大聖堂と斜塔。鐘が鳴ると、鳩が一斉に飛び立つ。", -1)));
            layout.rooms.Add(MakeRoom("火の間", RoomTheme.Fire, 2, new Color(1f, 0.45f, 0.2f),
                ("大噴火", "火山島", "噴煙の柱の中で火山雷が光り、溶岩が海に流れ込む。", 1),
                ("青い火の焦土", "焼け野原", "青い炎に焼かれた大地。割れ目の奥で熱が青く光り、焼け残った木がくすぶる。", 1)));
            layout.rooms.Add(MakeRoom("砂漠と塩の間", RoomTheme.Desert, 3, new Color(1f, 0.75f, 0.45f),
                ("ギザのピラミッド", "エジプト・ギザ", "夕暮れの三大ピラミッドとスフィンクス。砂嵐が吹き抜けると、夕日がいっそう赤く差す。", -1),
                ("死海", "ヨルダン・イスラエル", "白い塩の岸と青緑の水、塩のきのこ、浮かんで新聞を読む人。塩の結晶が水の中から育つ。", -1)));
            layout.rooms.Add(MakeRoom("海の間", RoomTheme.Sea, 4, new Color(0.35f, 0.9f, 0.85f),
                ("環礁", "南太平洋", "空に浮かぶ環礁。縁から海がこぼれ落ち、潮が引くと砂州の道が現れる。", 3),
                ("海の断面", "珊瑚の海から深海へ", "明るい珊瑚の浅瀬から、光の届かない深海まで。生き物たちが一斉に光る。", 3)));
            layout.rooms.Add(MakeRoom("アンデスの間", RoomTheme.Andes, 5, new Color(0.7f, 0.85f, 1f),
                ("ウユニ塩湖", "ボリビア", "天空の鏡。雲も車も人も、空といっしょに足元に映る。夜になると、星の中に浮かぶ。", -1),
                ("マチュピチュ", "ペルー", "尾根の上の空中都市とワイナピチュ。雲海がわき上がって包み、引くと朝日が照らし出す。", -1)));
            layout.rooms.Add(MakeRoom("夕の間", RoomTheme.Dusk, 6, new Color(1f, 0.62f, 0.35f),
                ("黄昏の棚田", "日本の里山", "夕日を映す棚田。日が沈むと家々に灯がともり、蛍が舞う。", 2),
                ("千本鳥居の山", "霧の参道", "霧の山を、朱の鳥居の参道がどこまでも登っていく。", 2)));
            layout.rooms.Add(MakeRoom("アジアの間", RoomTheme.Asia, 7, new Color(0.95f, 0.45f, 0.35f),
                ("万里の長城", "中国", "秋の山の尾根を、望楼をつないでうねる城壁。夕暮れ、のろしが次々にともって尾根を伝う。", -1),
                ("日本の庭", "日本・京都 (金閣寺)", "鏡湖池に映る金色の舎利殿と、もみじの山。風が吹くと、もみじが舞い散って池に浮かぶ。", -1)));
            return layout;
        }

        static RoomSpec MakeRoom(string name, RoomTheme theme, int slot, Color accent,
            params (string title, string place, string desc, int biome)[] works)
        {
            var room = new RoomSpec { name = name, theme = theme, slot = slot, accent = accent };
            foreach (var w in works)
                room.exhibits.Add(new ExhibitSpec { title = w.title, place = w.place, description = w.desc, biome = w.biome, work = WorkFor(w.title) });
            return room;
        }

        // 作品専用のシェーダーができている作品の名前。作品を1つ作り込むたびに、ここに足す
        public static string WorkFor(string title)
        {
            switch (title)
            {
                case "大噴火": return "Eruption";
                case "月下の氷河": return "Glacier";
                case "オーロラの夜": return "Aurora";
                case "環礁": return "Atoll";
                case "海の断面": return "DeepSea";
                case "黄昏の棚田": return "Terraces";
                case "千本鳥居の山": return "Torii";
                case "夜のパリ": return "Paris";
                case "ピサの斜塔": return "Pisa";
                case "ギザのピラミッド": return "Pyramids";
                case "死海": return "DeadSea";
                case "ウユニ塩湖": return "Uyuni";
                case "マチュピチュ": return "MachuPicchu";
                case "万里の長城": return "GreatWall";
                case "日本の庭": return "Kinkaku";
                case "青い火の焦土": return "BlueFire";
                case "青い火の火口湖": return "BlueFire"; // 前の名前 (前に保存した設計図のため)
                default: return "";
            }
        }
    }
}
