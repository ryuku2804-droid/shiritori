using System.Collections.Generic;
using UnityEngine;

namespace NightShards.Museum
{
    // キャプションの文字を TextMesh で置く道具。
    // フォントは Unity に入っている LegacyRuntime.ttf を使う。日本語の文字は OS のフォントから自動で補われる
    public static class CaptionText
    {
        // TextMesh の大きさの目安: characterSize 1・fontSize 10 で、1行の高さがおよそ 1m
        const int FontSize = 64;

        static readonly HashSet<Material> materials = new HashSet<Material>();
        static bool listening;

        public static Font DefaultFont => Resources.GetBuiltinResource<Font>("LegacyRuntime.ttf");

        // 文字用のマテリアルを作る。shader が空なら NightShards/MuseumText を探す
        public static Material CreateMaterial(Shader shader, Font font)
        {
            if (shader == null) shader = Shader.Find("NightShards/MuseumText");
            if (shader == null)
            {
                Debug.LogError("[Museum] シェーダー NightShards/MuseumText が見つかりません。MuseumText.shader を Assets に入れてください。");
                return font.material;
            }
            var mat = new Material(shader) { name = "Caption Text" };
            Refresh(mat, font);
            return mat;
        }

        // フォントの文字の絵 (テクスチャ) を、マテリアルに入れ直す。
        // 新しい文字を使うとフォントのテクスチャが作り直されることがあるので、そのたびに入れ直す
        public static void Refresh(Material mat, Font font)
        {
            if (mat == null || font == null || font.material == null) return;
            mat.mainTexture = font.material.mainTexture;
            materials.Add(mat);
            if (!listening)
            {
                Font.textureRebuilt += OnTextureRebuilt;
                listening = true;
            }
        }

        static void OnTextureRebuilt(Font font)
        {
            materials.RemoveWhere(m => m == null);
            foreach (var m in materials) m.mainTexture = font.material.mainTexture;
        }

        // 再生を始めたとき: シーンにあるすべての文字について、フォントに文字の絵を作らせ、文字のマテリアルに入れ直す。
        // フォントの文字の絵 (テクスチャ) はシーンに保存されないので、再生のたび (とくに Android に切りかえたあと) 空になり、
        // 美術館を組み立てたときに入れたテクスチャのままだと、文字が見えなくなる
        [RuntimeInitializeOnLoadMethod(RuntimeInitializeLoadType.AfterSceneLoad)]
        static void RefreshAllOnPlay()
        {
            materials.Clear();
            listening = false;
            var byFont = new Dictionary<Font, System.Text.StringBuilder>();
            var meshes = Object.FindObjectsByType<TextMesh>(FindObjectsInactive.Include, FindObjectsSortMode.None);
            foreach (var tm in meshes)
            {
                if (tm.font == null) continue;
                if (!byFont.TryGetValue(tm.font, out var sb)) byFont[tm.font] = sb = new System.Text.StringBuilder();
                sb.Append(tm.text);
            }
            // まず全部の文字の絵を作らせる (作り直されてテクスチャが変わっても、このあと入れ直すので大丈夫)
            foreach (var kv in byFont) kv.Key.RequestCharactersInTexture(kv.Value.ToString(), FontSize);
            foreach (var tm in meshes)
            {
                if (tm.font == null) continue;
                var r = tm.GetComponent<MeshRenderer>();
                if (r == null || r.sharedMaterial == null) continue;
                if (r.sharedMaterial != tm.font.material) Refresh(r.sharedMaterial, tm.font);
                // 文字の絵の位置が変わっているかもしれないので、文字の形を作り直させる
                string text = tm.text;
                tm.text = "";
                tm.text = text;
            }
        }

        // 1行の高さが lineHeight (m) になるように文字を置く。左上をそろえる
        public static TextMesh Add(Transform parent, string name, string text, Vector3 localPos, float lineHeight,
            Color color, Font font, Material mat)
        {
            return Add(parent, name, text, localPos, lineHeight, color, font, mat, TextAnchor.UpperLeft, TextAlignment.Left);
        }

        // そろえ方を指定する版 (サインなど、中央そろえにしたいとき)
        public static TextMesh Add(Transform parent, string name, string text, Vector3 localPos, float lineHeight,
            Color color, Font font, Material mat, TextAnchor anchor, TextAlignment alignment)
        {
            var go = new GameObject(name);
            go.transform.SetParent(parent, false);
            go.transform.localPosition = localPos;

            var tm = go.AddComponent<TextMesh>();
            tm.font = font;
            tm.fontSize = FontSize;
            tm.characterSize = lineHeight * 10f / FontSize;
            tm.anchor = anchor;
            tm.alignment = alignment;
            tm.lineSpacing = 1.1f;
            tm.color = color;
            tm.text = text;
            go.GetComponent<MeshRenderer>().sharedMaterial = mat;
            return tm;
        }

        // 日本語の文を、1行 maxChars 文字ごとに折り返す (句読点で終わる行を優先する)
        public static string Wrap(string text, int maxChars)
        {
            if (string.IsNullOrEmpty(text)) return "";
            var sb = new System.Text.StringBuilder();
            int lineLen = 0;
            for (int i = 0; i < text.Length; i++)
            {
                char c = text[i];
                if (c == '\n') { sb.Append(c); lineLen = 0; continue; }
                // 行頭に句読点が来ないように、句読点は1文字はみ出してもその行に入れる
                bool punct = c == '、' || c == '。' || c == '」' || c == '）';
                if (lineLen >= maxChars && !punct)
                {
                    sb.Append('\n');
                    lineLen = 0;
                }
                sb.Append(c);
                lineLen++;
            }
            return sb.ToString();
        }
    }
}
