using UnityEngine;

namespace BlindSpot
{
    /// <summary>床に落ちている投擲物。E で拾う。</summary>
    public class ItemPickup : MonoBehaviour, IInteractable
    {
        [SerializeField] ThrowableType type;

        public void Setup(ThrowableType newType)
        {
            type = newType;
        }

        public string GetPrompt(PlayerInteractor who)
        {
            if (who.Thrower == null) return null;
            string name = ThrowableDefs.DisplayName(type);
            return who.Thrower.CanAdd ? $"拾う({name})" : $"これ以上持てない({ThrowableDefs.MaxCarry}個まで)";
        }

        public void Interact(PlayerInteractor who)
        {
            if (who.Thrower == null || !who.Thrower.CanAdd) return;
            // 見た目 (マテリアル) も渡しておくと、投げるときに同じ見た目で作れる
            var renderer = GetComponent<Renderer>();
            who.Thrower.Add(type, renderer != null ? renderer.sharedMaterial : null);
            Destroy(gameObject);
        }
    }
}
