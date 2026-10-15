using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace NightShards.Museum
{
    // ジオラマの世界に入る。プレイヤーに付ける。
    //   入る: 作品をクリック → 画角が狭まりながら白く吸い込まれ、120 倍に拡大したジオラマの中の浜辺に立つ
    //   中:   WASD で歩ける (地面は DioramaTerrain で作った当たり判定)。クリックで仕掛け。ガラスの壁が世界の端
    //   出る: E か Esc → 暗転して、入る前にいた美術館の場所に戻る
    // 拡大したジオラマは、美術館から遠く離れた場所 (地下 3000m) に作るので、美術館とは重ならない
    public class DioramaWorld : MonoBehaviour
    {
        public FirstPersonController body;
        public ExhibitViewer viewer;
        public Camera viewCamera;

        [Tooltip("ジオラマを何倍に拡大した世界に入るか")]
        [SerializeField] float scale = 120f;
        [Tooltip("拡大したジオラマを置く場所 (美術館から遠く離す)")]
        [SerializeField] Vector3 origin = new Vector3(0f, -3000f, 0f);
        [Tooltip("歩く地面の当たり判定の細かさ (1 辺のます目の数)")]
        [SerializeField] int groundResolution = 160;
        [Tooltip("入るときの演出の秒数")] [SerializeField] float enterTime = 1.2f;
        [Tooltip("氷の上のすべりにくさ (0〜1)。小さいほどつるつる滑る")]
        [SerializeField, Range(0f, 1f)] float iceGrip = 0.08f;
        [Tooltip("出るときの演出の秒数")] [SerializeField] float exitTime = 0.8f;

        public bool InWorld { get; private set; }

        const float Inner = 0.47f; // ジオラマの地形がある範囲 (箱の中の、ガラスの内側)

        bool busy;
        GameObject world;
        DioramaWork worldWork;
        ExhibitStand source;
        Vector3 returnPosition;
        float returnYaw;
        float baseFov, baseFar;
        Vector3 spawnPosition;
        float spawnYaw;

        // 中に入れる作品か (作品専用のシェーダーと、歩ける地形の式がそろっているもの)
        public bool CanEnter(ExhibitStand stand)
        {
            return stand != null && stand.Diorama != null && stand.Work != null &&
                   DioramaTerrain.TryGet(stand.WorkName, stand.Seed, out _);
        }

        public void Enter(ExhibitStand stand)
        {
            if (busy || InWorld || !CanEnter(stand)) return;
            StartCoroutine(EnterRoutine(stand));
        }

        void Update()
        {
            if (!InWorld || busy) return;
            if (MuseumInput.ClickPressed && worldWork != null) worldWork.Trigger();
            if (MuseumInput.InteractPressed || MuseumInput.BackPressed) StartCoroutine(ExitRoutine());
            // 何かの拍子に世界の外へ落ちたら、浜辺に戻す
            if (body.transform.position.y < origin.y - scale) body.Teleport(spawnPosition, spawnYaw);
        }

        // ---------------------------------------------------------------- 入る

        IEnumerator EnterRoutine(ExhibitStand stand)
        {
            busy = true;
            source = stand;
            returnPosition = body.transform.position;
            returnYaw = body.transform.eulerAngles.y;
            body.InputEnabled = false;
            if (viewer.IsViewing) viewer.ZoomIn();

            // 吸い込まれる: 画角を狭めながら、白く光る
            baseFov = viewCamera.fieldOfView;
            yield return Animate(enterTime, k =>
            {
                viewCamera.fieldOfView = Mathf.Lerp(baseFov, 22f, k * k);
                SetFade(Color.white, k * k);
            });

            viewer.ResetToWalking();
            viewer.enabled = false;
            BuildWorld(stand);
            viewCamera.fieldOfView = baseFov;
            baseFar = viewCamera.farClipPlane;
            viewCamera.farClipPlane = scale * 3f;
            body.Teleport(spawnPosition, spawnYaw);

            InWorld = true;
            body.ManageCursor = false; // 世界の中では Esc を「戻る」に使うので、カーソルの出し入れはこちらで受け持つ
            FirstPersonController.SetCursorLocked(true);
            body.InputEnabled = true;
            if (MuseumHUD.Instance != null)
                MuseumHUD.Instance.Hint = $"{stand.Title} の中　　WASD  歩く　　クリック  仕掛け　　E / Esc  美術館に戻る";

            yield return Animate(enterTime, k => SetFade(Color.white, 1f - k));
            busy = false;
        }

        // ---------------------------------------------------------------- 出る

        IEnumerator ExitRoutine()
        {
            busy = true;
            body.InputEnabled = false;
            yield return Animate(exitTime, k => SetFade(Color.black, k));

            if (world != null) Destroy(world);
            world = null;
            worldWork = null;
            body.SurfaceGrip = null; // 美術館の床はふつうの地面
            viewCamera.farClipPlane = baseFar;
            body.Teleport(returnPosition, returnYaw);

            InWorld = false;
            viewer.enabled = true;
            body.ManageCursor = true;
            body.InputEnabled = true;
            if (MuseumHUD.Instance != null) MuseumHUD.Instance.Hint = "";

            yield return Animate(exitTime, k => SetFade(Color.black, 1f - k));
            busy = false;
        }

        // ---------------------------------------------------------------- 世界を作る

        void BuildWorld(ExhibitStand stand)
        {
            if (world != null) Destroy(world);
            world = new GameObject("Diorama World");
            world.transform.position = origin;

            // ジオラマと同じマテリアルの、大きな箱。カメラが箱の中にいても、シェーダーが中の景色を描く
            var cube = GameObject.CreatePrimitive(PrimitiveType.Cube);
            Destroy(cube.GetComponent<Collider>());
            cube.name = "World";
            cube.transform.SetParent(world.transform, false);
            cube.transform.localScale = Vector3.one * scale;
            var rend = cube.GetComponent<Renderer>();
            rend.sharedMaterial = stand.Diorama.sharedMaterial;
            rend.shadowCastingMode = UnityEngine.Rendering.ShadowCastingMode.Off;
            rend.receiveShadows = false;
            var block = new MaterialPropertyBlock();
            stand.Diorama.GetPropertyBlock(block); // 作品の形 (_Seed) を引き継ぐ
            block.SetFloat("_Steps", 180f);       // 中では遠くまで見えるので、いちばん細かく
            block.SetFloat("_ShadowSteps", 24f);
            block.SetFloat("_Event", 0f);
            rend.SetPropertyBlock(block);
            worldWork = cube.AddComponent<DioramaWork>();
            worldWork.Setup(stand.WorkName, spatialSound: false);

            DioramaTerrain.TryGet(stand.WorkName, stand.Seed, out var info);
            // 氷のある作品なら、足元が氷の上のときだけ、すべりやすくする
            if (info.icy != null)
            {
                var icy = info.icy;
                body.SurfaceGrip = pos =>
                {
                    Vector3 local = (pos - origin) / scale;
                    return icy(new Vector2(local.x, local.z)) ? iceGrip : 1f;
                };
            }
            BuildGround(info);
            BuildEdges(info);
            BuildProps(info);
            FindSpawn(info);
        }

        // 歩く地面: 地形の高さを格子状に調べて、当たり判定だけのメッシュを作る (目には見えない)。
        // 海の所は、水面のすぐ下を地面にして、浅瀬を歩いているようにする
        void BuildGround(DioramaTerrain.Info info)
        {
            int n = groundResolution;
            var verts = new List<Vector3>((n + 1) * (n + 1));
            var tris = new List<int>(n * n * 6);
            for (int j = 0; j <= n; j++)
            {
                for (int i = 0; i <= n; i++)
                {
                    float x = -Inner + 2f * Inner * i / n;
                    float z = -Inner + 2f * Inner * j / n;
                    float h = Mathf.Max(info.height(new Vector2(x, z)), info.water - 0.004f);
                    verts.Add(new Vector3(x, h, z) * scale);
                }
            }
            int row = n + 1;
            for (int j = 0; j < n; j++)
            {
                for (int i = 0; i < n; i++)
                {
                    int a = j * row + i, b = a + 1, c = a + row, d = c + 1;
                    tris.AddRange(new[] { a, c, b, b, c, d });
                }
            }
            var mesh = new Mesh { name = "World Ground" };
            mesh.indexFormat = UnityEngine.Rendering.IndexFormat.UInt32;
            mesh.SetVertices(verts);
            mesh.SetTriangles(tris, 0);
            mesh.RecalculateBounds();

            var ground = new GameObject("Ground");
            ground.transform.SetParent(world.transform, false);
            ground.AddComponent<MeshCollider>().sharedMesh = mesh;
        }

        // ぶつかる物: 鳥居の柱・灯籠・木の幹・家や社。見た目はシェーダーが描くので、当たり判定だけを置く
        void BuildProps(DioramaTerrain.Info info)
        {
            if (info.props == null) return;
            var holder = new GameObject("Props").transform;
            holder.SetParent(world.transform, false);
            foreach (var prop in info.props())
            {
                var go = new GameObject(prop.box ? "Box" : "Pillar");
                go.transform.SetParent(holder, false);
                go.transform.localPosition = prop.bottom * scale;
                if (prop.box)
                {
                    // シェーダーの向きの決め方 (x 軸が (cos, sin)) を、Unity の回転 (y 軸まわり) に直す
                    go.transform.localRotation = Quaternion.Euler(0f, -prop.yaw * Mathf.Rad2Deg, 0f);
                    go.AddComponent<BoxCollider>().size = prop.size * scale;
                }
                else
                {
                    var capsule = go.AddComponent<CapsuleCollider>();
                    capsule.direction = 1; // 縦
                    capsule.radius = prop.radius * scale;
                    capsule.height = (prop.height + prop.radius * 2f) * scale;
                    capsule.center = Vector3.up * (prop.height * 0.5f * scale);
                }
            }
        }

        // 世界の端: ガラスの内側に、見えない壁を 4 枚
        void BuildEdges(DioramaTerrain.Info info)
        {
            float half = Inner * scale;
            float height = scale;
            for (int k = 0; k < 4; k++)
            {
                var wall = new GameObject("Edge");
                wall.transform.SetParent(world.transform, false);
                var box = wall.AddComponent<BoxCollider>();
                bool alongX = k < 2;
                float side = (k % 2 == 0) ? 1f : -1f;
                wall.transform.localPosition = alongX ? new Vector3(0f, 0f, side * (half + 0.5f)) : new Vector3(side * (half + 0.5f), 0f, 0f);
                box.size = alongX ? new Vector3(half * 2f + 2f, height, 1f) : new Vector3(1f, height, half * 2f + 2f);
            }
        }

        // 立つ場所: 作品が決めていればそこ。決めていなければ、島の中心から手前 (+z、美術館で見ていた側) へ
        // まっすぐ進み、海に出る少し手前の浜辺。どちらも島 (火口) の中心を向く
        void FindSpawn(DioramaTerrain.Info info)
        {
            Vector2 spot = info.center + new Vector2(0f, 0.2f);
            for (float r = 0.08f; r < Inner && !info.hasSpawn; r += 0.002f)
            {
                Vector2 p = info.center + new Vector2(0f, r);
                if (info.height(p) < info.water + 0.008f)
                {
                    spot = info.center + new Vector2(0f, Mathf.Max(0.08f, r - 0.025f));
                    break;
                }
            }
            if (info.hasSpawn) spot = info.spawn;
            float h = Mathf.Max(info.height(spot), info.water);
            spawnPosition = origin + new Vector3(spot.x, h, spot.y) * scale + Vector3.up * 0.3f;
            Vector2 toCenter = info.center - spot;
            spawnYaw = Mathf.Atan2(toCenter.x, toCenter.y) * Mathf.Rad2Deg;
        }

        // ---------------------------------------------------------------- 演出の道具

        static IEnumerator Animate(float seconds, System.Action<float> step)
        {
            float t = 0f;
            while (t < seconds)
            {
                t += Time.deltaTime;
                float k = Mathf.Clamp01(t / seconds);
                step(k * k * (3f - 2f * k));
                yield return null;
            }
            step(1f);
        }

        static void SetFade(Color color, float alpha)
        {
            if (MuseumHUD.Instance == null) return;
            MuseumHUD.Instance.FadeColor = color;
            MuseumHUD.Instance.Fade = alpha;
        }
    }
}
