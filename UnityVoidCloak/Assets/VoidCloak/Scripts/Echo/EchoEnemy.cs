using System.Collections.Generic;
using UnityEngine;

namespace EchoKnight
{
    /// <summary>Anything the knight's sword can hit and parry.</summary>
    public interface IEchoEnemy
    {
        bool IsAlive { get; }
        Vector3 Position { get; }
        /// <summary>Damage from the knight's sword.</summary>
        void TakeHit(float damage, Vector3 from);
        /// <summary>Called when the knight parries this enemy's blow.</summary>
        void Stun(float seconds);
    }

    /// <summary>Every enemy in the scene (used by the knight's attacks).</summary>
    public static class EchoEnemies
    {
        static readonly List<IEchoEnemy> all = new List<IEchoEnemy>();

        public static IReadOnlyList<IEchoEnemy> All { get { return all; } }

        public static void Register(IEchoEnemy enemy)
        {
            if (!all.Contains(enemy)) all.Add(enemy);
        }

        public static void Unregister(IEchoEnemy enemy)
        {
            all.Remove(enemy);
        }
    }
}
