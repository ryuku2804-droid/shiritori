using System.Collections.Generic;
using UnityEngine;

namespace NightShards.Museum
{
    // 部屋とジオラマの連動。展示室に付ける。
    // この部屋のジオラマの仕掛けが動くと (DioramaWork.Pulse)、部屋の照明と床の光が一緒に強く脈打つ。
    // 例: 火の間で大噴火すると、床の溶岩のひびと赤い照明が一斉に明るくなる。
    //     青い火の火口湖なら、照明と床の光が青に染まる (色は DioramaWork.Tint)
    public class RoomReactor : MonoBehaviour
    {
        [Tooltip("連動させるライト")]
        [SerializeField] List<Light> lights = new List<Light>();
        [Tooltip("光らせる床 (溶岩のひびなど、自分で光る質感のもの)")]
        [SerializeField] Renderer floor;
        [Tooltip("いちばん強いときに、ライトを何倍にするか")]
        [SerializeField] float lightBoost = 3f;
        [Tooltip("いちばん強いときに、床の光を何倍にするか")]
        [SerializeField] float floorBoost = 4f;

        static readonly int EmissionId = Shader.PropertyToID("_EmissionColor");

        readonly List<float> baseIntensity = new List<float>();
        readonly List<Color> baseColor = new List<Color>();
        Color baseEmission;
        Color pendingTint, appliedTint; // 寄せる色 (いちばん強い作品のもの)
        MaterialPropertyBlock block;
        float pending;   // このフレームに届いた強さ (いちばん強いもの)
        float applied;   // いま反映している強さ

        public void Setup(List<Light> roomLights, Renderer floorRenderer, float lightGain, float floorGain)
        {
            lights = roomLights;
            floor = floorRenderer;
            lightBoost = lightGain;
            floorBoost = floorGain;
        }

        void OnEnable()
        {
            DioramaWork.Pulse += OnPulse;
        }

        void OnDisable()
        {
            DioramaWork.Pulse -= OnPulse;
            Apply(0f);
        }

        void Start()
        {
            baseIntensity.Clear();
            baseColor.Clear();
            foreach (var l in lights)
            {
                baseIntensity.Add(l != null ? l.intensity : 0f);
                baseColor.Add(l != null ? l.color : Color.white);
            }
            if (floor != null && floor.sharedMaterial != null && floor.sharedMaterial.HasProperty(EmissionId))
                baseEmission = floor.sharedMaterial.GetColor(EmissionId);
            block = new MaterialPropertyBlock();
        }

        // この部屋の中のジオラマからの知らせだけを受け取る
        void OnPulse(DioramaWork work, float value)
        {
            if (work == null || !work.transform.IsChildOf(transform) || value < pending) return;
            pending = value;
            pendingTint = work.Tint;
        }

        void LateUpdate()
        {
            if (pending > 0f || applied > 0f)
            {
                if (pending > 0f) appliedTint = pendingTint;
                Apply(pending);
            }
            pending = 0f;
        }

        void Apply(float v)
        {
            applied = v;
            // ゆらめき: 2つの速さの波を重ねて、炎のように不規則に揺らす
            float flicker = 1f + 0.25f * Mathf.Sin(Time.time * 11f) * Mathf.Sin(Time.time * 4.3f) * v;
            float tint = appliedTint.a * v;
            var tintColor = new Color(appliedTint.r, appliedTint.g, appliedTint.b, 1f);
            for (int i = 0; i < lights.Count && i < baseIntensity.Count; i++)
            {
                if (lights[i] == null) continue;
                lights[i].intensity = baseIntensity[i] * (1f + (lightBoost - 1f) * v) * flicker;
                lights[i].color = Color.Lerp(baseColor[i], tintColor, tint);
            }

            if (floor != null && block != null)
            {
                floor.GetPropertyBlock(block);
                // 床の光も、明るさはそのままで色だけ寄せる
                Color emission = Color.Lerp(baseEmission, tintColor * baseEmission.maxColorComponent, tint);
                block.SetColor(EmissionId, emission * (1f + (floorBoost - 1f) * v) * flicker);
                floor.SetPropertyBlock(block);
            }
        }
    }
}
