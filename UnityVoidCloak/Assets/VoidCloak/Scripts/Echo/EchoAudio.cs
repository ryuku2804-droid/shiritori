using System.Collections.Generic;
using UnityEngine;

namespace EchoKnight
{
    /// <summary>
    /// Plays the game's sounds in 3D. The clips are synthesised once at start
    /// (<see cref="EchoSoundSynth"/>), so no audio files are needed.
    ///
    /// A stone-hall reverb is put on the AudioListener so every sound really echoes,
    /// and a quiet wind loop plays in the background. Headphones recommended.
    /// One is created automatically the first time a sound plays.
    /// </summary>
    [DisallowMultipleComponent]
    public class EchoAudio : MonoBehaviour
    {
        [SerializeField, Range(0f, 1f)] private float masterVolume = 0.9f;
        [SerializeField, Range(0f, 1f)] private float ambienceVolume = 0.18f;
        [Tooltip("Reverb on the listener (Cave / StoneCorridor / Hallway suit the game).")]
        [SerializeField] private AudioReverbPreset reverb = AudioReverbPreset.StoneCorridor;
        [Tooltip("Sounds are heard at full volume up to this distance.")]
        [SerializeField, Min(0.1f)] private float minDistance = 4f;
        [Tooltip("Sounds fade out completely at this distance.")]
        [SerializeField, Min(1f)] private float maxDistance = 90f;
        [SerializeField, Range(4, 64)] private int voices = 24;

        static EchoAudio instance;
        AudioClip[][] clips;
        readonly List<AudioSource> pool = new List<AudioSource>();
        int nextVoice;
        AudioSource ambience;

        /// <summary>Plays a sound at a world position.</summary>
        /// <param name="volume">0..1 (multiplied by the master volume).</param>
        /// <param name="pitch">1 = normal; a small random variation is added.</param>
        /// <param name="delay">Seconds to wait before playing.</param>
        public static void Play(EchoSound sound, Vector3 position, float volume = 1f, float pitch = 1f, float delay = 0f)
        {
            if (!Application.isPlaying) return;
            EchoAudio a = Ensure();
            if (a != null) a.PlayAt(sound, position, volume, pitch, delay);
        }

        public static EchoAudio Ensure()
        {
            if (instance == null && Application.isPlaying)
            {
                var go = new GameObject("EchoAudio");
                instance = go.AddComponent<EchoAudio>();
            }
            return instance;
        }

        void Awake()
        {
            if (instance != null && instance != this) { Destroy(this); return; }
            instance = this;
            BuildClips();
            BuildPool();
        }

        void Start()
        {
            SetupListener();
        }

        void OnDestroy()
        {
            if (instance == this) instance = null;
            if (clips == null) return;
            foreach (AudioClip[] set in clips)
                foreach (AudioClip c in set)
                    if (c != null) Destroy(c);
        }

        void BuildClips()
        {
            clips = new AudioClip[(int)EchoSound.Count][];
            for (int s = 0; s < (int)EchoSound.Count; s++)
            {
                var sound = (EchoSound)s;
                int n = EchoSoundSynth.Variants(sound);
                clips[s] = new AudioClip[n];
                for (int v = 0; v < n; v++)
                {
                    float[] data = EchoSoundSynth.Generate(sound, v);
                    AudioClip clip = AudioClip.Create(sound + "_" + v, data.Length, 1, EchoSoundSynth.SampleRate, false);
                    clip.SetData(data, 0);
                    clips[s][v] = clip;
                }
            }
        }

        void BuildPool()
        {
            for (int i = 0; i < voices; i++)
            {
                var go = new GameObject("Voice " + i);
                go.transform.SetParent(transform, false);
                var src = go.AddComponent<AudioSource>();
                src.playOnAwake = false;
                src.spatialBlend = 1f;
                src.rolloffMode = AudioRolloffMode.Logarithmic;
                src.minDistance = minDistance;
                src.maxDistance = maxDistance;
                src.dopplerLevel = 0f;
                pool.Add(src);
            }
        }

        /// <summary>Reverb on the listener so every sound echoes, and the ambience loop.</summary>
        void SetupListener()
        {
            Camera cam = Camera.main;
            AudioListener listener = cam != null ? cam.GetComponent<AudioListener>() : null;
            if (listener != null && listener.GetComponent<AudioReverbFilter>() == null)
            {
                var filter = listener.gameObject.AddComponent<AudioReverbFilter>();
                filter.reverbPreset = reverb;
            }

            var amb = new GameObject("Ambience");
            amb.transform.SetParent(transform, false);
            ambience = amb.AddComponent<AudioSource>();
            ambience.clip = clips[(int)EchoSound.Ambience][0];
            ambience.loop = true;
            ambience.spatialBlend = 0f;
            ambience.volume = ambienceVolume * masterVolume;
            ambience.Play();
        }

        void PlayAt(EchoSound sound, Vector3 position, float volume, float pitch, float delay)
        {
            AudioClip[] set = clips[(int)sound];
            if (set == null || set.Length == 0) return;

            // reuse the next voice that is free, or the oldest one
            AudioSource src = null;
            for (int i = 0; i < pool.Count; i++)
            {
                AudioSource candidate = pool[(nextVoice + i) % pool.Count];
                if (!candidate.isPlaying) { src = candidate; nextVoice = (nextVoice + i + 1) % pool.Count; break; }
            }
            if (src == null) { src = pool[nextVoice]; nextVoice = (nextVoice + 1) % pool.Count; }

            src.transform.position = position;
            src.clip = set[Random.Range(0, set.Length)];
            src.volume = Mathf.Clamp01(volume) * masterVolume;
            src.pitch = pitch * Random.Range(0.94f, 1.06f);
            if (delay > 0f) src.PlayDelayed(delay);
            else src.Play();
        }
    }
}
