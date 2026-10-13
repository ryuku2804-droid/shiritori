using System.Collections.Generic;
using UnityEngine;

namespace NightShards.Museum
{
    // 中央のドームの形をメッシュで作る道具。Cube では作れない円や球の面を、頂点を並べて作る。
    // 角度は「北 (+z) が 0°、時計回り」。x = sin(角度)、z = cos(角度)
    public static class MuseumDome
    {
        // 床の円盤 (上向き)。uv はローカルの x, z (m)
        public static Mesh Disc(float radius, int segments)
        {
            var verts = new List<Vector3> { Vector3.zero };
            var uvs = new List<Vector2> { Vector2.zero };
            var tris = new List<int>();
            for (int i = 0; i <= segments; i++)
            {
                float a = i * Mathf.PI * 2f / segments;
                var p = new Vector3(Mathf.Sin(a), 0f, Mathf.Cos(a)) * radius;
                verts.Add(p);
                uvs.Add(new Vector2(p.x, p.z));
            }
            for (int i = 1; i <= segments; i++) tris.AddRange(new[] { 0, i, i + 1 });
            return Finish("Dome Floor", verts, uvs, tris, Vector3.up);
        }

        // 円筒の壁の内側の面 (中心を向く)。doorAngles の向き (度) には、幅 doorWidth・高さ doorHeight の出入口をあける。
        // uv.x は一周を 0〜1、uv.y は高さ (m)
        public static Mesh Drum(float radius, float height, IList<float> doorAngles, float doorWidth, float doorHeight, int segments)
        {
            float half = Mathf.Asin(Mathf.Clamp01(doorWidth * 0.5f / radius)) * Mathf.Rad2Deg;

            // 区切りの角度: 等間隔の角度に、出入口のちょうど端の角度を足して並べる
            var cuts = new List<float>();
            for (int i = 0; i <= segments; i++) cuts.Add(i * 360f / segments);
            foreach (float d in doorAngles)
            {
                cuts.Add(Mathf.Repeat(d - half, 360f));
                cuts.Add(Mathf.Repeat(d + half, 360f));
            }
            cuts.Sort();

            var verts = new List<Vector3>();
            var uvs = new List<Vector2>();
            var normals = new List<Vector3>();
            var tris = new List<int>();
            for (int i = 0; i < cuts.Count - 1; i++)
            {
                float a0 = cuts[i], a1 = cuts[i + 1];
                if (a1 - a0 < 1e-3f) continue;
                float mid = (a0 + a1) * 0.5f;
                bool door = false;
                foreach (float d in doorAngles)
                    if (Mathf.Abs(Mathf.DeltaAngle(mid, d)) < half) door = true;
                float y0 = door ? doorHeight : 0f; // 出入口の所は、上のまぐさの部分だけ
                AddWallQuad(verts, uvs, normals, tris, radius, a0, a1, y0, height);
            }
            var mesh = new Mesh { name = "Dome Drum" };
            mesh.SetVertices(verts);
            mesh.SetNormals(normals);
            mesh.SetUVs(0, uvs);
            mesh.SetTriangles(tris, 0);
            mesh.RecalculateBounds();
            return mesh;
        }

        static void AddWallQuad(List<Vector3> verts, List<Vector2> uvs, List<Vector3> normals, List<int> tris,
            float r, float a0, float a1, float y0, float y1)
        {
            int i = verts.Count;
            foreach (float y in new[] { y0, y1 })
            {
                foreach (float a in new[] { a0, a1 })
                {
                    float rad = a * Mathf.Deg2Rad;
                    var dir = new Vector3(Mathf.Sin(rad), 0f, Mathf.Cos(rad));
                    verts.Add(dir * r + Vector3.up * y);
                    normals.Add(-dir);
                    uvs.Add(new Vector2(a / 360f, y));
                }
            }
            // i: 下の a0 / i+1: 下の a1 / i+2: 上の a0 / i+3: 上の a1。中心から見て表になる向きに並べる
            tris.AddRange(new[] { i, i + 2, i + 1, i + 1, i + 2, i + 3 });
        }

        // 半球の天井の内側の面。baseY から始まり、てっぺんに半径 oculus の穴をあける。
        // uv.x は一周を 0〜1、uv.y は下の縁が 0・天窓の縁が 1 (格天井の模様に使う)
        public static Mesh Dome(float radius, float baseY, float oculus, int segments, int rings)
        {
            float phiMax = Mathf.Acos(Mathf.Clamp01(oculus / radius));
            var verts = new List<Vector3>();
            var uvs = new List<Vector2>();
            var normals = new List<Vector3>();
            var tris = new List<int>();
            for (int j = 0; j <= rings; j++)
            {
                float v = (float)j / rings;
                float phi = v * phiMax;
                for (int i = 0; i <= segments; i++)
                {
                    float u = (float)i / segments;
                    float a = u * Mathf.PI * 2f;
                    var n = new Vector3(Mathf.Cos(phi) * Mathf.Sin(a), Mathf.Sin(phi), Mathf.Cos(phi) * Mathf.Cos(a));
                    verts.Add(n * radius + Vector3.up * baseY);
                    normals.Add(-n);
                    uvs.Add(new Vector2(u, v));
                }
            }
            int row = segments + 1;
            for (int j = 0; j < rings; j++)
            {
                for (int i = 0; i < segments; i++)
                {
                    int a = j * row + i, b = a + 1, c = a + row, d = c + 1;
                    tris.AddRange(new[] { a, c, b, b, c, d });
                }
            }
            var mesh = new Mesh { name = "Dome Ceiling" };
            mesh.indexFormat = UnityEngine.Rendering.IndexFormat.UInt32;
            mesh.SetVertices(verts);
            mesh.SetNormals(normals);
            mesh.SetUVs(0, uvs);
            mesh.SetTriangles(tris, 0);
            mesh.RecalculateBounds();
            return mesh;
        }

        // 天窓から床へ落ちる光の柱 (上が細く下が少し広い筒)。uv.y は上が 0・床が 1
        public static Mesh LightShaft(float topRadius, float bottomRadius, float height, int segments)
        {
            var verts = new List<Vector3>();
            var uvs = new List<Vector2>();
            var tris = new List<int>();
            for (int i = 0; i <= segments; i++)
            {
                float u = (float)i / segments;
                float a = u * Mathf.PI * 2f;
                var dir = new Vector3(Mathf.Sin(a), 0f, Mathf.Cos(a));
                verts.Add(dir * topRadius + Vector3.up * height);
                verts.Add(dir * bottomRadius);
                uvs.Add(new Vector2(u, 0f));
                uvs.Add(new Vector2(u, 1f));
            }
            for (int i = 0; i < segments; i++)
            {
                int a = i * 2;
                tris.AddRange(new[] { a, a + 2, a + 1, a + 1, a + 2, a + 3 });
            }
            var mesh = new Mesh { name = "Light Shaft" };
            mesh.SetVertices(verts);
            mesh.SetUVs(0, uvs);
            mesh.SetTriangles(tris, 0);
            mesh.RecalculateNormals();
            mesh.RecalculateBounds();
            return mesh;
        }

        static Mesh Finish(string name, List<Vector3> verts, List<Vector2> uvs, List<int> tris, Vector3 normal)
        {
            var mesh = new Mesh { name = name };
            mesh.SetVertices(verts);
            mesh.SetUVs(0, uvs);
            var normals = new List<Vector3>();
            for (int i = 0; i < verts.Count; i++) normals.Add(normal);
            mesh.SetNormals(normals);
            mesh.SetTriangles(tris, 0);
            mesh.RecalculateBounds();
            return mesh;
        }

        // メッシュを1つの物として置く。collider = true なら当たり判定も付ける
        public static GameObject Place(Transform parent, string name, Mesh mesh, Material mat, Vector3 localPos, bool collider)
        {
            var go = new GameObject(name);
            go.transform.SetParent(parent, false);
            go.transform.localPosition = localPos;
            go.AddComponent<MeshFilter>().sharedMesh = mesh;
            go.AddComponent<MeshRenderer>().sharedMaterial = mat;
            if (collider) go.AddComponent<MeshCollider>().sharedMesh = mesh;
            return go;
        }
    }
}
