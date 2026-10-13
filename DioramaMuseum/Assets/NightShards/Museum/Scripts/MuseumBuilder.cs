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

        [Header("ジオラマとキャプション")]
        [Tooltip("ジオラマのマテリアル (MuseumDiorama シェーダー)。Tools で組み立てると自動で作って入れる。空なら再生時にその場で作る")]
        [SerializeField] Material dioramaMaterial;
        [Tooltip("ジオラマのシェーダー。空なら Shader.Find で探す")]
        [SerializeField] Shader dioramaShader;
        [Tooltip("ジオラマの箱の一辺 (m)")]
        [SerializeField] float dioramaSize = 0.8f;
        [Tooltip("キャプションの文字のシェーダー。空なら Shader.Find で探す")]
        [SerializeField] Shader textShader;
        [Tooltip("展示室のアート (月・光の糸・障子・火の粉) のシェーダー。空なら Shader.Find で探す")]
        [SerializeField] Shader artShader;
        [Tooltip("キャプションの文字の大きさの倍率")]
        [SerializeField, Range(0.5f, 2f)] float captionTextScale = 1f;

        [Header("シーン")]
        [Tooltip("シーンにもとからある Directional Light (太陽の光) を止め、再生中は元の Main Camera も止める。" +
                 "屋内なので太陽の光は使わない。外すと、Directional Light はそのまま残る")]
        [SerializeField] bool takeOverScene = true;

        [Header("明るさ (再生中に動かすと、その場で変わる)")]
        [Tooltip("すべてのライトと環境光にかける倍率")]
        [SerializeField, Range(0.25f, 4f)] float brightness = 1f;
        [Tooltip("影の部分の明るさ (どこにも光が当たっていない所の色)")]
        [SerializeField] Color ambient = new Color(0.06f, 0.06f, 0.07f);
        // URP のライトは距離の2乗で暗くなるので、高めの値になる
        [Tooltip("台座の真上のスポットライト")] [SerializeField] float spotIntensity = 60f;
        [Tooltip("ホールの天井のライト")] [SerializeField] float hallIntensity = 40f;
        [Tooltip("通路の奥の色の光")] [SerializeField] float glowIntensity = 12f;
        [Tooltip("展示室全体のほのかな光")] [SerializeField] float fillIntensity = 10f;
        [Tooltip("ホールの壁を上から照らす光")] [SerializeField] float washIntensity = 18f;

        [Header("霧")]
        [SerializeField] Color fogColor = new Color(0.01f, 0.01f, 0.012f);
        [Tooltip("大きいほど奥が暗く沈む")]
        [SerializeField] float fogDensity = 0.025f;

        // 組み立てた建物の親。Tools メニューで組み立てた場合は、シーンに保存されている
        [SerializeField, HideInInspector] Transform root;
        [SerializeField, HideInInspector] List<Transform> exhibitAnchors = new List<Transform>();

        // 明るさをあとから変えられるように、作ったライトを種類ごとに覚えておく
        [SerializeField, HideInInspector] List<Light> spotLights = new List<Light>();
        [SerializeField, HideInInspector] List<Light> hallLights = new List<Light>();
        [SerializeField, HideInInspector] List<Light> glowLights = new List<Light>();
        [SerializeField, HideInInspector] List<Light> fillLights = new List<Light>();
        [SerializeField, HideInInspector] List<Light> washLights = new List<Light>();
        // 展示室のアートのライト。作ったときの明るさを覚えておき、Brightness をかける
        [SerializeField, HideInInspector] List<Light> artLights = new List<Light>();
        [SerializeField, HideInInspector] List<float> artLightBase = new List<float>();

        public MuseumLayout Layout => layout;
        public Shader SurfaceShader => surfaceShader;
        public MuseumMaterials Materials => materials;
        public Material DioramaMaterial => dioramaMaterial;
        public Transform Root => root;
        public FirstPersonController Player { get; private set; }

        // 展示の一覧 (ジオラマの中心)
        public IReadOnlyList<Transform> ExhibitAnchors => exhibitAnchors;

        Material textMaterial; // 組み立て1回ぶん、すべてのキャプションで共有する

        public const string RootName = "Museum (Generated)";

        void Reset()
        {
            layout = MuseumLayout.CreateDefault();
        }

        // Inspector で値を変えたとき。建物があれば、ライトの明るさと環境光だけをその場で直す
        void OnValidate()
        {
            if (root != null) ApplyLighting();
        }

        void Awake()
        {
            if (root == null)
            {
                Build();
            }
            else
            {
                ApplyEnvironment();
                ApplyLighting();
            }

            if (takeOverScene)
                foreach (var cam in FindObjectsByType<Camera>(FindObjectsSortMode.None))
                    cam.gameObject.SetActive(false);

            CreatePlayer();
            gameObject.AddComponent<MuseumHUD>();
        }

        // ---------------------------------------------------------------- 組み立て・片付け

        // 建物をすべて作り直す。編集中にも再生中にも呼べる
        public void Build()
        {
            Clear();
            if (!MuseumMaterials.WarnIfNotUniversalPipeline()) WarnIfAdditionalLightsOff();
            ApplyEnvironment();
            materials.FillMissing(MuseumMaterials.FindShader(surfaceShader));

            root = new GameObject(RootName).transform;
            root.SetParent(transform, false);
            exhibitAnchors.Clear();
            textMaterial = CaptionText.CreateMaterial(textShader, CaptionText.DefaultFont);

            BuildHallAndRooms();
            ApplyLighting();
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
            spotLights.Clear();
            hallLights.Clear();
            glowLights.Clear();
            fillLights.Clear();
            washLights.Clear();
            artLights.Clear();
            artLightBase.Clear();
        }

        // 暗く静かな館内にする。空の光は使わず、ほぼ黒の環境光と、黒い霧で奥を沈める
        public void ApplyEnvironment()
        {
            if (takeOverScene)
                foreach (var l in FindObjectsByType<Light>(FindObjectsSortMode.None))
                    if (l.type == LightType.Directional) l.gameObject.SetActive(false);

            RenderSettings.skybox = null;
            RenderSettings.ambientMode = UnityEngine.Rendering.AmbientMode.Flat;
            RenderSettings.reflectionIntensity = 0.15f;
            RenderSettings.fog = true;
            RenderSettings.fogMode = FogMode.ExponentialSquared;
            RenderSettings.fogColor = fogColor;
            RenderSettings.fogDensity = fogDensity;
        }

        // ライトの明るさと環境光に、いまの設定を入れ直す
        public void ApplyLighting()
        {
            SetIntensity(spotLights, spotIntensity);
            SetIntensity(hallLights, hallIntensity);
            SetIntensity(glowLights, glowIntensity);
            SetIntensity(fillLights, fillIntensity);
            SetIntensity(washLights, washIntensity);
            for (int i = 0; i < artLights.Count && i < artLightBase.Count; i++)
                if (artLights[i] != null) artLights[i].intensity = artLightBase[i] * brightness;

            Color amb = ambient * brightness;
            RenderSettings.ambientLight = amb;
            // URP は環境光を ambientProbe から読むので、同じ色で直接作っておく
            var probe = new UnityEngine.Rendering.SphericalHarmonicsL2();
            probe.AddAmbientLight(amb);
            RenderSettings.ambientProbe = probe;
        }

        void SetIntensity(List<Light> lights, float intensity)
        {
            foreach (var l in lights)
                if (l != null) l.intensity = intensity * brightness;
        }

        // URP の設定で「追加のライト」(スポットライトや点光源) が切られていると、館はほぼ真っ暗になる
        static void WarnIfAdditionalLightsOff()
        {
            var urp = UnityEngine.Rendering.GraphicsSettings.currentRenderPipeline as UnityEngine.Rendering.Universal.UniversalRenderPipelineAsset;
            if (urp == null) return;
            if (urp.additionalLightsRenderingMode != UnityEngine.Rendering.Universal.LightRenderingMode.PerPixel)
                Debug.LogWarning($"[Museum] URP のアセット「{urp.name}」の Lighting > Additional Lights が " +
                                 $"{urp.additionalLightsRenderingMode} になっています。Per Pixel にしないと、スポットライトがほとんど効きません。", urp);
        }

        // 部屋のテーマごとの床・壁・天井
        Material FloorFor(RoomTheme theme)
        {
            switch (theme)
            {
                case RoomTheme.Moon: return materials.water;
                case RoomTheme.Fire: return materials.obsidian;
                case RoomTheme.Dusk: return materials.wood;
                default: return materials.causticFloor;
            }
        }

        Material WallFor(RoomTheme theme)
        {
            switch (theme)
            {
                case RoomTheme.Fire: return materials.basaltWall;
                case RoomTheme.Sea: return materials.causticWall;
                default: return materials.concreteWall;
            }
        }

        Material CeilingFor(RoomTheme theme)
        {
            return theme == RoomTheme.Sea ? materials.causticWall : materials.concreteCeiling;
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
            hallLights.Add(AddLight(root, "Hall Light", new Vector3(0f, hall.y - 0.2f, 0f), LightType.Spot,
                new Color(0.8f, 0.86f, 1f), hallIntensity, hall.y + 3f, 75f, false));

            foreach (var room in rooms) BuildWing(room, hall, t, cw, ch, cl);
            BuildHallDecor(rooms, hall, ch);
        }

        // ホールの空間デザイン: 壁を照らす光・天井の光のスリット・各入口の上の部屋の名前
        void BuildHallDecor(List<RoomSpec> rooms, Vector3 hall, float ch)
        {
            var decor = new GameObject("Hall Decor").transform;
            decor.SetParent(root, false);

            // 壁を照らす光: 各面に2つずつ、天井近くから壁に沿って下へ流す。コンクリートの継ぎ目とセパ穴が浮かび上がる
            for (int d = 0; d < 4; d++)
            {
                Vector3 f = MuseumGeometry.Forward((RoomDirection)d);
                Vector3 r = new Vector3(f.z, 0f, -f.x);
                float half = Mathf.Abs(f.x) > 0.5f ? hall.x * 0.5f : hall.z * 0.5f;
                float along = (Mathf.Abs(f.x) > 0.5f ? hall.z : hall.x) * 0.25f; // 出入口の両わき
                foreach (float side in new[] { -1f, 1f })
                {
                    Vector3 pos = f * (half - 0.7f) + r * (side * along) + Vector3.up * (hall.y - 0.3f);
                    var l = AddLight(decor, "Wall Wash", pos, LightType.Spot, new Color(1f, 0.95f, 0.88f),
                        washIntensity, hall.y + 2f, 60f, false);
                    l.transform.rotation = Quaternion.LookRotation(Vector3.down * 0.85f + f * 0.5f); // 真下から少し壁へ
                    washLights.Add(l);
                }
            }

            // 天井の光のスリット: 中心から各部屋の入口へ向かう光の線。歩く向きへ目を導く
            Shader art = artShader != null ? artShader : Shader.Find("NightShards/MuseumArt");
            if (art != null)
            {
                var slitMat = RoomArt.MakeArt(art, "Ceiling Slit", 4, new Color(1.5f, 1.42f, 1.3f), additive: true);
                foreach (var room in rooms)
                {
                    Vector3 f = MuseumGeometry.Forward(room.direction);
                    Vector3 r = new Vector3(f.z, 0f, -f.x);
                    float half = Mathf.Abs(f.x) > 0.5f ? hall.x * 0.5f : hall.z * 0.5f;
                    float len = half - 0.9f;
                    var slit = RoomArt.Panel(decor, "Ceiling Slit", f * (0.5f + len * 0.5f) + Vector3.up * (hall.y - 0.02f),
                        Vector3.up, new Vector2(len, 0.14f), slitMat);
                    slit.transform.localRotation = Quaternion.LookRotation(Vector3.up, r); // 板の長い辺を部屋の向きに
                }
            }

            // 入口の上のサイン: 部屋の名前と、展示している作品の名前
            var font = CaptionText.DefaultFont;
            var warm = new Color(1f, 0.95f, 0.86f, 0.9f);
            var dim = new Color(0.8f, 0.76f, 0.7f, 0.75f);
            foreach (var room in rooms)
            {
                Vector3 f = MuseumGeometry.Forward(room.direction);
                float half = Mathf.Abs(f.x) > 0.5f ? hall.x * 0.5f : hall.z * 0.5f;
                var sign = new GameObject("Sign_" + room.name).transform;
                sign.SetParent(decor, false);
                sign.localPosition = f * (half - 0.005f) + Vector3.up * (ch + 0.8f);
                sign.localRotation = Quaternion.LookRotation(f); // ホールの中から読める向き

                var works = new System.Text.StringBuilder();
                foreach (var e in room.exhibits)
                {
                    if (works.Length > 0) works.Append("　・　");
                    works.Append(e.title);
                }
                CaptionText.Add(sign, "Name", room.name, Vector3.zero, 0.34f, warm, font, textMaterial,
                    TextAnchor.MiddleCenter, TextAlignment.Center);
                CaptionText.Add(sign, "Works", works.ToString(), Vector3.down * 0.34f, 0.11f, dim, font, textMaterial,
                    TextAnchor.MiddleCenter, TextAlignment.Center);
            }
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
            glowLights.Add(AddLight(wing, "Corridor Glow", f * (hallHalf + cl - 1f) + Vector3.up * (ch - 0.5f), LightType.Point,
                room.accent, glowIntensity, 6f, 0f, false));

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
                FloorFor(room.theme), WallFor(room.theme), CeilingFor(room.theme));
            fillLights.Add(AddLight(roomRoot, "Room Fill", center + Vector3.up * (room.height * 0.75f), LightType.Point,
                room.accent, fillIntensity, Mathf.Max(room.width, room.depth), 0f, false));

            var exhibitPositions = BuildExhibits(room, roomRoot, f, r, near);

            // 部屋そのもののアート
            var info = new RoomArt.RoomInfo
            {
                parent = roomRoot,
                center = center,
                forward = f,
                right = r,
                width = room.width,
                depth = room.depth,
                height = room.height,
                accent = room.accent,
                exhibits = exhibitPositions,
            };
            foreach (var l in RoomArt.Build(room.theme, info, artShader))
            {
                artLights.Add(l);
                artLightBase.Add(l.intensity);
            }
        }

        // ジオラマのマテリアル。欄が空なら、MuseumDiorama シェーダーでその場で作る (見つからなければ仮の箱になる)
        Material runtimeDiorama;
        Material DioramaMaterialOrDefault()
        {
            if (dioramaMaterial != null) return dioramaMaterial;
            if (runtimeDiorama != null) return runtimeDiorama;
            Shader s = dioramaShader != null ? dioramaShader : Shader.Find("NightShards/MuseumDiorama");
            if (s == null)
            {
                Debug.LogWarning("[Museum] シェーダー NightShards/MuseumDiorama が見つからないので、台座には仮の箱を置きます。");
                return null;
            }
            runtimeDiorama = new Material(s) { name = "Museum Diorama" };
            return runtimeDiorama;
        }

        // 部屋の幅いっぱいに、等間隔で台座を並べる。台座は入口のほうを向く
        List<Vector3> BuildExhibits(RoomSpec room, Transform parent, Vector3 f, Vector3 r, float near)
        {
            var positions = new List<Vector3>();
            var parts = new ExhibitStand.Parts
            {
                pedestal = materials.pedestal,
                placeholder = materials.placeholder,
                plate = materials.pedestal,
                diorama = DioramaMaterialOrDefault(),
                dioramaSize = dioramaSize,
                text = textMaterial,
                font = CaptionText.DefaultFont,
                textScale = captionTextScale,
            };

            int n = room.exhibits.Count;
            for (int i = 0; i < n; i++)
            {
                var spec = room.exhibits[i];
                float across = -room.width * 0.5f + room.width * (i + 1) / (n + 1);
                Vector3 pos = f * (near + room.depth * 0.55f) + r * across;

                positions.Add(pos);
                var go = new GameObject("Exhibit_" + spec.title);
                go.transform.SetParent(parent, false);
                go.transform.localPosition = pos;
                go.transform.localRotation = Quaternion.LookRotation(-f);

                var stand = go.AddComponent<ExhibitStand>();
                stand.Build(spec, parts);
                exhibitAnchors.Add(stand.Diorama.transform);

                // 台座の真上から落とすスポットライト。床に光だまりができる
                spotLights.Add(AddLight(go.transform, "Spot", Vector3.up * (room.height - 0.25f), LightType.Spot,
                    new Color(1f, 0.94f, 0.84f), spotIntensity, room.height + 2f, 34f, layout.spotShadows));
            }
            return positions;
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
            // シーンの Global Volume (ブルームなどの仕上げ) を効かせる
            var urpCam = UnityEngine.Rendering.Universal.CameraExtensions.GetUniversalAdditionalCameraData(cam);
            urpCam.renderPostProcessing = true;
            urpCam.antialiasing = UnityEngine.Rendering.Universal.AntialiasingMode.SubpixelMorphologicalAntiAliasing;
            camGo.AddComponent<AudioListener>();

            Player = go.AddComponent<FirstPersonController>();
            Player.cameraPivot = pivot;

            var viewer = go.AddComponent<ExhibitViewer>();
            viewer.cameraTransform = camGo.transform;
            viewer.body = Player;

            var lod = go.AddComponent<DioramaLOD>();
            lod.viewCamera = cam;
            lod.viewer = viewer;
        }
    }
}
