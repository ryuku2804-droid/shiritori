#if UNITY_EDITOR
using System.Collections.Generic;
using EchoKnight;
using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEngine;
using UnityEngine.SceneManagement;
using VoidCloak;

namespace EchoKnightEditor
{
    /// <summary>
    /// Menus:
    ///   Tools > Echo Knight > Build Game              (title screen + every chapter, saved and added to Build Settings)
    ///   Tools > Echo Knight > Create Prologue Stage   (序章「崩れた鐘楼」)
    ///   Tools > Echo Knight > Create Chapter 1 Stage  (第一章「灰の城下町」)
    ///   Tools > Echo Knight > Create Prototype Stage  (the test courtyard)
    /// Each creates a new scene with the dark stage, the knight, the follow camera, enemies,
    /// shrines, hints and memory echoes. Save the scene afterwards (Ctrl+S).
    /// Build Game makes the scenes the game moves between (EchoTitle -> EchoPrologue -> EchoChapter1).
    /// </summary>
    public static class EchoPrototypeSceneBuilder
    {
        const string MaterialFolder = "Assets/EchoKnightGenerated";
        const string SceneFolder = "Assets/EchoKnightScenes";

        /// <summary>The layout of each chapter, in the order of EchoGame.Chapters.</summary>
        static EchoStageLayout ChapterLayout(int index)
        {
            switch (index)
            {
                case 0: return EchoPrologueLayout.Build();
                case 1: return EchoChapter1Layout.Build();
                default: return null;
            }
        }

        [MenuItem("Tools/Echo Knight/Build Game (Title + All Chapters)", false, 0)]
        public static void BuildGame()
        {
            if (!ShadersReady()) return;
            if (!EditorUtility.DisplayDialog("Echo Knight",
                    "タイトル画面と全部の章のシーンを作って、" + SceneFolder + " に保存します。\n" +
                    "同じ名前のシーンがあれば上書きします。少し時間がかかります。", "作る", "やめる")) return;
            if (!EditorSceneManager.SaveCurrentModifiedScenesIfUserWantsTo()) return;
            if (!AssetDatabase.IsValidFolder(SceneFolder)) AssetDatabase.CreateFolder("Assets", "EchoKnightScenes");

            var paths = new List<string>();
            try
            {
                EditorUtility.DisplayProgressBar("Echo Knight", "タイトル画面", 0f);
                Scene scene = EditorSceneManager.NewScene(NewSceneSetup.EmptyScene, NewSceneMode.Single);
                FillTitle();
                paths.Add(SaveAs(scene, EchoGame.TitleScene));

                for (int i = 0; i < EchoGame.Chapters.Length; i++)
                {
                    EchoStageLayout layout = ChapterLayout(i);
                    if (layout == null) continue;
                    EditorUtility.DisplayProgressBar("Echo Knight", EchoGame.Chapters[i].title, (i + 1f) / (EchoGame.Chapters.Length + 1f));
                    scene = EditorSceneManager.NewScene(NewSceneSetup.EmptyScene, NewSceneMode.Single);
                    FillStage(layout, i);
                    paths.Add(SaveAs(scene, EchoGame.Chapters[i].scene));
                }
            }
            finally
            {
                EditorUtility.ClearProgressBar();
            }

            // our scenes first (the title is the one the game starts with), then any others already listed
            var list = new List<EditorBuildSettingsScene>();
            foreach (string path in paths) list.Add(new EditorBuildSettingsScene(path, true));
            foreach (EditorBuildSettingsScene other in EditorBuildSettings.scenes)
                if (!paths.Contains(other.path)) list.Add(other);
            EditorBuildSettings.scenes = list.ToArray();

            EditorSceneManager.OpenScene(paths[0]);
            EditorUtility.DisplayDialog("Echo Knight",
                "できました。EchoTitle シーンが開いています。\nPlay を押すと、タイトル画面から通して遊べます。", "OK");
        }

        static string SaveAs(Scene scene, string sceneName)
        {
            string path = SceneFolder + "/" + sceneName + ".unity";
            EditorSceneManager.SaveScene(scene, path);
            return path;
        }

        /// <summary>The title screen: the ruins, the knight standing still, a fixed camera and the menu.</summary>
        static void FillTitle()
        {
            Shader cloakShader = Shader.Find("VoidCloak/ClothPoint");
            Shader worldShader = Shader.Find("EchoKnight/WorldPoint");
            Material stone = GetOrCreateMaterial("EchoStone", worldShader, new Color(0.9f, 0.93f, 1f, 1f));
            Material gold = GetOrCreateMaterial("EchoGold", worldShader, new Color(1f, 0.78f, 0.3f, 1f));

            new GameObject("EchoSystem").AddComponent<EchoSystem>();
            new GameObject("EchoAudio").AddComponent<EchoAudio>();

            EchoStageLayout layout = EchoTitleLayout.Build();
            var stage = new GameObject("Stage - Title").transform;
            foreach (EchoPiecePlacement placement in layout.pieces)
            {
                GameObject go = Place(placement.name, stage, placement.position, placement.yaw);
                go.AddComponent<EchoKitPiece>().Configure(placement.spec, placement.gold ? gold : stone);
            }

            var knight = new GameObject("Knight");
            knight.transform.position = layout.playerSpawn;
            knight.transform.rotation = Quaternion.Euler(0f, layout.playerYaw, 0f);
            var character = knight.AddComponent<VoidCloakCharacter>();
            var so = new SerializedObject(character);
            so.FindProperty("characterShader").objectReferenceValue = cloakShader;
            so.ApplyModifiedPropertiesWithoutUndo();

            var camGo = new GameObject("Main Camera");
            camGo.tag = "MainCamera";
            var cam = camGo.AddComponent<Camera>();
            cam.clearFlags = CameraClearFlags.SolidColor;
            cam.backgroundColor = Color.black;
            cam.nearClipPlane = 0.1f;
            cam.farClipPlane = 200f;
            cam.fieldOfView = 40f;
            camGo.AddComponent<AudioListener>();
            camGo.transform.position = EchoTitleLayout.CameraPosition;
            camGo.transform.rotation = Quaternion.LookRotation(EchoTitleLayout.CameraTarget - EchoTitleLayout.CameraPosition, Vector3.up);

            new GameObject("Title Screen").AddComponent<EchoTitleScreen>().Setup(knight.transform);

            RenderSettings.skybox = null;
            RenderSettings.ambientLight = Color.black;
        }

        [MenuItem("Tools/Echo Knight/Create Prologue Stage")]
        public static void CreatePrologueStage()
        {
            BuildScene(EchoPrologueLayout.Build(), 0, "序章「崩れた鐘楼」のステージを作りました。");
        }

        [MenuItem("Tools/Echo Knight/Create Chapter 1 Stage")]
        public static void CreateChapter1Stage()
        {
            BuildScene(EchoChapter1Layout.Build(), 1, "第一章「灰の城下町」のステージを作りました。");
        }

        [MenuItem("Tools/Echo Knight/Create Prototype Stage")]
        public static void CreatePrototypeStage()
        {
            BuildScene(EchoPrototypeStage.Build(), -1, "プロトタイプのステージを作りました。");
        }

        static void BuildScene(EchoStageLayout layout, int chapterIndex, string doneMessage)
        {
            if (!ShadersReady()) return;
            if (!EditorSceneManager.SaveCurrentModifiedScenesIfUserWantsTo()) return;
            var scene = EditorSceneManager.NewScene(NewSceneSetup.EmptyScene, NewSceneMode.Single);
            GameObject player = FillStage(layout, chapterIndex);
            EditorSceneManager.MarkSceneDirty(scene);
            Selection.activeGameObject = player;
            EditorUtility.DisplayDialog("Echo Knight", doneMessage + "\nCtrl+S でシーンを保存してから Play を押してください。", "OK");
        }

        static bool ShadersReady()
        {
            if (Shader.Find("VoidCloak/ClothPoint") != null && Shader.Find("EchoKnight/WorldPoint") != null) return true;
            EditorUtility.DisplayDialog("Echo Knight",
                "シェーダーが見つかりません。\nVoidCloakPointShader.shader と EchoWorldPoint.shader がプロジェクトに入っているか、" +
                "Consoleにシェーダーのエラーが出ていないか確認してください。", "OK");
            return false;
        }

        /// <summary>Fills the open (empty) scene with a whole stage. Returns the knight.</summary>
        static GameObject FillStage(EchoStageLayout layout, int chapterIndex)
        {
            Shader cloakShader = Shader.Find("VoidCloak/ClothPoint");
            Shader worldShader = Shader.Find("EchoKnight/WorldPoint");
            Material stone = GetOrCreateMaterial("EchoStone", worldShader, new Color(0.9f, 0.93f, 1f, 1f));
            Material enemy = GetOrCreateMaterial("EchoEnemy", worldShader, new Color(1f, 0.16f, 0.12f, 1f));
            Material gold = GetOrCreateMaterial("EchoGold", worldShader, new Color(1f, 0.78f, 0.3f, 1f));

            // which chapter this is (title card, save, next chapter) and the pause menu
            var info = new GameObject("Stage Info");
            info.AddComponent<EchoStageInfo>().Setup(chapterIndex);
            info.AddComponent<EchoPauseMenu>();

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
            var doorsByName = new Dictionary<string, EchoBellDoor>();
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
                var bellDoor = Place(door.name, stage, door.position, door.yaw).AddComponent<EchoBellDoor>();
                bellDoor.Setup(stone, door.width, door.openingHeight, bells, door.sequence);
                doorsByName[door.name] = bellDoor;
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
            var theatresByName = new Dictionary<string, EchoMemoryTheatre>();
            foreach (EchoTheatrePlacement th in layout.theatres)
            {
                var theatre = Place(th.name, events, th.position, th.yaw).AddComponent<EchoMemoryTheatre>();
                theatre.Setup(gold, th.sceneId, th.triggerRadius);
                theatresByName[th.name] = theatre;
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
            player.AddComponent<EchoStoneThrow>();

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

            foreach (EchoBossPlacement boss in layout.bosses)
            {
                EchoBellDoor sealedDoor;
                EchoMemoryTheatre memory;
                doorsByName.TryGetValue(boss.sealedDoorName ?? "", out sealedDoor);
                theatresByName.TryGetValue(boss.theatreName ?? "", out memory);
                var go = Place(boss.name, enemies, boss.position, boss.yaw);
                go.transform.localScale = Vector3.one * 1.12f;
                go.AddComponent<EchoSilentKnightBoss>().Setup(enemy, player.transform, sealedDoor, memory);
            }

            RenderSettings.skybox = null;
            RenderSettings.ambientLight = Color.black;
            return player;
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
