using System;
using UnityEngine;

namespace BlindSpot
{
    /// <summary>1歩分の情報。</summary>
    public readonly struct StepInfo
    {
        public readonly Vector3 Position;
        public readonly float Radius;       // 実際に届いた距離 (基本距離 × 床の倍率)
        public readonly MoveState State;
        public readonly SurfaceType Surface;

        public StepInfo(Vector3 position, float radius, MoveState state, SurfaceType surface)
        {
            Position = position;
            Radius = radius;
            State = state;
            Surface = surface;
        }
    }

    /// <summary>
    /// 歩いた距離が一定に達するごとに足音を鳴らし、NoiseSystem に通知する。
    /// 足音の届く距離 = 移動状態の基本距離 × 床の素材倍率
    /// </summary>
    [RequireComponent(typeof(PlayerController))]
    public class FootstepNoise : MonoBehaviour
    {
        [Serializable]
        public struct StepSetting
        {
            [Tooltip("1歩の歩幅 (m)。この距離を進むごとに足音が1回鳴る")]
            public float stride;
            [Tooltip("床が Default のときの足音の届く距離 (m)")]
            public float baseRadius;
            [Tooltip("効果音の音量 (0〜1)")]
            [Range(0f, 1f)] public float volume;

            public StepSetting(float stride, float baseRadius, float volume)
            {
                this.stride = stride;
                this.baseRadius = baseRadius;
                this.volume = volume;
            }
        }

        [Header("移動状態ごとの設定")]
        [SerializeField] StepSetting crouch = new StepSetting(0.5f, 1.5f, 0.15f);
        [SerializeField] StepSetting walk = new StepSetting(0.7f, 5f, 0.4f);
        [SerializeField] StepSetting run = new StepSetting(1.0f, 12f, 0.9f);

        [Header("床の判定")]
        [Tooltip("床として調べるレイヤー。Player レイヤーは外すこと")]
        [SerializeField] LayerMask groundMask = ~0;
        [SerializeField] float groundCheckDistance = 0.3f;

        [Header("効果音 (無くても動く)")]
        [SerializeField] AudioSource audioSource;
        [Tooltip("床に専用の音が無いときに使う足音")]
        [SerializeField] AudioClip[] defaultClips;

        /// <summary>足音が鳴るたびに呼ばれる (音の UI などで使う)。</summary>
        public event Action<StepInfo> OnStep;

        /// <summary>今立っている床の素材。</summary>
        public SurfaceType CurrentSurface { get; private set; } = SurfaceType.Default;

        /// <summary>最後に鳴った足音の届く距離。</summary>
        public float LastStepRadius { get; private set; }

        PlayerController player;
        SurfaceMaterial currentSurfaceComponent;
        Vector3 lastPosition;
        float distanceSinceStep;

        void Awake()
        {
            player = GetComponent<PlayerController>();
            lastPosition = transform.position;
        }

        void Update()
        {
            UpdateSurface();

            Vector3 pos = transform.position;
            Vector3 delta = pos - lastPosition;
            lastPosition = pos;

            if (!player.IsGrounded) return;

            delta.y = 0f;
            float moved = delta.magnitude;
            if (moved < 0.0001f) return;

            distanceSinceStep += moved;
            StepSetting setting = GetSetting(player.State);
            if (distanceSinceStep >= setting.stride)
            {
                distanceSinceStep = 0f;
                Step(setting);
            }
        }

        StepSetting GetSetting(MoveState state)
        {
            switch (state)
            {
                case MoveState.Crouch: return crouch;
                case MoveState.Run: return run;
                default: return walk; // Idle で少し滑ったときも歩き扱い
            }
        }

        void UpdateSurface()
        {
            Vector3 origin = transform.position + Vector3.up * 0.1f;
            if (Physics.Raycast(origin, Vector3.down, out RaycastHit hit, groundCheckDistance + 0.1f,
                    groundMask, QueryTriggerInteraction.Ignore))
            {
                currentSurfaceComponent = hit.collider.GetComponentInParent<SurfaceMaterial>();
            }
            else
            {
                currentSurfaceComponent = null;
            }
            CurrentSurface = currentSurfaceComponent != null ? currentSurfaceComponent.type : SurfaceType.Default;
        }

        void Step(StepSetting setting)
        {
            float multiplier = currentSurfaceComponent != null ? currentSurfaceComponent.Multiplier : 1f;
            float radius = setting.baseRadius * multiplier;
            LastStepRadius = radius;

            Vector3 pos = transform.position;
            NoiseSystem.Emit(pos, radius, NoiseType.Footstep, gameObject);
            PlaySound(setting.volume);
            OnStep?.Invoke(new StepInfo(pos, radius, player.State, CurrentSurface));
        }

        void PlaySound(float volume)
        {
            if (audioSource == null) return;
            AudioClip[] clips = currentSurfaceComponent != null && currentSurfaceComponent.footstepClips != null &&
                                currentSurfaceComponent.footstepClips.Length > 0
                ? currentSurfaceComponent.footstepClips
                : defaultClips;
            if (clips == null || clips.Length == 0) return;

            AudioClip clip = clips[UnityEngine.Random.Range(0, clips.Length)];
            if (clip == null) return;
            audioSource.pitch = UnityEngine.Random.Range(0.92f, 1.08f); // 毎回同じ音に聞こえないように
            audioSource.PlayOneShot(clip, volume);
        }
    }
}
