// エディターの中だけで使うファイル。Editor フォルダの外に置いても、ゲームのビルド (Quest など) には入らないように、
// 全体を UNITY_EDITOR のときだけ読むようにしている
#if UNITY_EDITOR
using System.IO;
using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEngine;

namespace NightShards.Museum.EditorTools
{
    // Tools > Diorama Museum のメニュー。編集中のシーンに美術館を組み立てる。
    // Editor という名前のフォルダに置くのがおすすめ (どこに置いても、#if UNITY_EDITOR でビルドには入らない)
    public static class MuseumMenu
    {
        const string Menu = "Tools/Diorama Museum/";
        const string DefaultMaterialFolder = "Assets/NightShards/Museum/Generated";

        [MenuItem(Menu + "美術館を組み立てる", priority = 0)]
        static void BuildInScene()
        {
            var builder = FindOrCreateBuilder();
            Build(builder);
            Selection.activeGameObject = builder.gameObject;
            FrameInSceneView(builder);
        }

        [MenuItem(Menu + "新しいシーンに組み立てる", priority = 1)]
        static void BuildInNewScene()
        {
            if (!EditorSceneManager.SaveCurrentModifiedScenesIfUserWantsTo()) return;
            EditorSceneManager.NewScene(NewSceneSetup.DefaultGameObjects, NewSceneMode.Single);
            BuildInScene();
        }

        // 設計図を初期設定 (ドームと 8 部屋・16 作品) に戻してから組み立てる。古い設計図から作り直すとき用
        [MenuItem(Menu + "設計図を初期設定に戻して組み立てる", priority = 2)]
        static void ResetAndBuild()
        {
            var builder = FindOrCreateBuilder();
            if (!EditorUtility.DisplayDialog("Diorama Museum",
                    "部屋と作品の一覧を初期設定 (ドームと 8 部屋・16 作品) に戻して、組み立て直します。\n" +
                    "Inspector で変えた部屋の名前や作品の説明は元に戻ります (Ctrl+Z で取り消せます)。", "戻して組み立てる", "やめる"))
                return;
            Undo.RecordObject(builder, "設計図を初期設定に戻す");
            builder.ResetLayout();
            EditorUtility.SetDirty(builder);
            Build(builder);
            Selection.activeGameObject = builder.gameObject;
            FrameInSceneView(builder);
        }

        [MenuItem(Menu + "展示室を1つ追加する", priority = 20)]
        static void AddRoom()
        {
            var builder = FindOrCreateBuilder();
            var layout = builder.Layout;

            // まだ使っていないスロット (ドームのまわりの位置) を探す
            int free = -1;
            for (int slot = 0; slot < MuseumLayout.SlotCount; slot++)
            {
                if (!layout.rooms.Exists(r => r.slot == slot)) { free = slot; break; }
            }
            if (free < 0)
            {
                EditorUtility.DisplayDialog("Diorama Museum",
                    "8 か所すべてに展示室があります。部屋を増やすには、Inspector の Rooms から1つ消してください。", "OK");
                return;
            }

            Undo.RecordObject(builder, "展示室を追加");
            layout.rooms.Add(new RoomSpec
            {
                name = "新しい展示室",
                slot = free,
                accent = new Color(0.9f, 0.9f, 0.85f),
                exhibits = { new ExhibitSpec { title = "新しい作品" } },
            });
            EditorUtility.SetDirty(builder);
            Build(builder);
            Selection.activeGameObject = builder.gameObject;
        }

        [MenuItem(Menu + "美術館を消す", priority = 40)]
        static void ClearInScene()
        {
            var builder = Object.FindFirstObjectByType<MuseumBuilder>();
            if (builder == null || builder.Root == null) return;
            Undo.DestroyObjectImmediate(builder.Root.gameObject);
            builder.Clear();
            EditorSceneManager.MarkSceneDirty(builder.gameObject.scene);
        }

        // ---------------------------------------------------------------- 共通

        // Inspector のボタンからも呼ぶ
        public static void Build(MuseumBuilder builder)
        {
            Undo.RecordObject(builder, "美術館を組み立てる");

            // 前に組み立てた建物は、元に戻せる形で消しておく
            if (builder.Root != null) Undo.DestroyObjectImmediate(builder.Root.gameObject);

            // ApplyEnvironment で止める Directional Light も、元に戻せるように記録する
            foreach (var l in Object.FindObjectsByType<Light>(FindObjectsSortMode.None))
                if (l.type == LightType.Directional) Undo.RecordObject(l.gameObject, "美術館を組み立てる");

            EnsureMaterialAssets(builder);
            EnsureShadersAndDiorama(builder);
            builder.Build();
            ReportShaderProblems(builder);

            Undo.RegisterCreatedObjectUndo(builder.Root.gameObject, "美術館を組み立てる");
            EditorUtility.SetDirty(builder);
            EditorSceneManager.MarkSceneDirty(builder.gameObject.scene);
            Debug.Log($"[Museum] 組み立てました。展示室 {builder.Layout.rooms.Count} 室、台座 {builder.ExhibitAnchors.Count} 台。");
        }

        static MuseumBuilder FindOrCreateBuilder()
        {
            var builder = Object.FindFirstObjectByType<MuseumBuilder>();
            if (builder != null) return builder;

            var go = new GameObject("Museum");
            Undo.RegisterCreatedObjectUndo(go, "美術館を作る");
            builder = Undo.AddComponent<MuseumBuilder>(go);
            return builder;
        }

        // マテリアルをファイルとして Generated フォルダに保存し、MuseumBuilder の欄に入れる。
        // すでにファイルがあれば作り直さずにそれを使う (自分で調整した色が消えないように)
        static void EnsureMaterialAssets(MuseumBuilder builder)
        {
            Shader shader = MuseumMaterials.FindShader(builder.SurfaceShader);
            string materialFolder = MaterialFolderFor(shader);
            if (!AssetDatabase.IsValidFolder(materialFolder))
            {
                Directory.CreateDirectory(materialFolder);
                AssetDatabase.Refresh();
            }

            var mats = builder.Materials;
            for (int i = 0; i < MuseumMaterials.Defaults.Length; i++)
            {
                if (mats.Get(i) != null && AssetDatabase.Contains(mats.Get(i))) continue;

                var spec = MuseumMaterials.Defaults[i];
                string path = $"{materialFolder}/{spec.name}.mat";
                var mat = AssetDatabase.LoadAssetAtPath<Material>(path);
                if (mat == null)
                {
                    mat = MuseumMaterials.Create(spec, shader);
                    AssetDatabase.CreateAsset(mat, path);
                }
                mats.Set(i, mat);
            }
            AssetDatabase.SaveAssets();
        }

        // シェーダーの欄と、ジオラマのマテリアルの欄を埋める。
        // ジオラマのマテリアルは MuseumDiorama シェーダーで作り、Generated フォルダに保存する
        static void EnsureShadersAndDiorama(MuseumBuilder builder)
        {
            var so = new SerializedObject(builder);

            void FillShader(string field, string shaderName)
            {
                var prop = so.FindProperty(field);
                if (prop.objectReferenceValue == null) prop.objectReferenceValue = Shader.Find(shaderName);
            }
            FillShader("surfaceShader", "NightShards/MuseumSurface");
            FillShader("textShader", "NightShards/MuseumText");
            FillShader("artShader", "NightShards/MuseumArt");
            FillShader("dioramaShader", "NightShards/MuseumDiorama");

            var diorama = so.FindProperty("dioramaMaterial");
            var current = diorama.objectReferenceValue as Material;
            bool usable = current != null && current.shader != null && current.shader.name == "NightShards/MuseumDiorama";
            if (!usable)
            {
                Shader dioramaShader = Shader.Find("NightShards/MuseumDiorama");
                if (dioramaShader == null)
                {
                    Debug.LogWarning("[Museum] シェーダー NightShards/MuseumDiorama が見つからないので、台座には仮の箱を置きます。");
                }
                else
                {
                    string folder = MaterialFolderFor(MuseumMaterials.FindShader(builder.SurfaceShader));
                    string path = folder + "/Museum Diorama.mat";
                    var mat = AssetDatabase.LoadAssetAtPath<Material>(path);
                    if (mat == null)
                    {
                        mat = new Material(dioramaShader) { name = "Museum Diorama" };
                        AssetDatabase.CreateAsset(mat, path);
                        AssetDatabase.SaveAssets();
                    }
                    diorama.objectReferenceValue = mat;
                }
            }
            so.ApplyModifiedPropertiesWithoutUndo();
        }

        // シェーダーが Assets/〇〇/Shaders にあれば Assets/〇〇/Generated に保存する。わからなければ決まった場所に
        static string MaterialFolderFor(Shader shader)
        {
            string shaderPath = shader != null ? AssetDatabase.GetAssetPath(shader) : "";
            if (!shaderPath.StartsWith("Assets/")) return DefaultMaterialFolder;
            string dir = Path.GetDirectoryName(shaderPath).Replace('\\', '/');
            string parent = Path.GetFileName(dir) == "Shaders" ? Path.GetDirectoryName(dir).Replace('\\', '/') : dir;
            return parent + "/Generated";
        }

        // ピンク色になる原因 (URP などのプロジェクト・シェーダーのエラー) を Console に書き出す
        static void ReportShaderProblems(MuseumBuilder builder)
        {
            bool notUrp = !MuseumMaterials.IsUniversalPipeline(); // 詳しいメッセージは Build の中で出している

            Shader shader = MuseumMaterials.FindShader(builder.SurfaceShader);
            bool hasError = shader != null && ShaderUtil.ShaderHasError(shader);
            if (hasError)
            {
                foreach (var m in ShaderUtil.GetShaderMessages(shader))
                    Debug.LogError($"[Museum] シェーダーのエラー ({m.platform}) {m.line} 行目: {m.message}\n{m.messageDetails}");
            }

            // 保存済みのマテリアルが別のシェーダーを向いていないか (貼り直す前のマテリアルが残っている場合など)
            var mats = builder.Materials;
            for (int i = 0; i < MuseumMaterials.Defaults.Length; i++)
            {
                var mat = mats.Get(i);
                if (mat == null || shader == null || mat.shader == shader) continue;
                Debug.LogWarning($"[Museum] マテリアル「{mat.name}」のシェーダーが {mat.shader.name} になっていたので、MuseumSurface に直しました。", mat);
                mat.shader = shader;
                EditorUtility.SetDirty(mat);
            }

            if (notUrp || hasError)
                EditorUtility.DisplayDialog("Diorama Museum",
                    notUrp ? "このプロジェクトは URP ではないので、館がピンク色になります。Console の赤いメッセージを見てください。"
                        : "MuseumSurface シェーダーにエラーがあるので、館がピンク色になります。Console の赤いメッセージを貼ってください。",
                    "OK");
        }

        // Scene ビューのカメラを、館全体が見える位置へ動かす
        static void FrameInSceneView(MuseumBuilder builder)
        {
            var view = SceneView.lastActiveSceneView;
            if (view == null || builder.Root == null) return;
            var bounds = new Bounds(builder.transform.position, Vector3.zero);
            foreach (var r in builder.Root.GetComponentsInChildren<Renderer>()) bounds.Encapsulate(r.bounds);
            view.Frame(bounds, false);
        }
    }

    // MuseumBuilder の Inspector に「組み立てる」「消す」ボタンを足す
    [CustomEditor(typeof(MuseumBuilder))]
    public class MuseumBuilderEditor : Editor
    {
        public override void OnInspectorGUI()
        {
            var builder = (MuseumBuilder)target;

            EditorGUILayout.HelpBox(
                builder.Root != null
                    ? "建物はシーンに組み立て済みです。Layout を変えたら「組み立て直す」を押してください。"
                    : "まだ建物はありません。「組み立てる」を押すか、そのまま再生すると組み立てます。",
                MessageType.Info);

            using (new EditorGUI.DisabledScope(Application.isPlaying))
            using (new EditorGUILayout.HorizontalScope())
            {
                if (GUILayout.Button(builder.Root != null ? "組み立て直す" : "組み立てる", GUILayout.Height(28)))
                    MuseumMenu.Build(builder);
                using (new EditorGUI.DisabledScope(builder.Root == null))
                {
                    if (GUILayout.Button("消す", GUILayout.Height(28), GUILayout.Width(80)))
                    {
                        Undo.DestroyObjectImmediate(builder.Root.gameObject);
                        builder.Clear();
                        EditorSceneManager.MarkSceneDirty(builder.gameObject.scene);
                    }
                }
            }
            EditorGUILayout.Space();

            DrawDefaultInspector();
        }
    }
}
#endif
