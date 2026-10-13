using System.Collections.Generic;
using UnityEngine;

namespace NightShards.Museum
{
    // 展示1点分 (台座・ジオラマ・キャプションのプレート)。
    // 鑑賞モード (ExhibitViewer) は、ここにある「見る中心」と「見る距離」を使う
    [ExecuteAlways]
    public class ExhibitStand : MonoBehaviour
    {
        // いまシーンにある展示の一覧 (近くの作品を探すのに使う)
        public static readonly List<ExhibitStand> All = new List<ExhibitStand>();


        // 仮の箱をバイオームごとに色分けする (ジオラマがまだないとき)
        static readonly Color[] BiomeTints =
        {
            new Color(0.55f, 0.65f, 0.9f), new Color(0.85f, 0.4f, 0.25f), new Color(0.9f, 0.55f, 0.4f), new Color(0.35f, 0.8f, 0.75f),
        };

        public const float PedestalHeight = 1f;
        public const float PedestalWidth = 0.9f;

        [SerializeField] string title;
        [SerializeField, TextArea(2, 4)] string description;
        [SerializeField] int biome;          // -1 はまだ作っていない作品 (仮の箱)
        [SerializeField] string place;
        [SerializeField] DioramaWork work;   // 作品専用のシェーダーで描くときの、仕掛けの係
        [SerializeField] string workName;
        [Tooltip("鑑賞モードでカメラが回る中心")]
        [SerializeField] Transform focus;
        [Tooltip("鑑賞モードを始めたときの、中心からカメラまでの距離")]
        [SerializeField] float viewDistance = 1.6f;
        [SerializeField] Renderer diorama;
        [SerializeField] Material textMaterial;

        public string Title => title;
        public string Description => description;
        public int Biome => biome;
        public Vector3 FocusPoint => focus != null ? focus.position : transform.position + Vector3.up * 1.4f;
        public float ViewDistance => viewDistance;
        public Renderer Diorama => diorama;
        public DioramaWork Work => work;

        // 組み立てに使う部品のまとめ
        public struct Parts
        {
            public Material pedestal;
            public Material placeholder;
            public Material plate;
            public Material diorama;     // 共通のジオラマ (MuseumDiorama) のマテリアル。空なら仮の箱
            public System.Func<string, Material> workMaterial; // 作品名 (work) から、作品専用のマテリアルを返す。なければ null
            public float dioramaSize;
            public Material text;
            public Font font;
            public float textScale;
        }

        void OnEnable()
        {
            if (!All.Contains(this)) All.Add(this);
            // シーンを開き直すとフォントのテクスチャが外れることがあるので、入れ直す
            CaptionText.Refresh(textMaterial, CaptionText.DefaultFont);
        }

        void OnDisable()
        {
            All.Remove(this);
        }

        // 台座・ジオラマ・キャプションを作る。stand の正面 (+z) が見る人のいる側
        public void Build(ExhibitSpec spec, Parts parts)
        {
            title = spec.title;
            description = spec.description;
            biome = Mathf.Clamp(spec.biome, -1, BiomeTints.Length - 1);
            place = spec.place;
            workName = spec.work;
            textMaterial = parts.text;

            MuseumGeometry.Box(transform, "Pedestal", Vector3.up * (PedestalHeight * 0.5f),
                new Vector3(PedestalWidth, PedestalHeight, PedestalWidth), parts.pedestal);

            BuildDiorama(parts);
            BuildCaption(parts);
        }

        void BuildDiorama(Parts parts)
        {
            float size = parts.dioramaSize;
            var block = new MaterialPropertyBlock();
            GameObject go;
            Material special = !string.IsNullOrEmpty(workName) && parts.workMaterial != null ? parts.workMaterial(workName) : null;
            if (special != null)
            {
                // 作品専用のシェーダー (例: NightShards/Diorama/Eruption) で描く。仕掛けは DioramaWork が動かす
                go = MuseumGeometry.Box(transform, "Diorama", Vector3.up * (PedestalHeight + size * 0.5f), Vector3.one * size, special);
                block.SetFloat("_Seed", SeedFromTitle(title));
                work = go.AddComponent<DioramaWork>();
                work.Setup(workName);
            }
            else if (parts.diorama != null && biome >= 0)
            {
                // ジオラマ: Cube の中を MuseumDiorama シェーダーが描く。
                // 作品ごとの違いは _Biome (種類) と _Seed (地形の形。作品名から決める) で渡す
                go = MuseumGeometry.Box(transform, "Diorama", Vector3.up * (PedestalHeight + size * 0.5f), Vector3.one * size, parts.diorama);
                block.SetFloat("_Biome", biome);
                block.SetFloat("_Seed", SeedFromTitle(title));
            }
            else
            {
                // まだジオラマがないときの仮の箱。バイオームの色を付けておく
                go = MuseumGeometry.Box(transform, "Placeholder", Vector3.up * (PedestalHeight + size * 0.5f), Vector3.one * size, parts.placeholder);
                go.transform.localRotation = Quaternion.Euler(0f, 20f, 0f);
                Color tint = biome >= 0 ? BiomeTints[biome] : new Color(0.85f, 0.82f, 0.76f);
                block.SetColor("_ColorA", tint);
                block.SetColor("_ColorB", tint * 0.8f);
            }
            diorama = go.GetComponent<Renderer>();
            diorama.SetPropertyBlock(block);

            focus = new GameObject("Focus").transform;
            focus.SetParent(transform, false);
            focus.localPosition = Vector3.up * (PedestalHeight + size * 0.5f);
            viewDistance = Mathf.Max(1.2f, size * 2f);
        }

        // 台座の正面に、少し上を向いたプレートを付けて、作品名・バイオーム・説明を書く
        void BuildCaption(Parts parts)
        {
            float s = parts.textScale;
            string body = CaptionText.Wrap(description, 18);
            int lines = string.IsNullOrEmpty(body) ? 0 : body.Split('\n').Length;

            const float width = 0.46f;
            float height = 0.11f + lines * 0.026f * s;

            // 台座の前の面 (z = +幅/2) の少し手前、高さ 0.8m あたり。
            // 文字は自分の +z 方向から読むので、180° 回して見る人のほうへ向け、15° 上に傾ける
            var caption = new GameObject("Caption").transform;
            caption.SetParent(transform, false);
            caption.localPosition = new Vector3(0f, PedestalHeight - 0.08f - height * 0.5f, PedestalWidth * 0.5f + 0.03f);
            caption.localRotation = Quaternion.Euler(15f, 180f, 0f);

            var plate = MuseumGeometry.Box(caption, "Plate", new Vector3(0f, 0f, 0.006f), new Vector3(width, height, 0.012f), parts.plate);
            DestroySafe(plate.GetComponent<Collider>()); // 薄い板に当たり判定はいらない

            float left = -width * 0.5f + 0.025f;
            float top = height * 0.5f - 0.02f;
            const float front = -0.002f; // 文字はプレートの面よりわずかに手前 (見る人の側) に置く
            var warm = new Color(1f, 0.96f, 0.88f);
            var dim = new Color(0.78f, 0.74f, 0.68f);
            CaptionText.Add(caption, "Title", title, new Vector3(left, top, front), 0.034f * s, warm, parts.font, parts.text);
            string medium = string.IsNullOrEmpty(place) ? "HLSL レイマーチング" : $"{place}　|　HLSL レイマーチング";
            CaptionText.Add(caption, "Medium", medium,
                new Vector3(left, top - 0.042f * s, front), 0.017f * s, dim, parts.font, parts.text);
            if (lines > 0)
                CaptionText.Add(caption, "Description", body, new Vector3(left, top - 0.072f * s, front), 0.02f * s, warm, parts.font, parts.text);
        }

        // 作品名から 0〜10 の数を作る。同じ名前なら毎回同じ形になる
        static float SeedFromTitle(string s)
        {
            if (string.IsNullOrEmpty(s)) return 0f;
            int h = 17;
            foreach (char c in s) h = h * 31 + c;
            return (h & 0xffff) / 6553.5f;
        }

        static void DestroySafe(Object o)
        {
            if (o == null) return;
            if (Application.isPlaying) Destroy(o);
            else DestroyImmediate(o);
        }
    }
}
