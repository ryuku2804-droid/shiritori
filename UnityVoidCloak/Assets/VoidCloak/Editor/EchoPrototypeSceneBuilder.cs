#if UNITY_EDITOR
using EchoKnight;
using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEngine;
using VoidCloak;

namespace EchoKnightEditor
{
    /// <summary>
    /// Menus:
    ///   Tools > Echo Knight > Create Prologue Stage   (序章「崩れた鐘楼」)
    ///   Tools > Echo Knight > Create Prototype Stage  (the test courtyard)
    /// Each creates a new scene with the dark stage, the knight, the follow camera, enemies,
    /// shrines, hints and memory echoes. Save the scene afterwards (Ctrl+S).
    /// </summary>
    public static class EchoPrototypeSceneBuilder
    {
        const string MaterialFolder = "Assets/EchoKnightGenerated";

        [MenuItem("Tools/Echo Knight/Create Prologue Stage")]
        public static void CreatePrologueStage()
        {
            BuildScene(EchoPrologueLayout.Build(), "序章「崩れた鐘楼」のステージを作りました。");
        }

        [MenuItem("Tools/Echo Knight/Create Prototype Stage")]
        public static void CreatePrototypeStage()
        {
            BuildScene(EchoPrototypeStage.Build(), "プロトタイプのステージを作りました。");
        }

        static void BuildScene(EchoStageLayout layout, string doneMessage)
        {
            Shader cloakShader = Shader.Find("VoidCloak/ClothPoint");
            Shader worldShader = Shader.Find("EchoKnight/WorldPoint");
            if (cloakShader == null || worldShader == null)
            {
                EditorUtility.DisplayDialog("Echo Knight",
                    "シェーダーが見つかりません。\nVoidCloakPointShader.shader と EchoWorldPoint.shader がプロジェクトに入っているか、" +
                    "Consoleにシェーダーのエラーが出ていないか確認してください。", "OK");
                return;
            }

            if (!EditorSceneManager.SaveCurrentModifiedScenesIfUserWantsTo()) return;
            var scene = EditorSceneManager.NewScene(NewSceneSetup.EmptyScene, NewSceneMode.Single);

            Material stone = GetOrCreateMaterial("EchoStone", worldShader, new Color(0.9f, 0.93f, 1f, 1f));
            Material enemy = GetOrCreateMaterial("EchoEnemy", worldShader, new Color(1f, 0.16f, 0.12f, 1f));
            Material gold = GetOrCreateMaterial("EchoGold", worldShader, new Color(1f, 0.78f, 0.3f, 1f));

            new GameObject("EchoSystem").AddComponent<EchoSystem>();
            new GameObject("EchoAudio").AddComponent<EchoAudio>();

            // ---------------- stage
            var stage = new GameObject("Stage - " + layout.name).transform;
            foreach (EchoPiecePlacement placement in layout.pieces)
            {
                GameObject go = Place(placement.name, stage, placement.position, placement.yaw);
                go.AddComponent<EchoKitPiece>().Configure(placement.spec, placement.gold ? gold : stone);
            }

            // ---------------- sound puzzles
            foreach (EchoHollowWallPlacement wall in layout.hollowWalls)
            {
                Place(wall.name, stage, wall.position, wall.yaw).AddComponent<EchoHollowWall>().Setup(stone, wall.size, wall.seed);
            }
            foreach (EchoBellDoorPlacement door in layout.bellDoors)
            {
                var bells = new EchoPuzzleBell[door.bells.Length];
                for (int i = 0; i < bells.Length; i++)
                {
                    bells[i] = Place(door.name + " - Bell " + (i + 1), stage, door.bells[i].position, door.bells[i].yaw).AddComponent<EchoPuzzleBell>();
                    bells[i].Setup(gold, i);
                }
                Place(door.name, stage, door.position, door.yaw).AddComponent<EchoBellDoor>().Setup(stone, door.width, door.openingHeight, bells, door.sequence);
            }

            // ---------------- bell shrines (save points)
            foreach (EchoShrinePlacement shrine in layout.shrines)
            {
                Place(shrine.name, stage, shrine.position, shrine.yaw).AddComponent<EchoBellShrine>().Setup(gold);
            }

            // ---------------- memory echoes, hints, goal
            var events = new GameObject("Story").transform;
            foreach (EchoGhostPlacement ghost in layout.ghosts)
            {
                Place(ghost.name, events, ghost.position, ghost.yaw).AddComponent<EchoMemoryGhost>().Setup(gold, ghost.speaker, ghost.line);
            }
            foreach (EchoHintPlacement hint in layout.hints)
            {
                Place(hint.name, events, hint.center, 0f).AddComponent<EchoHintZone>().Setup(hint.size, hint.speaker, hint.line, hint.instruction);
            }
            if (layout.hasGoal)
            {
                Place("Goal", events, layout.goalCenter, 0f).AddComponent<EchoStageGoal>().Setup(layout.goalSize, layout.goalTitle, layout.goalSubtitle);
            }

            // ---------------- knight
            var player = new GameObject("Knight");
            player.transform.position = layout.playerSpawn;
            player.transform.rotation = Quaternion.Euler(0f, layout.playerYaw, 0f);
            var controller = player.AddComponent<CharacterController>();
            controller.height = 4.2f;
            controller.radius = 0.8f;
            controller.center = new Vector3(0f, 2.1f, 0f);
            controller.stepOffset = 0.6f;
            controller.slopeLimit = 50f;
            var character = player.AddComponent<VoidCloakCharacter>();
            var so = new SerializedObject(character);
            so.FindProperty("characterShader").objectReferenceValue = cloakShader;
            so.ApplyModifiedPropertiesWithoutUndo();
            player.AddComponent<VoidCloakMover>();
            player.AddComponent<EchoPlayer>();
            player.AddComponent<EchoCombat>();

            // ---------------- camera (pure black background)
            var camGo = new GameObject("Main Camera");
            camGo.tag = "MainCamera";
            var cam = camGo.AddComponent<Camera>();
            cam.clearFlags = CameraClearFlags.SolidColor;
            cam.backgroundColor = Color.black;
            cam.nearClipPlane = 0.1f;
            cam.farClipPlane = 300f;
            camGo.AddComponent<AudioListener>();
            camGo.transform.position = layout.playerSpawn + Quaternion.Euler(0f, layout.playerYaw, 0f) * new Vector3(0f, 5f, -11f);
            camGo.AddComponent<VoidCloakFollowCamera>().Target = player.transform;

            // ---------------- enemies
            int n = 1;
            var enemies = new GameObject("Enemies").transform;
            foreach (EchoEnemyPlacement e in layout.listeners)
            {
                Place("Listener " + n++, enemies, e.position, e.yaw).AddComponent<EchoListenerEnemy>().Setup(enemy, player.transform, e.wanderRadius);
            }
            n = 1;
            foreach (EchoArmorPlacement a in layout.armors)
            {
                Place("Hollow Armor " + n++, enemies, a.position, a.yaw).AddComponent<EchoHollowArmorEnemy>().Setup(enemy, player.transform, a.route);
            }

            RenderSettings.skybox = null;
            RenderSettings.ambientLight = Color.black;

            EditorSceneManager.MarkSceneDirty(scene);
            Selection.activeGameObject = player;
            EditorUtility.DisplayDialog("Echo Knight", doneMessage + "\nCtrl+S でシーンを保存してから Play を押してください。", "OK");
        }

        static GameObject Place(string name, Transform parent, Vector3 position, float yaw)
        {
            var go = new GameObject(name);
            go.transform.SetParent(parent, false);
            go.transform.localPosition = position;
            go.transform.localRotation = Quaternion.Euler(0f, yaw, 0f);
            return go;
        }

        static Material GetOrCreateMaterial(string name, Shader shader, Color color)
        {
            if (!AssetDatabase.IsValidFolder(MaterialFolder)) AssetDatabase.CreateFolder("Assets", "EchoKnightGenerated");
            string path = MaterialFolder + "/" + name + ".mat";
            var m = AssetDatabase.LoadAssetAtPath<Material>(path);
            if (m == null)
            {
                m = new Material(shader);
                m.SetColor("_EchoColor", color);
                AssetDatabase.CreateAsset(m, path);
                AssetDatabase.SaveAssets();
            }
            return m;
        }
    }
}
#endif
