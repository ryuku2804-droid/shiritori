using System.Collections.Generic;
using UnityEngine;

namespace NightShards.Museum
{
    // 美術館を組み立てる本体。組み立て方は2通りある:
    //   1. メニュー Tools > Diorama Museum > 美術館を組み立てる  → 編集中のシーンに建物ができる (Scene ビューで見られる)
    //   2. このコンポーネントだけを置いて再生                     → 建物がなければ、再生したときに組み立てる
    // プレイヤー (カメラ) と画面表示は、どちらの場合も再生したときに作る
    public class MuseumBuilder : MonoBehaviour
    {
        [SerializeField] MuseumLayout layout = MuseumLayout.CreateDefault();

        [Tooltip("空なら Shader.Find で探す。ビルドに入れるときはここに MuseumSurface を入れておく")]
        [SerializeField] Shader surfaceShader;

        [Tooltip("Tools メニューで組み立てると、保存したマテリアルがここに入る")]
        [SerializeField] MuseumMaterials materials = new MuseumMaterials();

        [Tooltip("シーンにもとからある Directional Light を止め、再生中は元の Main Camera も止める (暗い館内にするため)")]
        [SerializeField] bool takeOverScene = true;

        [Header("空気感")]
        [SerializeField] Color ambient = new Color(0.025f, 0.025f, 0.03f);
        [SerializeField] Color fogColor = new Color(0.01f, 0.01f, 0.012f);
        [SerializeField] float fogDensity = 0.035f;

        // 組み立てた建物の親。Tools メニューで組み立てた場合は、シーンに保存されている
        [SerializeField, HideInInspector] Transform root;
        [SerializeField, HideInInspector] List<Transform> exhibitAnchors = new List<Transform>();

        public MuseumLayout Layout => layout;
        public Shader SurfaceShader => surfaceShader;
        public MuseumMaterials Materials => materials;
        public Transform Root => root;
        public FirstPersonController Player { get; private set; }

        // 台座の上の位置 (段階2でここにジオラマを置く)
        public IReadOnlyList<Transform> ExhibitAnchors => exhibitAnchors;

        public const string RootName = "Museum (Generated)";

        void Reset()
        {
            layout = MuseumLayout.CreateDefault();
        }

        void Awake()
        {
            if (root == null) Build();
            else ApplyEnvironment();

            if (takeOverScene)
                foreach (var cam in FindObjectsByType<Camera>(FindObjectsSortMode.None))
                    cam.gameObject.SetActive(false);

            // 1つの物体に効かせられるライトの数。床や壁は大きいので、少し増やしておく
            QualitySettings.pixelLightCount = Mathf.Max(QualitySettings.pixelLightCount, 8);

            CreatePlayer();
            gameObject.AddComponent<MuseumHUD>();
        }

        // ---------------------------------------------------------------- 組み立て・片付け

        // 建物をすべて作り直す。編集中にも再生中にも呼べる
        public void Build()
        {
            Clear();
            ApplyEnvironment();
            materials.FillMissing(MuseumMaterials.FindShader(surfaceShader));

            root = new GameObject(RootName).transform;
            root.SetParent(transform, false);
            exhibitAnchors.Clear();

            BuildHallAndRooms();
        }

        // 組み立てた建物を消す
        public void Clear()
        {
            if (root != null)
            {
                if (Application.isPlaying) Destroy(root.gameObject);
                else DestroyImmediate(root.gameObject);
            }
            root = null;
            exhibitAnchors.Clear();
        }

        // 暗く静かな館内にする。空の光は使わず、ほぼ黒の環境光と、黒い霧で奥を沈める
        public void ApplyEnvironment()
        {
            if (takeOverScene)
                foreach (var l in FindObjectsByType<Light>(FindObjectsSortMode.None))
                    if (l.type == LightType.Directional) l.gameObject.SetActive(false);

            RenderSettings.skybox = null;
            RenderSettings.ambientMode = UnityEngine.Rendering.AmbientMode.Flat;
            RenderSettings.ambientLight = ambient;
            RenderSettings.reflectionIntensity = 0.15f;
            RenderSettings.fog = true;
            RenderSettings.fogMode = FogMode.ExponentialSquared;
            RenderSettings.fogColor = fogColor;
            RenderSettings.fogDensity = fogDensity;
        }

        Material FloorFor(RoomTheme theme)
        {
            switch (theme)
            {
                case RoomTheme.Dusk: return materials.wood;
                case RoomTheme.Sea: return materials.paleStone;
                default: return materials.darkStone;
            }
        }

        // ---------------------------------------------------------------- 建物

        void BuildHallAndRooms()
        {
            float t = layout.wallThickness;
            float cw = layout.corridorWidth, ch = layout.corridorHeight, cl = layout.corridorLength;
            Vector3 hall = layout.hallSize;

            if (cl < 2f * t + 0.5f) Debug.LogWarning("[Museum] 通路が短すぎます。corridorLength を壁の厚さの2倍より長くしてください。");

            // 1方向に1室まで。重なった部屋は飛ばす
            var used = new HashSet<RoomDirection>();
            var rooms = new List<RoomSpec>();
            foreach (var room in layout.rooms)
            {
                if (!used.Add(room.direction))
                {
                    Debug.LogWarning($"[Museum] 「{room.name}」は {room.direction} 向きが重なっているので置きません。");
                    continue;
                }
                rooms.Add(room);
            }

            // 中央ホール。部屋のある面に出入口をあける
            var hallDoors = new Dictionary<RoomDirection, List<float>>();
            foreach (var room in rooms) hallDoors[room.direction] = new List<float> { 0f };
            MuseumGeometry.Room(root, "Hall", Vector3.zero, hall.x, hall.z, hall.y, t, hallDoors, cw, ch,
                materials.darkStone, materials.concreteWall, materials.concreteCeiling);
            AddLight(root, "Hall Light", new Vector3(0f, hall.y - 0.2f, 0f), LightType.Spot,
                new Color(0.8f, 0.86f, 1f), 1.4f, hall.y + 3f, 75f, false);

            foreach (var room in rooms) BuildWing(room, hall, t, cw, ch, cl);
        }

        // 通路と展示室を1組作る
        void BuildWing(RoomSpec room, Vector3 hall, float t, float cw, float ch, float cl)
        {
            Vector3 f = MuseumGeometry.Forward(room.direction);
            Vector3 r = new Vector3(f.z, 0f, -f.x); // f から見て右
            float hallHalf = Mathf.Abs(f.x) > 0.5f ? hall.x * 0.5f : hall.z * 0.5f;
            var wing = new GameObject("Wing_" + room.name).transform;
            wing.SetParent(root, false);

            // 通路: 床はホールの内側の端から部屋の内側の端まで、天井と横壁は両側の壁の外側の面の間
            float inner = cl - 2f * t;
            Vector3 mid = f * (hallHalf + cl * 0.5f);
            MuseumGeometry.Box(wing, "Corridor Floor", mid + Vector3.down * (MuseumGeometry.SlabThickness * 0.5f),
                MuseumGeometry.Size(f, cl, MuseumGeometry.SlabThickness, cw), materials.wood);
            MuseumGeometry.Box(wing, "Corridor Ceiling", mid + Vector3.up * (ch + MuseumGeometry.SlabThickness * 0.5f),
                MuseumGeometry.Size(f, inner, MuseumGeometry.SlabThickness, cw + 2f * t), materials.concreteCeiling);
            for (int side = -1; side <= 1; side += 2)
            {
                Vector3 c = mid + r * (side * (cw * 0.5f + t * 0.5f)) + Vector3.up * (ch * 0.5f);
                MuseumGeometry.Box(wing, "Corridor Wall", c, MuseumGeometry.Size(f, inner, ch, t), materials.concreteWall);
            }
            // 通路の奥に部屋の色の光。ホールから見ると、入口ごとに違う色が漏れて見える
            AddLight(wing, "Corridor Glow", f * (hallHalf + cl - 1f) + Vector3.up * (ch - 0.5f), LightType.Point,
                room.accent, 1.3f, 6f, 0f, false);

            // 展示室
            float near = hallHalf + cl; // 部屋の内側の手前の端
            Vector3 center = f * (near + room.depth * 0.5f);
            bool alongZ = Mathf.Abs(f.z) > 0.5f;
            float sizeX = alongZ ? room.width : room.depth;
            float sizeZ = alongZ ? room.depth : room.width;
            var doors = new Dictionary<RoomDirection, List<float>>
            {
                { MuseumGeometry.Opposite(room.direction), new List<float> { 0f } },
            };
            var roomRoot = MuseumGeometry.Room(wing, "Room", center, sizeX, sizeZ, room.height, t, doors, cw, ch,
                FloorFor(room.theme), materials.concreteWall, materials.concreteCeiling);
            AddLight(roomRoot, "Room Fill", center + Vector3.up * (room.height * 0.75f), LightType.Point,
                room.accent, 0.5f, Mathf.Max(room.width, room.depth), 0f, false);

            BuildExhibits(room, roomRoot, f, r, near);
        }

        // 部屋の幅いっぱいに、等間隔で台座を並べる。台座は入口のほうを向く
        void BuildExhibits(RoomSpec room, Transform parent, Vector3 f, Vector3 r, float near)
        {
            int n = room.exhibits.Count;
            for (int i = 0; i < n; i++)
            {
                var spec = room.exhibits[i];
                float across = -room.width * 0.5f + room.width * (i + 1) / (n + 1);
                Vector3 pos = f * (near + room.depth * 0.55f) + r * across;

                var stand = new GameObject("Exhibit_" + spec.title).transform;
                stand.SetParent(parent, false);
                stand.localPosition = pos;
                stand.localRotation = Quaternion.LookRotation(-f);

                MuseumGeometry.Box(stand, "Pedestal", Vector3.up * 0.5f, new Vector3(0.9f, 1f, 0.9f), materials.pedestal);
                // 段階2で本物のジオラマに差し替える仮の箱
                var placeholder = MuseumGeometry.Box(stand, "Placeholder", Vector3.up * 1.35f, Vector3.one * 0.7f, materials.placeholder);
                placeholder.transform.localRotation = Quaternion.Euler(0f, 20f, 0f);

                var anchor = new GameObject("Anchor").transform;
                anchor.SetParent(stand, false);
                anchor.localPosition = Vector3.up * 1f;
                exhibitAnchors.Add(anchor);

                // 台座の真上から落とすスポットライト。床に光だまりができる
                AddLight(stand, "Spot", Vector3.up * (room.height - 0.25f), LightType.Spot,
                    new Color(1f, 0.94f, 0.84f), 4f, room.height + 2f, 34f, layout.spotShadows);
            }
        }

        Light AddLight(Transform parent, string name, Vector3 localPos, LightType type, Color color,
            float intensity, float range, float spotAngle, bool shadows)
        {
            var go = new GameObject(name);
            go.transform.SetParent(parent, false);
            go.transform.localPosition = localPos;
            // スポットは真下に向ける (親が回っていても下を向くように、ワールドで指定する)
            if (type == LightType.Spot) go.transform.rotation = Quaternion.Euler(90f, 0f, 0f);

            var l = go.AddComponent<Light>();
            l.type = type;
            l.color = color;
            l.intensity = intensity;
            l.range = range;
            if (type == LightType.Spot) l.spotAngle = spotAngle;
            l.shadows = shadows ? LightShadows.Soft : LightShadows.None;
            l.shadowStrength = 0.85f;
            return l;
        }

        // ---------------------------------------------------------------- プレイヤー

        void CreatePlayer()
        {
            Vector3 hall = layout.hallSize;
            var go = new GameObject("Player");
            go.transform.SetParent(transform, false);
            go.transform.localPosition = new Vector3(0f, 0.05f, -hall.z * 0.5f + 2f); // ホールの南の壁ぎわで、北を向いて立つ
            go.transform.localRotation = Quaternion.identity;

            var cc = go.AddComponent<CharacterController>();
            cc.height = 1.8f;
            cc.radius = 0.35f;
            cc.center = new Vector3(0f, 0.9f, 0f);
            cc.stepOffset = 0.3f;
            cc.skinWidth = 0.04f;

            var pivot = new GameObject("Camera Pivot").transform;
            pivot.SetParent(go.transform, false);
            pivot.localPosition = new Vector3(0f, 1.65f, 0f);

            var camGo = new GameObject("Main Camera");
            camGo.tag = "MainCamera";
            camGo.transform.SetParent(pivot, false);
            var cam = camGo.AddComponent<Camera>();
            cam.clearFlags = CameraClearFlags.SolidColor;
            cam.backgroundColor = Color.black;
            cam.nearClipPlane = 0.05f;
            cam.farClipPlane = 200f;
            cam.fieldOfView = 70f;
            camGo.AddComponent<AudioListener>();

            Player = go.AddComponent<FirstPersonController>();
            Player.cameraPivot = pivot;
        }
    }
}
