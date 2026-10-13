using UnityEngine;

namespace NightShards.Museum
{
    // 夕の間の、障子越しの夕日。スポットライトに格子の形の「クッキー」(光の型紙) を付けて、床に格子の影を落とす。
    // 再生中は日がゆっくり傾き、影がのびたり縮んだりする。
    // クッキーは画像ファイルを使わず、ここで作る
    [ExecuteAlways]
    [RequireComponent(typeof(Light))]
    public class ShojiSun : MonoBehaviour
    {
        [Tooltip("光が進む水平の向き (障子から部屋の中へ)。部屋から見た向き")]
        public Vector3 aimFlat = Vector3.back;
        [Tooltip("見下ろす角度の範囲 (度)。小さいほど日が低く、影が長い")]
        public Vector2 pitchRange = new Vector2(20f, 40f);
        [Tooltip("日が低くなって、また戻るまでの秒数")]
        public float cycleSeconds = 120f;
        [Tooltip("格子のます目の数 (横・縦)")]
        public Vector2Int cells = new Vector2Int(6, 5);

        Light sun;
        Texture2D cookie;

        void OnEnable()
        {
            sun = GetComponent<Light>();
            cookie = MakeCookie(128, cells);
            sun.cookie = cookie;
            Apply(0f);
        }

        void OnDisable()
        {
            if (sun != null) sun.cookie = null;
            if (cookie != null)
            {
                if (Application.isPlaying) Destroy(cookie);
                else DestroyImmediate(cookie);
            }
        }

        void Update()
        {
            if (!Application.isPlaying) return;
            float s = 0.5f - 0.5f * Mathf.Cos(2f * Mathf.PI * Time.time / Mathf.Max(1f, cycleSeconds));
            Apply(s);
        }

        // s = 0 で日が高く、1 で低い
        void Apply(float s)
        {
            float pitch = Mathf.Lerp(pitchRange.y, pitchRange.x, s);
            Vector3 flat = new Vector3(aimFlat.x, 0f, aimFlat.z);
            if (flat.sqrMagnitude < 1e-4f) flat = Vector3.forward;
            // 部屋は回して置かれるので、向きは親 (部屋) から見た向きで決める
            transform.localRotation = Quaternion.LookRotation(flat.normalized) * Quaternion.Euler(pitch, 0f, 0f);
        }

        // 白地に黒い桟の格子。外側の縁は黒にして、光が四角く切り取られるようにする
        static Texture2D MakeCookie(int size, Vector2Int cells)
        {
            var tex = new Texture2D(size, size, TextureFormat.RGBA32, false)
            {
                name = "Shoji Cookie",
                wrapMode = TextureWrapMode.Clamp,
                hideFlags = HideFlags.DontSave, // シーンには保存しない (開くたびに作る)
            };
            var pixels = new Color32[size * size];
            float bar = 0.035f;  // 桟の太さ (ます目に対する割合)
            float margin = 0.12f; // 外側の黒い縁
            for (int y = 0; y < size; y++)
            {
                for (int x = 0; x < size; x++)
                {
                    float u = (x + 0.5f) / size;
                    float v = (y + 0.5f) / size;
                    float inside = (u > margin && u < 1f - margin && v > margin && v < 1f - margin) ? 1f : 0f;
                    float cu = Mathf.Repeat((u - margin) / (1f - 2f * margin) * cells.x, 1f);
                    float cv = Mathf.Repeat((v - margin) / (1f - 2f * margin) * cells.y, 1f);
                    bool onBar = cu < bar || cu > 1f - bar || cv < bar || cv > 1f - bar;
                    byte c = (byte)(inside * (onBar ? 0.08f : 1f) * 255f);
                    pixels[y * size + x] = new Color32(c, c, c, c);
                }
            }
            tex.SetPixels32(pixels);
            tex.Apply();
            return tex;
        }
    }
}
