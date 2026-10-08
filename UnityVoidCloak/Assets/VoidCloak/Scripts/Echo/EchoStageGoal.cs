using UnityEngine;

namespace EchoKnight
{
    /// <summary>
    /// The end of a stage: reaching it rings out a great golden echo and shows the chapter title.
    /// Then the next chapter is loaded (see <see cref="EchoStageInfo"/>).
    /// </summary>
    [DisallowMultipleComponent]
    public class EchoStageGoal : MonoBehaviour
    {
        [SerializeField] private Vector3 size = new Vector3(6f, 5f, 4f);
        [SerializeField] private string title = "";
        [SerializeField] private string subtitle = "";
        [SerializeField, Min(1f)] private float showSeconds = 10f;

        float reachedTime = -1f;

        public bool Reached { get { return reachedTime >= 0f; } }

        public void Setup(Vector3 zoneSize, string goalTitle, string goalSubtitle)
        {
            size = zoneSize;
            title = goalTitle;
            subtitle = goalSubtitle;
        }

        void Update()
        {
            if (Reached)
            {
                // after the title: on to the next chapter (when this stage is part of the game)
                if (Time.time - reachedTime >= showSeconds && EchoStageInfo.Current != null) EchoStageInfo.Current.FinishChapter();
                return;
            }
            EchoPlayer player = EchoPlayer.Current;
            if (player == null) return;
            if (!new Bounds(transform.position, size).Contains(player.transform.position + Vector3.up)) return;

            reachedTime = Time.time;
            EchoSystem.Emit(transform.position, 90f, EchoSource.Bell, 1.3f);
            EchoAudio.Play(EchoSound.ShrineBell, transform.position + Vector3.up * 3f, 1f, 0.8f);
        }

        void OnGUI()
        {
            if (!Reached) return;
            float t = Time.time - reachedTime;
            float alpha = Mathf.Clamp01(t / 1.5f) * Mathf.Clamp01((showSeconds - t) / 2f);
            if (alpha > 0.01f) EchoScreenText.DrawTitle(title, subtitle, alpha);
        }

        void OnDrawGizmos()
        {
            Gizmos.color = new Color(1f, 0.8f, 0.3f, 0.7f);
            Gizmos.DrawWireCube(transform.position, size);
        }
    }
}
