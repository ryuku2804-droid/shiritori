using System.Collections.Generic;
using UnityEngine;

namespace EchoKnight
{
    /// <summary>Anything the knight's sword can strike: enemies, puzzle bells, hollow walls.</summary>
    public interface IEchoHittable
    {
        /// <summary>False once it can no longer be hit (dead enemy, broken wall).</summary>
        bool IsAlive { get; }
        Vector3 Position { get; }
        /// <summary>Damage from the knight's sword.</summary>
        void TakeHit(float damage, Vector3 from);
    }

    /// <summary>An enemy: can be hit, and its blows can be parried.</summary>
    public interface IEchoEnemy : IEchoHittable
    {
        /// <summary>Called when the knight parries this enemy's blow.</summary>
        void Stun(float seconds);
    }

    /// <summary>Everything in the scene the knight's sword can hit.</summary>
    public static class EchoTargets
    {
        static readonly List<IEchoHittable> all = new List<IEchoHittable>();

        public static IReadOnlyList<IEchoHittable> All { get { return all; } }

        public static void Register(IEchoHittable target)
        {
            if (!all.Contains(target)) all.Add(target);
        }

        public static void Unregister(IEchoHittable target)
        {
            all.Remove(target);
        }
    }
}
