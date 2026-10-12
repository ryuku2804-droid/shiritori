using System.Collections.Generic;
using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEngine;
using UnityEngine.AI;
using UnityEngine.SceneManagement;

namespace BlindSpot.EditorTools
{
    /// <summary>
    /// StageLayout (どこに何を置くかのデータ) を読んで、新しいシーンを丸ごと組み立てて保存する。
    /// メニュー「Tools > BlindSpot」から使う。何度押しても同じ結果になる。
    /// </summary>
    public static class GrayboxRoomBuilder
    {
        const string PlayerLayerName = "Player";
        const string MonsterLayerName = "Monster";
        const string MaterialFolder = "Assets/BlindSpot/Materials";

        // 見た目の名前 → 色。StageLayout の material にはここの名前を書く
        static readonly Dictionary<string, Color> Colors = new Dictionary<string, Color>
        {
            { "Floor", new Color(0.45f, 0.45f, 0.45f) },
            { "Wall", new Color(0.7f, 0.7f, 0.7f) },
            { "Obstacle", new Color(0.3f, 0.3f, 0.32f) },
            { "Carpet", new Color(0.45f, 0.12f, 0.12f) },
            { "Glass", new Color(0.6f, 0.9f, 0.95f) },
            { "Water", new Color(0.1f, 0.25f, 0.5f) },
            { "Metal", new Color(0.35f, 0.45f, 0.55f) },
            { "Monster", new Color(0.55f, 0.15f, 0.12f) },
            { "Furniture", new Color(0.38f, 0.42f, 0.36f) },
            { "Stone", new Color(0.5f, 0.5f, 0.48f) },
            { "Bottle", new Color(0.2f, 0.5f, 0.3f) },
            { "Can", new Color(0.75f, 0.75f, 0.78f) },
        };

        [MenuItem("Tools/BlindSpot/テスト部屋を作成")]
        static void BuildPrototype()
        {
            BuildStage(PrototypeStage.Build(), PrototypeStage.ScenePath);
        }

        /// <summary>レイアウトから新しいシーンを作り、保存してビルド設定に登録する。</summary>
        public static void BuildStage(StageLayout layout, string scenePath)
        {
            // 今開いているシーンに未保存の変更があれば、保存するか聞く (キャンセルなら中止)
            if (!EditorSceneManager.SaveCurrentModifiedScenesIfUserWantsTo()) return;

            int playerLayer = EnsureLayer(PlayerLayerName);
            int monsterLayer = EnsureLayer(MonsterLayerName);
            if (playerLayer < 0 || monsterLayer < 0)
            {
                EditorUtility.DisplayDialog("BlindSpot",
                    "空いているレイヤーが無いため Player / Monster レイヤーを作れませんでした。\n" +
                    "Project Settings > Tags and Layers で空きを作ってから再実行してください。", "OK");
                return;
            }

            Scene scene = EditorSceneManager.NewScene(NewSceneSetup.EmptyScene, NewSceneMode.Single);

            CreateLight();

            // レイアウトの箱を全部置く。名前で引けるように辞書にも入れておく
            // (ステップ2以降で「この扉とこのスイッチをつなぐ」ような紐付けに使う)
            var root = new GameObject(layout.name);
            var groups = new Dictionary<string, Transform>();
            var placed = new Dictionary<string, GameObject>();
            foreach (Placement p in layout.blocks)
            {
                placed[p.name] = Place(p, GetGroup(root.transform, groups, p.group));
            }

            // 家具の部品を、名前でまとめて1つの家具にする (オブジェクト同士を名前でつなぐ例)
            BuildLockers(layout, placed, GetGroup(root.transform, groups, "Furniture"));
            BuildDesks(layout, placed, GetGroup(root.transform, groups, "Furniture"));
            BuildItems(layout, GetGroup(root.transform, groups, "Items"));

            BuildPlayer(playerLayer, layout.playerStart, layout.playerYaw);

            // 動くもの (プレイヤーと怪物) は NavMesh の障害物にしない
            int staticMask = ~((1 << playerLayer) | (1 << monsterLayer));
            if (layout.patrolPoints.Count > 0)
            {
                BuildNavMesh(staticMask);
                BuildMonster(monsterLayer, layout);
            }

            EnsureFolder(System.IO.Path.GetDirectoryName(scenePath).Replace('\\', '/'));
            EditorSceneManager.SaveScene(scene, scenePath);
            AddToBuildSettings(scenePath);

            Debug.Log($"[BlindSpot] {scenePath} を作成しました ({placed.Count} 個の箱を配置)。");
        }

        // ---------------- 配置 ----------------

        static Transform GetGroup(Transform root, Dictionary<string, Transform> groups, string group)
        {
            if (string.IsNullOrEmpty(group)) return root;
            if (!groups.TryGetValue(group, out Transform t))
            {
                t = new GameObject(group).transform;
                t.SetParent(root, false);
                groups[group] = t;
            }
            return t;
        }

        static GameObject Place(Placement p, Transform parent)
        {
            var go = GameObject.CreatePrimitive(PrimitiveType.Cube); // 見た目と BoxCollider が両方付く
            go.name = p.name;
            go.transform.SetParent(parent, false);
            go.transform.localPosition = p.position;
            go.transform.localRotation = Quaternion.Euler(0f, p.yaw, 0f);
            go.transform.localScale = p.size;
            go.GetComponent<MeshRenderer>().sharedMaterial = GetMaterial(p.material);
            if (p.surface != SurfaceType.Default) go.AddComponent<SurfaceMaterial>().type = p.surface;
            GameObjectUtility.SetStaticEditorFlags(go, StaticEditorFlags.BatchingStatic);
            return go;
        }

        /// <summary>名前が「prefix_」で始まる箱を全部、parent の子にする。</summary>
        static void Adopt(Dictionary<string, GameObject> placed, string prefix, Transform parent)
        {
            foreach (KeyValuePair<string, GameObject> pair in placed)
            {
                if (pair.Key.StartsWith(prefix + "_")) pair.Value.transform.SetParent(parent, true);
            }
        }

        static void BuildLockers(StageLayout layout, Dictionary<string, GameObject> placed, Transform group)
        {
            foreach (FixtureSpec spec in layout.lockers)
            {
                var locker = new GameObject(spec.name).transform;
                locker.SetParent(group, false);
                locker.SetPositionAndRotation(spec.position, Quaternion.Euler(0f, spec.yaw, 0f));
                Adopt(placed, spec.name, locker);

                // 中の位置は扉の向き、出口は扉の向きのまま外へ
                var inside = new GameObject("InsidePoint").transform;
                inside.SetParent(locker, false);
                inside.SetPositionAndRotation(spec.inside, Quaternion.Euler(0f, spec.yaw, 0f));
                var exit = new GameObject("ExitPoint").transform;
                exit.SetParent(locker, false);
                exit.SetPositionAndRotation(spec.exit, Quaternion.Euler(0f, spec.yaw, 0f));

                var spot = locker.gameObject.AddComponent<HidingSpot>();
                var so = new SerializedObject(spot);
                so.FindProperty("insidePoint").objectReferenceValue = inside;
                so.FindProperty("exitPoint").objectReferenceValue = exit;
                so.ApplyModifiedPropertiesWithoutUndo();
            }
        }

        static void BuildDesks(StageLayout layout, Dictionary<string, GameObject> placed, Transform group)
        {
            foreach (FixtureSpec spec in layout.desks)
            {
                var desk = new GameObject(spec.name).transform;
                desk.SetParent(group, false);
                desk.SetPositionAndRotation(spec.position, Quaternion.Euler(0f, spec.yaw, 0f));
                Adopt(placed, spec.name, desk);

                // 机の下の、しゃがめば隠れられる範囲 (中心は床から高さの半分)
                var zone = new GameObject("HideZone").transform;
                zone.SetParent(desk, false);
                zone.localPosition = new Vector3(0f, spec.zoneSize.y / 2f, 0f);
                var hide = zone.gameObject.AddComponent<HideZone>();
                var so = new SerializedObject(hide);
                so.FindProperty("size").vector3Value = spec.zoneSize;
                so.ApplyModifiedPropertiesWithoutUndo();
            }
        }

        static void BuildItems(StageLayout layout, Transform group)
        {
            for (int i = 0; i < layout.items.Count; i++)
            {
                ItemSpec spec = layout.items[i];
                GameObject go = ThrowableDefs.CreateObject(spec.type, GetMaterial(spec.type.ToString()));
                go.name = $"{spec.type}_{i}";
                go.transform.SetParent(group, false);
                go.transform.position = spec.position + Vector3.up * ThrowableDefs.HalfHeight(spec.type);
                go.AddComponent<ItemPickup>().Setup(spec.type);
            }
        }

        static void CreateLight()
        {
            var go = new GameObject("Directional Light");
            var light = go.AddComponent<Light>();
            light.type = LightType.Directional;
            light.intensity = 1f;
            go.transform.rotation = Quaternion.Euler(50f, -30f, 0f);
        }

        // ---------------- プレイヤー ----------------

        static GameObject BuildPlayer(int playerLayer, Vector3 position, float yaw)
        {
            var player = new GameObject("Player");
            player.transform.SetPositionAndRotation(position, Quaternion.Euler(0f, yaw, 0f));
            player.layer = playerLayer;
            player.tag = "Player";

            var cc = player.AddComponent<CharacterController>();
            cc.height = 1.8f;
            cc.radius = 0.35f;
            cc.center = new Vector3(0, 0.9f, 0);
            cc.stepOffset = 0.3f;
            cc.slopeLimit = 45f;
            cc.skinWidth = 0.05f;

            var audio = player.AddComponent<AudioSource>();
            audio.playOnAwake = false;
            audio.spatialBlend = 0f; // 自分の足音なので 2D で鳴らす

            // カメラ
            var camRoot = new GameObject("CameraRoot");
            camRoot.transform.SetParent(player.transform, false);
            camRoot.transform.localPosition = new Vector3(0, 1.65f, 0);
            camRoot.layer = playerLayer;
            camRoot.tag = "MainCamera";
            var cam = camRoot.AddComponent<Camera>();
            cam.nearClipPlane = 0.05f;
            cam.fieldOfView = 70f;
            camRoot.AddComponent<AudioListener>();

            int maskWithoutPlayer = ~(1 << playerLayer);

            // private の [SerializeField] には、Inspector と同じ経路 (SerializedObject) で値を入れる
            var pc = player.AddComponent<PlayerController>();
            var so = new SerializedObject(pc);
            so.FindProperty("cameraRoot").objectReferenceValue = camRoot.transform;
            so.FindProperty("obstacleMask").intValue = maskWithoutPlayer;
            so.ApplyModifiedPropertiesWithoutUndo();

            var fs = player.AddComponent<FootstepNoise>();
            so = new SerializedObject(fs);
            so.FindProperty("groundMask").intValue = maskWithoutPlayer;
            so.FindProperty("audioSource").objectReferenceValue = audio;
            so.ApplyModifiedPropertiesWithoutUndo();

            // 隠れる・投げる・息を止める
            var interactor = player.AddComponent<PlayerInteractor>();
            so = new SerializedObject(interactor);
            so.FindProperty("mask").intValue = maskWithoutPlayer;
            so.ApplyModifiedPropertiesWithoutUndo();
            var thrower = player.AddComponent<PlayerThrower>();
            var breath = player.AddComponent<BreathHold>();

            var hud = player.AddComponent<DebugHud>();
            so = new SerializedObject(hud);
            so.FindProperty("player").objectReferenceValue = pc;
            so.FindProperty("footsteps").objectReferenceValue = fs;
            so.FindProperty("interactor").objectReferenceValue = interactor;
            so.FindProperty("thrower").objectReferenceValue = thrower;
            so.FindProperty("breath").objectReferenceValue = breath;
            so.ApplyModifiedPropertiesWithoutUndo();

            return player;
        }

        // ---------------- 怪物 ----------------

        static void BuildNavMesh(int includeLayers)
        {
            var go = new GameObject("NavMesh");
            var nav = go.AddComponent<RuntimeNavMesh>();
            var so = new SerializedObject(nav);
            so.FindProperty("includeLayers").intValue = includeLayers;
            so.ApplyModifiedPropertiesWithoutUndo();
        }

        static void BuildMonster(int monsterLayer, StageLayout layout)
        {
            // 巡回ポイント (空のオブジェクト)
            var pointsRoot = new GameObject("PatrolPoints").transform;
            var points = new Transform[layout.patrolPoints.Count];
            for (int i = 0; i < points.Length; i++)
            {
                points[i] = new GameObject("Point_" + i).transform;
                points[i].SetParent(pointsRoot, false);
                points[i].position = layout.patrolPoints[i];
            }

            // 仮の体はカプセル (高さ 2.2m・半径 0.4m)。カプセルの原点は真ん中なので、足元が床に来るよう持ち上げる
            const float height = 2.2f;
            var monster = GameObject.CreatePrimitive(PrimitiveType.Capsule);
            monster.name = "Monster";
            monster.layer = monsterLayer;
            monster.transform.position = layout.monsterStart + Vector3.up * (height / 2f);
            monster.transform.localScale = new Vector3(0.8f, height / 2f, 0.8f);
            monster.GetComponent<MeshRenderer>().sharedMaterial = GetMaterial("Monster");

            var agent = monster.AddComponent<NavMeshAgent>();
            // エージェントの大きさはスケール前の値で指定する (実際の大きさ = 値 × スケール)
            agent.baseOffset = 1f; // カプセルの半分の高さ。足元を NavMesh に合わせる
            agent.radius = 0.5f;   // × 0.8 = 0.4m
            agent.height = 2f;     // × 1.1 = 2.2m
            agent.angularSpeed = 240f;
            agent.acceleration = 12f;
            agent.stoppingDistance = 0.3f;
            agent.enabled = false; // NavMesh はゲーム開始時に作るので、MonsterAI の Start で有効にする

            var ai = monster.AddComponent<MonsterAI>();
            var so = new SerializedObject(ai);
            var list = so.FindProperty("patrolPoints");
            list.arraySize = points.Length;
            for (int i = 0; i < points.Length; i++) list.GetArrayElementAtIndex(i).objectReferenceValue = points[i];
            so.ApplyModifiedPropertiesWithoutUndo();

            // クリック音は 3D (近いほど大きく、方向もわかる)
            var audio = monster.AddComponent<AudioSource>();
            audio.playOnAwake = false;
            audio.spatialBlend = 1f;
            audio.rolloffMode = AudioRolloffMode.Linear;
            audio.minDistance = 1f;
            audio.maxDistance = 25f;
            var clicker = monster.AddComponent<MonsterClicker>();
            so = new SerializedObject(clicker);
            so.FindProperty("monster").objectReferenceValue = ai;
            so.ApplyModifiedPropertiesWithoutUndo();
        }

        // ---------------- 補助 ----------------

        /// <summary>ビルド設定 (File > Build Profiles のシーン一覧) に無ければ追加する。</summary>
        static void AddToBuildSettings(string scenePath)
        {
            var scenes = new List<EditorBuildSettingsScene>(EditorBuildSettings.scenes);
            if (scenes.Exists(s => s.path == scenePath)) return;
            scenes.Add(new EditorBuildSettingsScene(scenePath, true));
            EditorBuildSettings.scenes = scenes.ToArray();
        }

        /// <summary>指定名のレイヤーが無ければ空いている User Layer に作る。番号を返す (失敗時 -1)。</summary>
        static int EnsureLayer(string layerName)
        {
            int existing = LayerMask.NameToLayer(layerName);
            if (existing >= 0) return existing;

            var tagManager = new SerializedObject(AssetDatabase.LoadAllAssetsAtPath("ProjectSettings/TagManager.asset")[0]);
            var layers = tagManager.FindProperty("layers");
            for (int i = 8; i < layers.arraySize; i++)
            {
                var p = layers.GetArrayElementAtIndex(i);
                if (string.IsNullOrEmpty(p.stringValue))
                {
                    p.stringValue = layerName;
                    tagManager.ApplyModifiedPropertiesWithoutUndo();
                    Debug.Log($"[BlindSpot] レイヤー「{layerName}」を {i} 番に作成しました。");
                    return i;
                }
            }
            return -1;
        }

        /// <summary>"Assets/A/B" のようなフォルダを、無い階層ごと作る。</summary>
        static void EnsureFolder(string path)
        {
            if (AssetDatabase.IsValidFolder(path)) return;
            string parent = System.IO.Path.GetDirectoryName(path).Replace('\\', '/');
            EnsureFolder(parent);
            AssetDatabase.CreateFolder(parent, System.IO.Path.GetFileName(path));
        }

        /// <summary>単色マテリアルを取得 (無ければ Assets/BlindSpot/Materials に作成)。</summary>
        static Material GetMaterial(string name)
        {
            string path = $"{MaterialFolder}/GB_{name}.mat";
            var mat = AssetDatabase.LoadAssetAtPath<Material>(path);
            if (mat != null) return mat;

            EnsureFolder(MaterialFolder);
            Color color = Colors.TryGetValue(name, out Color c) ? c : Color.magenta; // 表に無い名前は目立つ色にする
            var shader = Shader.Find("Universal Render Pipeline/Lit") ?? Shader.Find("Standard");
            mat = new Material(shader);
            if (mat.HasProperty("_BaseColor")) mat.SetColor("_BaseColor", color);
            if (mat.HasProperty("_Color")) mat.SetColor("_Color", color);
            AssetDatabase.CreateAsset(mat, path);
            return mat;
        }
    }
}
