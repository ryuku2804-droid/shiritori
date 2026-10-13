using System.Collections.Generic;
using UnityEngine;

namespace NightShards.Museum
{
    // 空のシーンにこれ1つを置いて再生すると、美術館が丸ごと組み上がる。
    // 段階1: 中央ホール・通路・展示室・台座 (仮)・照明・プレイヤー・画面表示
    public class MuseumBuilder : MonoBehaviour
    {
        [SerializeField] MuseumLayout layout = MuseumLayout.CreateDefault();

        [Tooltip("空なら Shader.Find で探す。ビルドに入れるときはここに MuseumSurface を入れておく")]
        [SerializeField] Shader surfaceShader;

        [Tooltip("シーンにもとからある Main Camera と Directional Light を止める (暗い館内にするため)")]
        [SerializeField] bool takeOverScene = true;

        [Header("空気感")]
        [SerializeField] Color ambient = new Color(0.025f, 0.025f, 0.03f);
        [SerializeField] Color fogColor = new Color(0.01f, 0.01f, 0.012f);
        [SerializeField] float fogDensity = 0.035f;

        public Transform Root { get; private set; }
        public FirstPersonController Player { get; private set; }

        // 台座の上の位置 (段階2でここにジオラマを置く)
        public readonly List<Transform> ExhibitAnchors = new List<Transform>();

        Material concreteWall, concreteCeiling, darkStone, paleStone, wood, pedestalMat, placeholderMat;

        void Reset()
        {
            layout = MuseumLayout.CreateDefault();
        }

        void Awake()
        {
            SetupEnvironment();
            CreateMaterials();

            Root = new GameObject("Museum").transform;
            Root.SetParent(transform, false);

            BuildHallAndRooms();
            CreatePlayer();
            gameObject.AddComponent<MuseumHUD>();
        }

        // ---------------------------------------------------------------- 環境

        void SetupEnvironment()
        {
            if (takeOverScene)
            {
                foreach (var l in FindObjectsByType<Light>(FindObjectsSortMode.None))
                    if (l.type == LightType.Directional) l.gameObject.SetActive(false);
                foreach (var cam in FindObjectsByType<Camera>(FindObjectsSortMode.None))
                    cam.gameObject.SetActive(false);
            }

            // 暗く静かな館内。空の光は使わず、ほぼ黒の環境光と、黒い霧で奥を沈める
            RenderSettings.skybox = null;
            RenderSettings.ambientMode = UnityEngine.Rendering.AmbientMode.Flat;
            RenderSettings.ambientLight = ambient;
            RenderSettings.reflectionIntensity = 0.15f;
            RenderSettings.fog = true;
            RenderSettings.fogMode = FogMode.ExponentialSquared;
            RenderSettings.fogColor = fogColor;
            RenderSettings.fogDensity = fogDensity;

            // 1つの物体に効かせられるライトの数。床や壁は大きいので、少し増やしておく
            QualitySettings.pixelLightCount = Mathf.Max(QualitySettings.pixelLightCount, 8);
        }

        void CreateMaterials()
        {
            if (surfaceShader == null) surfaceShader = Shader.Find("NightShards/MuseumSurface");
            if (surfaceShader == null)
            {
                Debug.LogError("[Museum] シェーダー NightShards/MuseumSurface が見つかりません。MuseumSurface.shader を Assets に入れてください。");
                surfaceShader = Shader.Find("Standard");
            }

            // 種類: 0 コンクリート / 1 木 / 2 石 / 3 漆喰
            concreteWall = MakeMat("Concrete Wall", 0, new Color(0.46f, 0.45f, 0.43f), new Color(0.34f, 0.33f, 0.32f), 0.18f);
            concreteCeiling = MakeMat("Concrete Ceiling", 0, new Color(0.22f, 0.22f, 0.22f), new Color(0.15f, 0.15f, 0.16f), 0.1f);
            darkStone = MakeMat("Dark Stone", 2, new Color(0.07f, 0.07f, 0.08f), new Color(0.13f, 0.13f, 0.14f), 0.78f);
            paleStone = MakeMat("Pale Stone", 2, new Color(0.62f, 0.62f, 0.6f), new Color(0.5f, 0.5f, 0.49f), 0.6f);
            wood = MakeMat("Wood", 1, new Color(0.36f, 0.22f, 0.13f), new Color(0.22f, 0.12f, 0.07f), 0.45f);
            pedestalMat = MakeMat("Pedestal", 3, new Color(0.05f, 0.05f, 0.055f), new Color(0.08f, 0.08f, 0.085f), 0.35f);
            placeholderMat = MakeMat("Placeholder", 3, new Color(0.8f, 0.8f, 0.78f), new Color(0.7f, 0.7f, 0.68f), 0.1f);
        }

        Material MakeMat(string name, int kind, Color a, Color b, float smoothness)
        {
            var m = new Material(surfaceShader) { name = name };
            m.SetFloat("_Kind", kind);
            m.SetColor("_ColorA", a);
            m.SetColor("_ColorB", b);
            m.SetFloat("_Smoothness", smoothness);
            if (m.HasProperty("_Color")) m.SetColor("_Color", a); // Standard で代用したとき用
            return m;
        }

        Material FloorFor(RoomTheme theme)
        {
            switch (theme)
            {
                case RoomTheme.Dusk: return wood;
                case RoomTheme.Sea: return paleStone;
                default: return darkStone;
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
            MuseumGeometry.Room(Root, "Hall", Vector3.zero, hall.x, hall.z, hall.y, t, hallDoors, cw, ch,
                darkStone, concreteWall, concreteCeiling);
            AddLight(Root, "Hall Light", new Vector3(0f, hall.y - 0.2f, 0f), LightType.Spot,
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
            wing.SetParent(Root, false);

            // 通路: 床はホールの内側の端から部屋の内側の端まで、天井と横壁は両側の壁の外側の面の間
            float inner = cl - 2f * t;
            Vector3 mid = f * (hallHalf + cl * 0.5f);
            MuseumGeometry.Box(wing, "Corridor Floor", mid + Vector3.down * (MuseumGeometry.SlabThickness * 0.5f),
                MuseumGeometry.Size(f, cl, MuseumGeometry.SlabThickness, cw), wood);
            MuseumGeometry.Box(wing, "Corridor Ceiling", mid + Vector3.up * (ch + MuseumGeometry.SlabThickness * 0.5f),
                MuseumGeometry.Size(f, inner, MuseumGeometry.SlabThickness, cw + 2f * t), concreteCeiling);
            for (int side = -1; side <= 1; side += 2)
            {
                Vector3 c = mid + r * (side * (cw * 0.5f + t * 0.5f)) + Vector3.up * (ch * 0.5f);
                MuseumGeometry.Box(wing, "Corridor Wall", c, MuseumGeometry.Size(f, inner, ch, t), concreteWall);
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
                FloorFor(room.theme), concreteWall, concreteCeiling);
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

                MuseumGeometry.Box(stand, "Pedestal", Vector3.up * 0.5f, new Vector3(0.9f, 1f, 0.9f), pedestalMat);
                // 段階2で本物のジオラマに差し替える仮の箱
                var placeholder = MuseumGeometry.Box(stand, "Placeholder", Vector3.up * 1.35f, Vector3.one * 0.7f, placeholderMat);
                placeholder.transform.localRotation = Quaternion.Euler(0f, 20f, 0f);

                var anchor = new GameObject("Anchor").transform;
                anchor.SetParent(stand, false);
                anchor.localPosition = Vector3.up * 1f;
                ExhibitAnchors.Add(anchor);

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
