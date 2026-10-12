using UnityEngine;

namespace BlindSpot
{
    /// <summary>
    /// 机やベッドの下のような「しゃがめば隠れられる場所」。
    /// 範囲の中でしゃがんでいる間、プレイヤーは隠れている扱いになる。
    /// </summary>
    public class HideZone : MonoBehaviour
    {
        [Tooltip("隠れられる範囲の大きさ (このオブジェクトの位置が中心)")]
        [SerializeField] Vector3 size = new Vector3(1.4f, 1.2f, 0.7f);

        PlayerController player;
        bool hiding;

        void Start()
        {
            player = FindFirstObjectByType<PlayerController>();
        }

        void Update()
        {
            if (player == null) return;

            // プレイヤーの足元の位置を、この範囲から見た座標 (回転込み) に直して、箱の中にあるか調べる
            Vector3 local = transform.InverseTransformPoint(player.transform.position);
            bool inside = Mathf.Abs(local.x) <= size.x / 2f &&
                          Mathf.Abs(local.y) <= size.y / 2f &&
                          Mathf.Abs(local.z) <= size.z / 2f;
            bool now = inside && player.IsCrouching;

            if (now == hiding) return;
            hiding = now;
            player.SetHidden(now);
        }

        void OnDisable()
        {
            if (hiding && player != null) player.SetHidden(false);
            hiding = false;
        }

        void OnDrawGizmos()
        {
            Gizmos.color = new Color(0.4f, 1f, 0.5f, 0.6f);
            Gizmos.matrix = transform.localToWorldMatrix;
            Gizmos.DrawWireCube(Vector3.zero, size);
        }
    }
}
