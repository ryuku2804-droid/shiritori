using System.Collections.Generic;
using UnityEngine;

namespace BlindSpot.EditorTools
{
    /// <summary>ステージに置く箱1つ分のデータ。</summary>
    public struct Placement
    {
        public string group;        // 親オブジェクトの名前 ("Walls" など)
        public string name;
        public Vector3 position;    // 箱の中心
        public float yaw;           // Y 軸まわりの回転 (度)
        public Vector3 size;        // 箱の大きさ (回転前の X・Y・Z)
        public string material;     // 見た目 (GrayboxRoomBuilder の色の表から選ぶ)
        public SurfaceType surface; // 床の素材。Default 以外なら SurfaceMaterial を付ける
    }

    /// <summary>
    /// 「どこに何を置くか」だけを持つデータ。Unity のオブジェクトは作らない。
    /// 実際に作るのは GrayboxRoomBuilder の仕事。
    /// </summary>
    public class StageLayout
    {
        public readonly string name;
        public Vector3 playerStart;
        public float playerYaw;
        public readonly List<Placement> blocks = new List<Placement>();

        public StageLayout(string name)
        {
            this.name = name;
        }

        // ---------------- まとめて置くヘルパー ----------------

        /// <summary>箱を1つ置く。基本の関数で、ほかのヘルパーはすべてこれを呼ぶ。</summary>
        public void Box(string group, string name, Vector3 center, Vector3 size, string material,
            float yaw = 0f, SurfaceType surface = SurfaceType.Default)
        {
            blocks.Add(new Placement
            {
                group = group,
                name = name,
                position = center,
                yaw = yaw,
                size = size,
                material = material,
                surface = surface,
            });
        }

        /// <summary>上面が高さ 0 になる床 (厚さ 0.2m)。</summary>
        public void Floor(string name, float x, float z, float width, float depth, string material = "Floor")
        {
            Box("Floors", name, new Vector3(x, -0.1f, z), new Vector3(width, 0.2f, depth), material);
        }

        /// <summary>床の上に敷く、素材の違う薄い板 (厚さ 2cm)。色は素材の名前で決まる。</summary>
        public void Patch(string name, float x, float z, float width, float depth, SurfaceType surface)
        {
            const float thickness = 0.02f;
            Box("Surfaces", name, new Vector3(x, thickness / 2f, z), new Vector3(width, thickness, depth),
                surface.ToString(), 0f, surface);
        }

        /// <summary>点 from から点 to まで (どちらも床の高さ) の壁。斜めでもよい。</summary>
        public void Wall(string name, Vector3 from, Vector3 to, float height, float thickness = 0.3f, string material = "Wall")
        {
            Vector3 d = to - from;
            float length = new Vector2(d.x, d.z).magnitude;
            float yaw = Mathf.Atan2(d.x, d.z) * Mathf.Rad2Deg; // 壁の長さ方向を Z に合わせる
            Vector3 center = (from + to) / 2f + Vector3.up * (height / 2f);
            Box("Walls", name, center, new Vector3(thickness, height, length), material, yaw);
        }

        /// <summary>床・天井・四方の壁で囲まれた部屋。(cx, cz) は部屋の中心。</summary>
        public void Room(string name, float cx, float cz, float width, float depth, float height, float wall = 0.3f)
        {
            Floor(name + "_Floor", cx, cz, width, depth);
            Box("Ceilings", name + "_Ceiling", new Vector3(cx, height + 0.1f, cz), new Vector3(width, 0.2f, depth), "Wall");

            // 壁は部屋の外側に置き、角がすき間なく閉じるように厚さ分だけ長くする
            float hx = width / 2f + wall / 2f;
            float hz = depth / 2f + wall / 2f;
            Wall(name + "_Wall_N", new Vector3(cx - hx - wall / 2f, 0, cz + hz), new Vector3(cx + hx + wall / 2f, 0, cz + hz), height, wall);
            Wall(name + "_Wall_S", new Vector3(cx - hx - wall / 2f, 0, cz - hz), new Vector3(cx + hx + wall / 2f, 0, cz - hz), height, wall);
            Wall(name + "_Wall_E", new Vector3(cx + hx, 0, cz - hz), new Vector3(cx + hx, 0, cz + hz), height, wall);
            Wall(name + "_Wall_W", new Vector3(cx - hx, 0, cz - hz), new Vector3(cx - hx, 0, cz + hz), height, wall);
        }

        /// <summary>床から天井までの柱。</summary>
        public void Pillar(string name, float x, float z, float size, float height)
        {
            Box("Obstacles", name, new Vector3(x, height / 2f, z), new Vector3(size, height, size), "Obstacle");
        }

        /// <summary>床に置く箱 (木箱・机など)。</summary>
        public void Crate(string name, float x, float z, Vector3 size, float yaw = 0f)
        {
            Box("Obstacles", name, new Vector3(x, size.y / 2f, z), size, "Obstacle", yaw);
        }

        /// <summary>
        /// しゃがまないと通れない低い通路。(x, z) は通路の中心、clearance は天板の下の高さ。
        /// 通路の上は roomHeight まで壁でふさぐ。
        /// </summary>
        public void LowPassage(string name, float x, float z, float width, float depth, float clearance, float roomHeight)
        {
            const float top = 0.2f;  // 天板の厚さ
            const float side = 0.2f; // 側板の厚さ
            float sideHeight = clearance + top;
            Box("Obstacles", name + "_Top", new Vector3(x, clearance + top / 2f, z), new Vector3(width, top, depth), "Obstacle");
            Box("Obstacles", name + "_Side_L", new Vector3(x - width / 2f - side / 2f, sideHeight / 2f, z), new Vector3(side, sideHeight, depth), "Obstacle");
            Box("Obstacles", name + "_Side_R", new Vector3(x + width / 2f + side / 2f, sideHeight / 2f, z), new Vector3(side, sideHeight, depth), "Obstacle");
            float upper = roomHeight - sideHeight;
            Box("Obstacles", name + "_Upper", new Vector3(x, sideHeight + upper / 2f, z), new Vector3(width + side * 2f, upper, 0.2f), "Obstacle");
        }
    }
}
