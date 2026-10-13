using System.Collections.Generic;
using UnityEngine;

namespace NightShards.Museum
{
    // 壁にあける開口 (出入口)。u は壁の始点からの距離 (開口の中心)
    public struct Opening
    {
        public float u;
        public float width;
        public float height;

        public Opening(float u, float width, float height)
        {
            this.u = u;
            this.width = width;
            this.height = height;
        }
    }

    // 床・壁・天井を Cube の組み合わせで作る道具。Cube には最初から BoxCollider が付いているので、
    // CharacterController はそのまま壁をすり抜けない
    public static class MuseumGeometry
    {
        public const float SlabThickness = 0.2f;

        // 中心と大きさを指定して箱を1つ置く (座標は parent から見たローカル)
        public static GameObject Box(Transform parent, string name, Vector3 center, Vector3 size, Material mat)
        {
            var go = GameObject.CreatePrimitive(PrimitiveType.Cube);
            go.name = name;
            go.transform.SetParent(parent, false);
            go.transform.localPosition = center;
            go.transform.localScale = size;
            go.GetComponent<Renderer>().sharedMaterial = mat;
            return go;
        }

        // 方向 f に沿った長さ・高さ・f と直角の長さから、x/y/z の大きさを作る
        public static Vector3 Size(Vector3 f, float alongF, float y, float acrossF)
        {
            return Mathf.Abs(f.x) > 0.5f ? new Vector3(alongF, y, acrossF) : new Vector3(acrossF, y, alongF);
        }

        // 方向の単位ベクトル (North = +z)
        public static Vector3 Forward(RoomDirection d)
        {
            switch (d)
            {
                case RoomDirection.North: return Vector3.forward;
                case RoomDirection.East: return Vector3.right;
                case RoomDirection.South: return Vector3.back;
                default: return Vector3.left;
            }
        }

        public static RoomDirection Opposite(RoomDirection d)
        {
            return (RoomDirection)(((int)d + 2) % 4);
        }

        // 床の高さ 0 に立つ壁を、a から b まで (x 軸か z 軸に平行) 作る。開口の部分は抜いて、上にまぐさを置く
        public static void Wall(Transform parent, string name, Vector3 a, Vector3 b, float thickness, float height,
            List<Opening> openings, Material mat)
        {
            Vector3 dir = b - a;
            float len = dir.magnitude;
            dir /= len;
            bool alongX = Mathf.Abs(dir.x) > 0.5f;

            var root = new GameObject(name).transform;
            root.SetParent(parent, false);

            void Segment(float u0, float u1, float y0, float y1)
            {
                if (u1 - u0 < 0.001f || y1 - y0 < 0.001f) return;
                Vector3 mid = a + dir * ((u0 + u1) * 0.5f) + Vector3.up * ((y0 + y1) * 0.5f);
                Vector3 size = alongX ? new Vector3(u1 - u0, y1 - y0, thickness) : new Vector3(thickness, y1 - y0, u1 - u0);
                Box(root, "Segment", mid, size, mat);
            }

            var sorted = new List<Opening>(openings ?? new List<Opening>());
            sorted.Sort((p, q) => p.u.CompareTo(q.u));

            float cursor = 0f;
            foreach (var op in sorted)
            {
                float s = Mathf.Clamp(op.u - op.width * 0.5f, 0f, len);
                float e = Mathf.Clamp(op.u + op.width * 0.5f, 0f, len);
                Segment(cursor, s, 0f, height);         // 開口の手前の壁
                Segment(s, e, op.height, height);       // 開口の上のまぐさ
                cursor = Mathf.Max(cursor, e);
            }
            Segment(cursor, len, 0f, height);           // 最後の開口から端まで
        }

        // 長方形の部屋 (床・天井・4面の壁) を作る。center と sizeX/sizeZ は内側の寸法。
        // 壁は内側の寸法の外に立てるので、部屋の中の広さは指定どおりになる。
        // doors には「どの面の、どの位置 (x か z の座標) に開口をあけるか」を入れる
        public static Transform Room(Transform parent, string name, Vector3 center, float sizeX, float sizeZ,
            float height, float t, Dictionary<RoomDirection, List<float>> doors, float doorWidth, float doorHeight,
            Material floor, Material wall, Material ceiling)
        {
            var root = new GameObject(name).transform;
            root.SetParent(parent, false);

            Box(root, "Floor", center + Vector3.down * (SlabThickness * 0.5f), new Vector3(sizeX, SlabThickness, sizeZ), floor);
            Box(root, "Ceiling", center + Vector3.up * (height + SlabThickness * 0.5f),
                new Vector3(sizeX + 2f * t, SlabThickness, sizeZ + 2f * t), ceiling);

            float hx = sizeX * 0.5f, hz = sizeZ * 0.5f;
            Vector3 c = new Vector3(center.x, 0f, center.z);

            // 南北の壁は角まで覆う (x 方向に t ずつ長い)。東西の壁はその内側に収まる
            BuildSide(RoomDirection.North, c + new Vector3(-hx - t, 0f, hz + t * 0.5f), c + new Vector3(hx + t, 0f, hz + t * 0.5f));
            BuildSide(RoomDirection.South, c + new Vector3(-hx - t, 0f, -hz - t * 0.5f), c + new Vector3(hx + t, 0f, -hz - t * 0.5f));
            BuildSide(RoomDirection.East, c + new Vector3(hx + t * 0.5f, 0f, -hz), c + new Vector3(hx + t * 0.5f, 0f, hz));
            BuildSide(RoomDirection.West, c + new Vector3(-hx - t * 0.5f, 0f, -hz), c + new Vector3(-hx - t * 0.5f, 0f, hz));

            void BuildSide(RoomDirection side, Vector3 a, Vector3 b)
            {
                var ops = new List<Opening>();
                if (doors != null && doors.TryGetValue(side, out var list))
                {
                    bool alongX = side == RoomDirection.North || side == RoomDirection.South;
                    foreach (float worldPos in list)
                        ops.Add(new Opening(worldPos - (alongX ? a.x : a.z), doorWidth, doorHeight));
                }
                Wall(root, "Wall_" + side, a, b, t, height, ops, wall);
            }

            return root;
        }
    }
}
