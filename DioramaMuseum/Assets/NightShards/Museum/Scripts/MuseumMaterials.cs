using System;
using UnityEngine;

namespace NightShards.Museum
{
    // 館で使うマテリアルのまとめ。
    // Tools メニューで組み立てると、Generated フォルダにマテリアルのファイルとして保存され、ここに入る (あとから色を調整できる)。
    // 空の欄は、再生したときにその場で作る
    [Serializable]
    public class MuseumMaterials
    {
        public Material concreteWall;
        public Material concreteCeiling;
        public Material darkStone;
        public Material paleStone;
        public Material wood;
        public Material pedestal;
        public Material placeholder;
        public Material water;          // 月の間の床 (水盤)
        public Material obsidian;       // 火の間の床 (溶岩のひび)
        public Material basaltWall;     // 火の間の壁
        public Material causticWall;    // 海の間の壁と天井 (水の光)
        public Material causticFloor;   // 海の間の床
        public Material plasterWall;    // 世界の部屋の白い漆喰の壁
        public Material sandstone;      // 砂漠と塩の間の床
        public Material marble;         // ヨーロッパの間の床
        public Material domeFloor;      // ドームの床 (方位盤)
        public Material domeCoffer;     // ドームの格天井と壁

        // マテリアル1つ分の初期値。kind は MuseumSurface の種類
        // (0 コンクリート / 1 木 / 2 石 / 3 漆喰 / 4 黒曜石と溶岩 / 5 水盤 / 6 水の光の映る漆喰 / 7 格天井 / 8 方位盤)
        public struct Spec
        {
            public string name;
            public int kind;
            public Color a;
            public Color b;
            public float smoothness;
            public Color emission; // 自分で光る色 (溶岩・水の光)。1 より大きい値はブルームでにじむ

            public Spec(string name, int kind, Color a, Color b, float smoothness) : this(name, kind, a, b, smoothness, Color.black) { }

            public Spec(string name, int kind, Color a, Color b, float smoothness, Color emission)
            {
                this.name = name;
                this.kind = kind;
                this.a = a;
                this.b = b;
                this.smoothness = smoothness;
                this.emission = emission;
            }
        }

        // 並びは Get / Set の番号と同じ
        public static readonly Spec[] Defaults =
        {
            new Spec("Concrete Wall", 0, new Color(0.46f, 0.45f, 0.43f), new Color(0.34f, 0.33f, 0.32f), 0.18f),
            new Spec("Concrete Ceiling", 0, new Color(0.22f, 0.22f, 0.22f), new Color(0.15f, 0.15f, 0.16f), 0.1f),
            new Spec("Dark Stone", 2, new Color(0.07f, 0.07f, 0.08f), new Color(0.13f, 0.13f, 0.14f), 0.78f),
            new Spec("Pale Stone", 2, new Color(0.62f, 0.62f, 0.6f), new Color(0.5f, 0.5f, 0.49f), 0.6f),
            new Spec("Wood", 1, new Color(0.36f, 0.22f, 0.13f), new Color(0.22f, 0.12f, 0.07f), 0.45f),
            new Spec("Pedestal", 3, new Color(0.05f, 0.05f, 0.055f), new Color(0.08f, 0.08f, 0.085f), 0.35f),
            new Spec("Placeholder", 3, new Color(0.8f, 0.8f, 0.78f), new Color(0.7f, 0.7f, 0.68f), 0.1f),
            new Spec("Water", 5, new Color(0.012f, 0.016f, 0.03f), new Color(0.02f, 0.03f, 0.05f), 0.96f),
            new Spec("Obsidian", 4, new Color(0.025f, 0.02f, 0.02f), new Color(0.05f, 0.04f, 0.04f), 0.85f, new Color(4f, 1.1f, 0.15f)),
            new Spec("Basalt Wall", 0, new Color(0.14f, 0.12f, 0.11f), new Color(0.08f, 0.07f, 0.07f), 0.2f),
            new Spec("Caustic Wall", 6, new Color(0.82f, 0.86f, 0.86f), new Color(0.74f, 0.79f, 0.8f), 0.15f, new Color(0.4f, 0.9f, 0.95f)),
            new Spec("Caustic Floor", 6, new Color(0.55f, 0.75f, 0.78f), new Color(0.45f, 0.65f, 0.7f), 0.7f, new Color(0.6f, 1.2f, 1.25f)),
            new Spec("Plaster Wall", 3, new Color(0.72f, 0.69f, 0.64f), new Color(0.66f, 0.63f, 0.58f), 0.08f),
            new Spec("Sandstone", 2, new Color(0.62f, 0.5f, 0.36f), new Color(0.52f, 0.41f, 0.29f), 0.3f),
            new Spec("Marble", 2, new Color(0.78f, 0.77f, 0.74f), new Color(0.6f, 0.6f, 0.6f), 0.85f),
            new Spec("Dome Floor", 8, new Color(0.05f, 0.05f, 0.06f), new Color(0.1f, 0.1f, 0.11f), 0.82f),
            new Spec("Dome Coffer", 7, new Color(0.62f, 0.6f, 0.56f), new Color(0.5f, 0.48f, 0.45f), 0.1f),
        };

        public Material Get(int i)
        {
            switch (i)
            {
                case 0: return concreteWall;
                case 1: return concreteCeiling;
                case 2: return darkStone;
                case 3: return paleStone;
                case 4: return wood;
                case 5: return pedestal;
                case 6: return placeholder;
                case 7: return water;
                case 8: return obsidian;
                case 9: return basaltWall;
                case 10: return causticWall;
                case 11: return causticFloor;
                case 12: return plasterWall;
                case 13: return sandstone;
                case 14: return marble;
                case 15: return domeFloor;
                default: return domeCoffer;
            }
        }

        public void Set(int i, Material m)
        {
            switch (i)
            {
                case 0: concreteWall = m; break;
                case 1: concreteCeiling = m; break;
                case 2: darkStone = m; break;
                case 3: paleStone = m; break;
                case 4: wood = m; break;
                case 5: pedestal = m; break;
                case 6: placeholder = m; break;
                case 7: water = m; break;
                case 8: obsidian = m; break;
                case 9: basaltWall = m; break;
                case 10: causticWall = m; break;
                case 11: causticFloor = m; break;
                case 12: plasterWall = m; break;
                case 13: sandstone = m; break;
                case 14: marble = m; break;
                case 15: domeFloor = m; break;
                default: domeCoffer = m; break;
            }
        }

        // 空の欄だけ、その場でマテリアルを作って埋める
        public void FillMissing(Shader shader)
        {
            for (int i = 0; i < Defaults.Length; i++)
                if (Get(i) == null) Set(i, Create(Defaults[i], shader));
        }

        public static Material Create(Spec spec, Shader shader)
        {
            var m = new Material(shader) { name = spec.name };
            m.SetFloat("_Kind", spec.kind);
            m.SetColor("_ColorA", spec.a);
            m.SetColor("_ColorB", spec.b);
            m.SetFloat("_Smoothness", spec.smoothness);
            if (m.HasProperty("_EmissionColor")) m.SetColor("_EmissionColor", spec.emission);
            if (m.HasProperty("_BaseColor")) m.SetColor("_BaseColor", spec.a); // URP/Lit で代用したとき用
            return m;
        }

        // MuseumSurface を探す。見つからなければ Standard で代用してエラーを出す
        public static Shader FindShader(Shader preferred)
        {
            if (preferred != null) return preferred;
            var s = Shader.Find("NightShards/MuseumSurface");
            if (s != null) return s;
            Debug.LogError("[Museum] シェーダー NightShards/MuseumSurface が見つかりません。MuseumSurface.shader を Assets に入れてください。");
            return Shader.Find("Universal Render Pipeline/Lit");
        }

        // MuseumSurface は URP 用。Built-In や HDRP のプロジェクトでは描けずにピンク色になる
        public static bool IsUniversalPipeline()
        {
            var rp = UnityEngine.Rendering.GraphicsSettings.currentRenderPipeline;
            return rp != null && rp.GetType().Name.Contains("Universal");
        }

        public static bool WarnIfNotUniversalPipeline()
        {
            if (IsUniversalPipeline()) return false;
            var rp = UnityEngine.Rendering.GraphicsSettings.currentRenderPipeline;
            string current = rp == null ? "Built-In Render Pipeline" : rp.GetType().Name;
            Debug.LogError($"[Museum] このプロジェクトは URP ではなく「{current}」で描いています。" +
                           "MuseumSurface は URP 用なので、ピンク色になります。");
            return true;
        }
    }
}
