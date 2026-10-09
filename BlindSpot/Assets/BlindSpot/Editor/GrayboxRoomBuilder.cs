using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEngine;

namespace BlindSpot.EditorTools
{
    /// <summary>
    /// メニュー「BlindSpot > ステップ1: テスト部屋とプレイヤーを作成」で、
    /// グレーボックスの部屋 (素材の違う床つき) とプレイヤーを今開いているシーンに組み立てる。
    /// </summary>
    public static class GrayboxRoomBuilder
    {
        const string RootName = "Graybox_Room";
        const string PlayerName = "Player";
        const string PlayerLayerName = "Player";
        const string MaterialFolder = "Assets/BlindSpot/Materials";

        [MenuItem("BlindSpot/ステップ1: テスト部屋とプレイヤーを作成")]
        public static void Build()
        {
            // 既にあるなら作り直すか確認
            var oldRoot = GameObject.Find(RootName);
            var oldPlayer = GameObject.Find(PlayerName);
            if (oldRoot != null || oldPlayer != null)
            {
                if (!EditorUtility.DisplayDialog("BlindSpot",
                        "テスト部屋またはプレイヤーが既にシーンにあります。削除して作り直しますか?",
                        "作り直す", "キャンセル"))
                    return;
                if (oldRoot != null) Undo.DestroyObjectImmediate(oldRoot);
                if (oldPlayer != null) Undo.DestroyObjectImmediate(oldPlayer);
            }

            int playerLayer = EnsureLayer(PlayerLayerName);
            if (playerLayer < 0)
            {
                EditorUtility.DisplayDialog("BlindSpot",
                    "空いているレイヤーが無いため Player レイヤーを作れませんでした。\n" +
                    "Project Settings > Tags and Layers で空きを作ってから再実行してください。", "OK");
                return;
            }

            BuildRoom();
            var player = BuildPlayer(playerLayer);
            RemoveOtherMainCameras(player);
            EnsureLight();

            EditorSceneManager.MarkSceneDirty(EditorSceneManager.GetActiveScene());
            Selection.activeGameObject = player;
            Debug.Log("[BlindSpot] テスト部屋とプレイヤーを作成しました。シーンを保存してから再生してください。");
        }

        // ---------------- 部屋 ----------------

        static void BuildRoom()
        {
            var root = new GameObject(RootName);
            Undo.RegisterCreatedObjectUndo(root, "Create Graybox Room");

            var matFloor = GetMaterial("Floor", new Color(0.45f, 0.45f, 0.45f));
            var matWall = GetMaterial("Wall", new Color(0.7f, 0.7f, 0.7f));
            var matObstacle = GetMaterial("Obstacle", new Color(0.3f, 0.3f, 0.32f));
            var matCarpet = GetMaterial("Carpet", new Color(0.45f, 0.12f, 0.12f));
            var matGlass = GetMaterial("Glass", new Color(0.6f, 0.9f, 0.95f));
            var matWater = GetMaterial("Water", new Color(0.1f, 0.25f, 0.5f));
            var matMetal = GetMaterial("Metal", new Color(0.35f, 0.45f, 0.55f));

            const float size = 20f;   // 部屋の一辺
            const float height = 3f;  // 天井の高さ
            const float wall = 0.3f;  // 壁の厚さ

            // 床と天井 (天井はしゃがみ・立ち上がり判定の確認にも使える)
            Box(root, "Floor", new Vector3(0, -0.1f, 0), new Vector3(size, 0.2f, size), matFloor);
            Box(root, "Ceiling", new Vector3(0, height + 0.1f, 0), new Vector3(size, 0.2f, size), matWall);

            // 壁
            float half = size / 2f;
            Box(root, "Wall_N", new Vector3(0, height / 2, half + wall / 2), new Vector3(size + wall * 2, height, wall), matWall);
            Box(root, "Wall_S", new Vector3(0, height / 2, -half - wall / 2), new Vector3(size + wall * 2, height, wall), matWall);
            Box(root, "Wall_E", new Vector3(half + wall / 2, height / 2, 0), new Vector3(wall, height, size), matWall);
            Box(root, "Wall_W", new Vector3(-half - wall / 2, height / 2, 0), new Vector3(wall, height, size), matWall);

            // 素材の違う床 (薄い板を床の上に置く。段差 2cm なので普通に歩いて乗れる)
            var surfaces = new GameObject("Surfaces");
            surfaces.transform.SetParent(root.transform, false);
            SurfacePatch(surfaces, "Carpet", new Vector3(-6, 0, 5), new Vector2(5, 5), matCarpet, SurfaceType.Carpet);
            SurfacePatch(surfaces, "Glass", new Vector3(6, 0, 5), new Vector2(4, 4), matGlass, SurfaceType.Glass);
            SurfacePatch(surfaces, "Water", new Vector3(6, 0, -3), new Vector2(4, 3), matWater, SurfaceType.Water);
            SurfacePatch(surfaces, "Metal", new Vector3(-6, 0, -3), new Vector2(3, 6), matMetal, SurfaceType.Metal);

            // 障害物
            var obstacles = new GameObject("Obstacles");
            obstacles.transform.SetParent(root.transform, false);
            Box(obstacles, "Pillar_1", new Vector3(-2, height / 2, 2), new Vector3(1, height, 1), matObstacle);
            Box(obstacles, "Pillar_2", new Vector3(2, height / 2, -2), new Vector3(1, height, 1), matObstacle);
            Box(obstacles, "Crate_1", new Vector3(0, 0.5f, 6), new Vector3(2, 1, 1), matObstacle);
            Box(obstacles, "Crate_2", new Vector3(3, 0.6f, 8), new Vector3(1.2f, 1.2f, 1.2f), matObstacle);
            Box(obstacles, "Shelf", new Vector3(-8.5f, 1f, 0), new Vector3(1, 2, 3), matObstacle);

            // しゃがみでしか通れない低い通路 (天板の下 1.2m)
            var lowPass = new GameObject("LowPassage");
            lowPass.transform.SetParent(obstacles.transform, false);
            lowPass.transform.localPosition = new Vector3(0, 0, -6);
            Box(lowPass, "Top", new Vector3(0, 1.2f + 0.1f, 0), new Vector3(3, 0.2f, 2), matObstacle);
            Box(lowPass, "Side_L", new Vector3(-1.6f, 0.65f, 0), new Vector3(0.2f, 1.3f, 2), matObstacle);
            Box(lowPass, "Side_R", new Vector3(1.6f, 0.65f, 0), new Vector3(0.2f, 1.3f, 2), matObstacle);
            Box(lowPass, "Upper", new Vector3(0, (1.4f + height) / 2f, 0), new Vector3(3.4f, height - 1.4f, 0.2f), matObstacle);

            foreach (Transform t in root.GetComponentsInChildren<Transform>())
                GameObjectUtility.SetStaticEditorFlags(t.gameObject, StaticEditorFlags.BatchingStatic);
        }

        static GameObject Box(GameObject parent, string name, Vector3 localPos, Vector3 scale, Material mat)
        {
            var go = GameObject.CreatePrimitive(PrimitiveType.Cube);
            go.name = name;
            go.transform.SetParent(parent.transform, false);
            go.transform.localPosition = localPos;
            go.transform.localScale = scale;
            go.GetComponent<MeshRenderer>().sharedMaterial = mat;
            return go;
        }

        static void SurfacePatch(GameObject parent, string name, Vector3 pos, Vector2 size, Material mat, SurfaceType type)
        {
            const float thickness = 0.02f;
            var go = Box(parent, "Surface_" + name, pos + Vector3.up * (thickness / 2f),
                new Vector3(size.x, thickness, size.y), mat);
            go.AddComponent<SurfaceMaterial>().type = type;
        }

        // ---------------- プレイヤー ----------------

        static GameObject BuildPlayer(int playerLayer)
        {
            var player = new GameObject(PlayerName);
            Undo.RegisterCreatedObjectUndo(player, "Create Player");
            player.transform.position = new Vector3(0, 0.05f, -8.5f);
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
            var cam = camRoot.AddComponent<Camera>();
            cam.nearClipPlane = 0.05f;
            cam.fieldOfView = 70f;
            camRoot.AddComponent<AudioListener>();
            camRoot.tag = "MainCamera";

            int maskWithoutPlayer = ~(1 << playerLayer);

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

            var hud = player.AddComponent<DebugHud>();
            so = new SerializedObject(hud);
            so.FindProperty("player").objectReferenceValue = pc;
            so.FindProperty("footsteps").objectReferenceValue = fs;
            so.ApplyModifiedPropertiesWithoutUndo();

            return player;
        }

        /// <summary>プレイヤー以外の MainCamera (シーン標準の Main Camera など) を削除する。カメラが2つあると困るため。</summary>
        static void RemoveOtherMainCameras(GameObject player)
        {
            foreach (var cam in Object.FindObjectsByType<Camera>(FindObjectsInactive.Include, FindObjectsSortMode.None))
            {
                if (cam.transform.IsChildOf(player.transform)) continue;
                if (!cam.CompareTag("MainCamera")) continue;
                Debug.Log($"[BlindSpot] 既存のカメラ「{cam.name}」を削除しました (Ctrl+Z で戻せます)。");
                Undo.DestroyObjectImmediate(cam.gameObject);
            }
        }

        static void EnsureLight()
        {
            if (Object.FindFirstObjectByType<Light>() != null) return;
            var go = new GameObject("Directional Light");
            Undo.RegisterCreatedObjectUndo(go, "Create Light");
            var light = go.AddComponent<Light>();
            light.type = LightType.Directional;
            light.intensity = 1f;
            go.transform.rotation = Quaternion.Euler(50, -30, 0);
        }

        // ---------------- 補助 ----------------

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

        /// <summary>単色マテリアルを取得 (無ければ Assets/BlindSpot/Materials に作成)。</summary>
        static Material GetMaterial(string name, Color color)
        {
            string path = $"{MaterialFolder}/GB_{name}.mat";
            var mat = AssetDatabase.LoadAssetAtPath<Material>(path);
            if (mat != null) return mat;

            if (!AssetDatabase.IsValidFolder("Assets/BlindSpot")) AssetDatabase.CreateFolder("Assets", "BlindSpot");
            if (!AssetDatabase.IsValidFolder(MaterialFolder)) AssetDatabase.CreateFolder("Assets/BlindSpot", "Materials");

            var shader = Shader.Find("Universal Render Pipeline/Lit") ?? Shader.Find("Standard");
            mat = new Material(shader);
            if (mat.HasProperty("_BaseColor")) mat.SetColor("_BaseColor", color);
            if (mat.HasProperty("_Color")) mat.SetColor("_Color", color);
            AssetDatabase.CreateAsset(mat, path);
            return mat;
        }
    }
}
