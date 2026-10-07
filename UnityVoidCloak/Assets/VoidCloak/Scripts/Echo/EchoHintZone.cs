using UnityEngine;

namespace EchoKnight
{
    /// <summary>
    /// Shows a line of story and / or an instruction while the knight is inside this box.
    /// </summary>
    [DisallowMultipleComponent]
    public class EchoHintZone : MonoBehaviour
    {
        [SerializeField] private Vector3 size = new Vector3(8f, 6f, 8f);
        [SerializeField] private string speaker = "";
        [SerializeField, TextArea(1, 3)] private string line = "";
        [SerializeField, TextArea(1, 3)] private string instruction = "";

        float alpha;

        public void Setup(Vector3 zoneSize, string zoneSpeaker, string zoneLine, string zoneInstruction)
        {
            size = zoneSize;
            speaker = zoneSpeaker ?? "";
            line = zoneLine ?? "";
            instruction = zoneInstruction ?? "";
        }

        void Update()
        {
            EchoPlayer player = EchoPlayer.Current;
            bool inside = player != null && new Bounds(transform.position, size).Contains(player.transform.position + Vector3.up);
            alpha = Mathf.MoveTowards(alpha, inside ? 1f : 0f, Time.deltaTime * 2f);
        }

        void OnGUI()
        {
            if (alpha > 0.01f) EchoScreenText.Draw(speaker, line, instruction, alpha);
        }

        void OnDrawGizmos()
        {
            Gizmos.color = new Color(0.4f, 0.8f, 1f, 0.6f);
            Gizmos.DrawWireCube(transform.position, size);
        }
    }
}
