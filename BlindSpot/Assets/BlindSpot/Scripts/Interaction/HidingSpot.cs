using UnityEngine;

namespace BlindSpot
{
    /// <summary>
    /// ロッカー・棚の中に隠れる。E で入り、もう一度 E で出る。
    /// 中にいる間は捕まらないが、息をしていれば音は外に漏れる (怪物がすぐそばにいるときは息を止める)。
    /// </summary>
    public class HidingSpot : MonoBehaviour, IInteractable
    {
        [Tooltip("隠れているときのプレイヤーの位置と向き")]
        [SerializeField] Transform insidePoint;
        [Tooltip("出たときのプレイヤーの位置と向き")]
        [SerializeField] Transform exitPoint;
        [Tooltip("扉を開け閉めする音の届く距離 (m)")]
        [SerializeField] float doorNoiseRadius = 2.5f;

        PlayerInteractor occupant;

        public string GetPrompt(PlayerInteractor who)
        {
            if (occupant == who) return "出る";
            if (occupant == null) return "ロッカーに隠れる";
            return null; // ほかの誰かが入っている
        }

        public void Interact(PlayerInteractor who)
        {
            if (occupant == who) Exit();
            else if (occupant == null) Enter(who);
        }

        void Enter(PlayerInteractor who)
        {
            occupant = who;
            who.ActiveHidingSpot = this;
            who.Player.MovementEnabled = false; // 体を固定する (視点は動かせる)
            who.Player.Teleport(insidePoint.position, insidePoint.eulerAngles.y);
            who.Player.SetHidden(true);
            NoiseSystem.Emit(transform.position, doorNoiseRadius, NoiseType.Other, gameObject);
        }

        void Exit()
        {
            PlayerInteractor who = occupant;
            occupant = null;
            who.ActiveHidingSpot = null;
            who.Player.SetHidden(false);
            who.Player.Teleport(exitPoint.position, exitPoint.eulerAngles.y);
            who.Player.MovementEnabled = true;
            NoiseSystem.Emit(transform.position, doorNoiseRadius, NoiseType.Other, gameObject);
        }
    }
}
