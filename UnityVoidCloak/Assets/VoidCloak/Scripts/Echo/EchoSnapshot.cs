using System.Collections.Generic;
using System.Globalization;
using System.Text;
using UnityEngine;

namespace EchoKnight
{
    /// <summary>Something whose state belongs to the save: an enemy (alive / dead, where), a wall, a door.</summary>
    public interface IEchoSaveable
    {
        /// <summary>Unique in the scene (the GameObject name).</summary>
        string SaveKey { get; }
        string Capture();
        void Restore(string state);
    }

    /// <summary>
    /// The state of the world at the last save (a bell shrine rung, or the start of a chapter).
    /// When the knight falls, time goes back to that moment: enemies killed before it stay dead,
    /// enemies killed after it are back where they were; walls broken and doors opened after it
    /// are whole and shut again. The snapshot is also written to the save, so "continue" restores it.
    /// </summary>
    public static class EchoSnapshot
    {
        const string KeyWorld = "EchoKnight.World";

        static readonly List<IEchoSaveable> all = new List<IEchoSaveable>();
        static Dictionary<string, string> last = new Dictionary<string, string>();

        public static readonly CultureInfo Inv = CultureInfo.InvariantCulture;

        public static void Register(IEchoSaveable s)
        {
            if (!all.Contains(s)) all.Add(s);
        }

        public static void Unregister(IEchoSaveable s)
        {
            all.Remove(s);
        }

        /// <summary>Remember the world as it is now (and write it to the save when asked).</summary>
        public static void Capture(bool writeToSave)
        {
            last = new Dictionary<string, string>();
            foreach (IEchoSaveable s in all) last[s.SaveKey] = s.Capture();
            if (!writeToSave) return;
            PlayerPrefs.SetString(KeyWorld, Serialize(last));
            PlayerPrefs.Save();
        }

        /// <summary>Back to the remembered moment (the knight fell).</summary>
        public static void RestoreLast()
        {
            Apply(last);
        }

        /// <summary>"Continue": the world as it was saved.</summary>
        public static void RestoreFromSave()
        {
            Apply(Deserialize(PlayerPrefs.GetString(KeyWorld, "")));
        }

        public static void ClearSave()
        {
            PlayerPrefs.SetString(KeyWorld, "");
        }

        static void Apply(Dictionary<string, string> states)
        {
            if (states == null) return;
            foreach (IEchoSaveable s in all.ToArray())
            {
                string state;
                if (states.TryGetValue(s.SaveKey, out state)) s.Restore(state);
            }
        }

        static string Serialize(Dictionary<string, string> d)
        {
            var sb = new StringBuilder();
            foreach (var kv in d) sb.Append(kv.Key.Replace("\n", " ").Replace("\t", " ")).Append('\t').Append(kv.Value).Append('\n');
            return sb.ToString();
        }

        static Dictionary<string, string> Deserialize(string text)
        {
            var d = new Dictionary<string, string>();
            if (string.IsNullOrEmpty(text)) return d;
            foreach (string line in text.Split('\n'))
            {
                int tab = line.IndexOf('\t');
                if (tab > 0) d[line.Substring(0, tab)] = line.Substring(tab + 1);
            }
            return d;
        }

        // ------------------------------------------------------------------ helpers for enemies

        /// <summary>"a|x|y|z|yaw|health" for a living enemy, "d" for a dead one.</summary>
        public static string Living(Transform t, float health)
        {
            Vector3 p = t.position;
            return string.Format(Inv, "a|{0}|{1}|{2}|{3}|{4}", p.x, p.y, p.z, t.eulerAngles.y, health);
        }

        public static bool ParseLiving(string state, out Vector3 position, out float yaw, out float health)
        {
            position = Vector3.zero;
            yaw = 0f;
            health = 0f;
            if (string.IsNullOrEmpty(state) || state[0] != 'a') return false;
            string[] p = state.Split('|');
            if (p.Length < 6) return false;
            position = new Vector3(float.Parse(p[1], Inv), float.Parse(p[2], Inv), float.Parse(p[3], Inv));
            yaw = float.Parse(p[4], Inv);
            health = float.Parse(p[5], Inv);
            return true;
        }
    }
}
