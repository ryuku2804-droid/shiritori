using System.Collections.Generic;
using UnityEngine;

namespace NightShards.Museum
{
    // 月の間の、天井から下がる光の糸。細い板を X 字に2枚組んだものを、まとめて1つのメッシュにする。
    // 糸の下端は頭より上 (2.4m 以上) なので、ぶつからない。作品の真上は避ける
    [ExecuteAlways]
    [RequireComponent(typeof(MeshFilter), typeof(MeshRenderer))]
    public class LightThreads : MonoBehaviour
    {
        [SerializeField] int count = 80;
        [Tooltip("糸を散らす広さ (x: 左右、y: 奥行き、m)")]
        [SerializeField] Vector2 area = new Vector2(10f, 8f);
        [Tooltip("天井の高さ (m)。糸はここから下がる")]
        [SerializeField] float ceiling = 6f;
        [Tooltip("糸の下端の高さの範囲 (m)")]
        [SerializeField] Vector2 bottomRange = new Vector2(2.4f, 4.8f);
        [SerializeField] float width = 0.014f;
        [SerializeField] int seed = 7;
        [Tooltip("この点のまわり (avoidRadius m) には糸を下げない。作品の位置を入れる")]
        [SerializeField] List<Vector3> avoid = new List<Vector3>();
        [SerializeField] float avoidRadius = 1.1f;

        public void Setup(Vector2 area, float ceiling, List<Vector3> avoid)
        {
            this.area = area;
            this.ceiling = ceiling;
            this.avoid = avoid;
            Rebuild();
        }

        // シーンを開き直したときなど、メッシュがなければ作り直す
        void OnEnable()
        {
            var filter = GetComponent<MeshFilter>();
            if (filter.sharedMesh == null) Rebuild();
        }

        public void Rebuild()
        {
            var random = new System.Random(seed);
            float Rand(float a, float b) => a + (float)random.NextDouble() * (b - a);

            var verts = new List<Vector3>();
            var uvs = new List<Vector2>();
            var colors = new List<Color>();
            var tris = new List<int>();

            int placed = 0;
            for (int tries = 0; placed < count && tries < count * 20; tries++)
            {
                var foot = new Vector3(Rand(-area.x, area.x) * 0.5f, 0f, Rand(-area.y, area.y) * 0.5f);
                bool blocked = false;
                foreach (var a in avoid)
                {
                    if (new Vector2(foot.x - a.x, foot.z - a.z).magnitude < avoidRadius) { blocked = true; break; }
                }
                if (blocked) continue;

                float bottom = Rand(bottomRange.x, bottomRange.y);
                var color = new Color(Rand(0f, 1f), 0f, 0f, 1f); // r: 光の粒の流れをずらす乱数 (シェーダーが読む)
                float angle = Rand(0f, 180f);
                AddCross(foot, bottom, angle, color);
                placed++;
            }

            var mesh = new Mesh { name = "Light Threads" };
            mesh.SetVertices(verts);
            mesh.SetUVs(0, uvs);
            mesh.SetColors(colors);
            mesh.SetTriangles(tris, 0);
            mesh.RecalculateNormals();
            mesh.RecalculateBounds();
            GetComponent<MeshFilter>().sharedMesh = mesh;

            // 1本ぶん: 向きを変えた細い板を2枚。uv.y は上が 0、下が 1
            void AddCross(Vector3 foot, float bottom, float angle, Color color)
            {
                for (int k = 0; k < 2; k++)
                {
                    Vector3 side = Quaternion.Euler(0f, angle + k * 90f, 0f) * Vector3.right * (width * 0.5f);
                    int i = verts.Count;
                    verts.Add(new Vector3(foot.x, ceiling, foot.z) - side);
                    verts.Add(new Vector3(foot.x, ceiling, foot.z) + side);
                    verts.Add(new Vector3(foot.x, bottom, foot.z) - side);
                    verts.Add(new Vector3(foot.x, bottom, foot.z) + side);
                    uvs.Add(new Vector2(0f, 0f));
                    uvs.Add(new Vector2(1f, 0f));
                    uvs.Add(new Vector2(0f, 1f));
                    uvs.Add(new Vector2(1f, 1f));
                    for (int c = 0; c < 4; c++) colors.Add(color);
                    tris.AddRange(new[] { i, i + 2, i + 1, i + 1, i + 2, i + 3 });
                }
            }
        }
    }
}
