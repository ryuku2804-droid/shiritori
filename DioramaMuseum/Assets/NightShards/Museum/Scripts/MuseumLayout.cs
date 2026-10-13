using System;
using System.Collections.Generic;
using UnityEngine;

namespace NightShards.Museum
{
    // 中央ホールから見て、展示室をどの方向に伸ばすか
    public enum RoomDirection { North, East, South, West }

    // 展示室ごとの作品テーマ。段階3で、部屋ごとの床・壁・光のアートをこれで切り替える
    public enum RoomTheme { Moon, Fire, Dusk, Sea }

    // ジオラマ1点分の設定
    [Serializable]
    public class ExhibitSpec
    {
        public string title = "無題";
        [TextArea(2, 4)] public string description = "";
        [Tooltip("0 アルプス月夜 / 1 火山島 / 2 日本の夕焼け / 3 南国の島")]
        [Range(0, 3)] public int biome = 0;
    }

    // 展示室1つ分の設定
    [Serializable]
    public class RoomSpec
    {
        public string name = "展示室";
        public RoomTheme theme = RoomTheme.Moon;
        public RoomDirection direction = RoomDirection.North;
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
        [Header("中央ホール")]
        [Tooltip("x: 幅 / y: 天井の高さ / z: 奥行き (m)")]
        public Vector3 hallSize = new Vector3(14f, 7f, 14f);

        [Header("通路")]
        public float corridorLength = 6f;
        public float corridorWidth = 3f;
        public float corridorHeight = 3.2f;

        [Header("共通")]
        public float wallThickness = 0.3f;
        [Tooltip("台座の上に当てるスポットライトに影を付けるか (重さに効く)")]
        public bool spotShadows = true;

        [Header("展示室 (1方向に1室まで)")]
        public List<RoomSpec> rooms = new List<RoomSpec>();

        // 初期設定。4つのバイオームを、それぞれの部屋に2点ずつ置く
        public static MuseumLayout CreateDefault()
        {
            var layout = new MuseumLayout();
            layout.rooms.Add(MakeRoom("月の間", RoomTheme.Moon, RoomDirection.North, new Color(0.55f, 0.68f, 1f), 0,
                ("アルプス月夜", "雪をかぶった峰々を、満月が青く照らす夜。"),
                ("月下の谷", "山あいの小さな村に、月の光だけが届いている。")));
            layout.rooms.Add(MakeRoom("火の間", RoomTheme.Fire, RoomDirection.East, new Color(1f, 0.45f, 0.2f), 1,
                ("火山島", "海の上にそびえる火山。山頂から溶岩が流れ落ちる。"),
                ("噴煙", "灰の雲の下で、島はまだ赤く脈打っている。")));
            layout.rooms.Add(MakeRoom("夕の間", RoomTheme.Dusk, RoomDirection.West, new Color(1f, 0.62f, 0.35f), 2,
                ("日本の夕焼け", "瓦屋根と鳥居を、沈む夕日が茜色に染める。"),
                ("帰り道", "一日の終わり、町に最初の明かりがともる。")));
            layout.rooms.Add(MakeRoom("海の間", RoomTheme.Sea, RoomDirection.South, new Color(0.35f, 0.9f, 0.85f), 3,
                ("南国の島", "透きとおる浅瀬に囲まれた、椰子の島。"),
                ("潮だまり", "真昼の光が、珊瑚の海の底まで届く。")));
            return layout;
        }

        static RoomSpec MakeRoom(string name, RoomTheme theme, RoomDirection dir, Color accent, int biome,
            params (string title, string desc)[] works)
        {
            var room = new RoomSpec { name = name, theme = theme, direction = dir, accent = accent };
            foreach (var w in works)
                room.exhibits.Add(new ExhibitSpec { title = w.title, description = w.desc, biome = biome });
            return room;
        }
    }
}
