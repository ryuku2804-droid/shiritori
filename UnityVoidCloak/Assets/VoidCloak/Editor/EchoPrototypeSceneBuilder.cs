#if UNITY_EDITOR
using EchoKnight;
using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEngine;
using VoidCloak;

namespace EchoKnightEditor
{
    /// <summary>
    /// Menu: Tools > Echo Knight > Create Prototype Stage
    /// Creates a new scene with the dark stage, the knight (WASD, echoes, bell strike),
    /// the follow camera and one Listener enemy. Save the scene afterwards (Ctrl+S).
    /// </summary>
    public static class EchoPrototypeSceneBuilder
    {
        const string MaterialFolder = "Assets/EchoKnightGenerated";

        [MenuItem("Tools/Echo Knight/Create Prototype Stage")]
        public static void CreatePrototypeStage()
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
            var stage = new GameObject("Stage").transform;
            foreach (EchoPiecePlacement placement in EchoPrototypeLayout.Pieces())
            {
                var go = new GameObject(placement.name);
                go.transform.SetParent(stage, false);
                go.transform.localPosition = placement.position;
                go.transform.localRotation = Quaternion.Euler(0f, placement.yaw, 0f);
                go.AddComponent<EchoKitPiece>().Configure(placement.spec, stone);
            }

            // ---------------- bell shrines (save points)
            foreach (EchoShrinePlacement shrine in EchoPrototypeLayout.Shrines())
            {
                var go = new GameObject(shrine.name);
                go.transform.SetParent(stage, false);
                go.transform.localPosition = shrine.position;
                go.transform.localRotation = Quaternion.Euler(0f, shrine.yaw, 0f);
                go.AddComponent<EchoBellShrine>().Setup(gold);
            }

            // ---------------- knight
            var player = new GameObject("Knight");
            player.transform.position = EchoPrototypeLayout.PlayerSpawn;
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
            camGo.transform.position = EchoPrototypeLayout.PlayerSpawn + new Vector3(0f, 5f, -11f);
            camGo.AddComponent<VoidCloakFollowCamera>().Target = player.transform;

            // ---------------- enemy
            var listener = new GameObject("Listener");
            listener.transform.position = EchoPrototypeLayout.ListenerSpawn;
            listener.transform.rotation = Quaternion.Euler(0f, 180f, 0f);
            listener.AddComponent<EchoListenerEnemy>().Setup(enemy, player.transform);

            RenderSettings.skybox = null;
            RenderSettings.ambientLight = Color.black;

            EditorSceneManager.MarkSceneDirty(scene);
            Selection.activeGameObject = player;
            EditorUtility.DisplayDialog("Echo Knight",
                "プロトタイプのステージを作りました。\nCtrl+S でシーンを保存してから Play を押してください。", "OK");
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
