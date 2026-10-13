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

        // マテリアル1つ分の初期値。kind は MuseumSurface の種類 (0 コンクリート / 1 木 / 2 石 / 3 漆喰)
        public struct Spec
        {
            public string name;
            public int kind;
            public Color a;
            public Color b;
            public float smoothness;

            public Spec(string name, int kind, Color a, Color b, float smoothness)
            {
                this.name = name;
                this.kind = kind;
                this.a = a;
                this.b = b;
                this.smoothness = smoothness;
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
                default: return placeholder;
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
                default: placeholder = m; break;
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
            if (m.HasProperty("_Color")) m.SetColor("_Color", spec.a); // Standard で代用したとき用
            return m;
        }

        // MuseumSurface を探す。見つからなければ Standard で代用してエラーを出す
        public static Shader FindShader(Shader preferred)
        {
            if (preferred != null) return preferred;
            var s = Shader.Find("NightShards/MuseumSurface");
            if (s != null) return s;
            Debug.LogError("[Museum] シェーダー NightShards/MuseumSurface が見つかりません。MuseumSurface.shader を Assets に入れてください。");
            return Shader.Find("Standard");
        }
    }
}
