using System.Collections.Generic;
using UnityEngine;

namespace EchoKnight
{
    /// <summary>
    /// An enemy's attack made of sound: a red ring that spreads slowly from the enemy.
    /// It kills the knight when its front reaches him, unless
    ///   - he parries (Q / LB) just as the front arrives: the ring is thrown back and
    ///     hits its owner (damage + stun), or
    ///   - something solid (a pillar, a wall) stands between him and where it started.
    /// The knight's <see cref="EchoCombat"/> resolves the rings against himself.
    /// </summary>
    public sealed class EchoShockwave
    {
        public Vector3 origin;
        public float startTime;
        public float speed;
        public float radius;
        public IEchoEnemy owner;
        public bool resolved;

        /// <summary>When the front reaches a point (flat distance).</summary>
        public float ArrivalTime(Vector3 p)
        {
            Vector3 d = p - origin;
            d.y = 0f;
            return startTime + d.magnitude / speed;
        }

        public bool Reaches(Vector3 p)
        {
            Vector3 d = p - origin;
            d.y = 0f;
            return d.magnitude <= radius;
        }

        public bool Finished { get { return Time.time > startTime + radius / speed + 0.5f; } }
    }

    public static class EchoShockwaves
    {
        static readonly List<EchoShockwave> active = new List<EchoShockwave>();

        public static List<EchoShockwave> Active
        {
            get
            {
                active.RemoveAll(w => w.Finished || w.startTime > Time.time + 1f);   // (the second test drops rings from a previous play session)
                return active;
            }
        }

        /// <summary>Fire a ring. It is also drawn: a red band of light sweeping over the floor and walls.</summary>
        public static EchoShockwave Fire(Vector3 origin, IEchoEnemy owner, float radius, float speed)
        {
            var w = new EchoShockwave { origin = origin, startTime = Time.time, speed = speed, radius = radius, owner = owner };
            active.Add(w);
            EchoSystem.Emit(origin, radius, EchoSource.Enemy, 1.5f, speed);
            return w;
        }

        public static void Clear()
        {
            active.Clear();
        }
    }
}
