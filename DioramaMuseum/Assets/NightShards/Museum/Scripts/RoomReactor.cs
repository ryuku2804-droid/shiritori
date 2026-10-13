using System.Collections.Generic;
using UnityEngine;

namespace NightShards.Museum
{
    // 部屋とジオラマの連動。展示室に付ける。
    // この部屋のジオラマの仕掛けが動くと (DioramaWork.Pulse)、部屋の照明と床の光が一緒に強く脈打つ。
    // 例: 火の間で大噴火すると、床の溶岩のひびと赤い照明が一斉に明るくなる
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
        Color baseEmission;
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
            foreach (var l in lights) baseIntensity.Add(l != null ? l.intensity : 0f);
            if (floor != null && floor.sharedMaterial != null && floor.sharedMaterial.HasProperty(EmissionId))
                baseEmission = floor.sharedMaterial.GetColor(EmissionId);
            block = new MaterialPropertyBlock();
        }

        // この部屋の中のジオラマからの知らせだけを受け取る
        void OnPulse(DioramaWork work, float value)
        {
            if (work != null && work.transform.IsChildOf(transform)) pending = Mathf.Max(pending, value);
        }

        void LateUpdate()
        {
            if (pending > 0f || applied > 0f) Apply(pending);
            pending = 0f;
        }

        void Apply(float v)
        {
            applied = v;
            // ゆらめき: 2つの速さの波を重ねて、炎のように不規則に揺らす
            float flicker = 1f + 0.25f * Mathf.Sin(Time.time * 11f) * Mathf.Sin(Time.time * 4.3f) * v;
            for (int i = 0; i < lights.Count && i < baseIntensity.Count; i++)
                if (lights[i] != null) lights[i].intensity = baseIntensity[i] * (1f + (lightBoost - 1f) * v) * flicker;

            if (floor != null && block != null)
            {
                floor.GetPropertyBlock(block);
                block.SetColor(EmissionId, baseEmission * (1f + (floorBoost - 1f) * v) * flicker);
                floor.SetPropertyBlock(block);
            }
        }
    }
}
