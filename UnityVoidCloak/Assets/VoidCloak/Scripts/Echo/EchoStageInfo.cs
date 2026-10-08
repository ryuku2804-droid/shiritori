using UnityEngine;

namespace EchoKnight
{
    /// <summary>
    /// One per stage scene: which chapter this is. When the stage starts it shows the chapter
    /// title, saves the progress, and - if the player chose "continue" on the title screen -
    /// puts the knight back at the saved bell shrine. The goal calls <see cref="FinishChapter"/>.
    /// </summary>
    [DisallowMultipleComponent]
    public class EchoStageInfo : MonoBehaviour
    {
        [Tooltip("Index into EchoGame.Chapters (0 = prologue). -1 = a test stage that is not part of the game.")]
        [SerializeField] private int chapterIndex = -1;
        [SerializeField, Min(0f)] private float titleSeconds = 4.5f;

        float startTime;
        bool finishing;

        public static EchoStageInfo Current { get; private set; }
        public int ChapterIndex { get { return chapterIndex; } }

        public void Setup(int index)
        {
            chapterIndex = index;
        }

        void OnEnable()
        {
            Current = this;
        }

        void OnDisable()
        {
            if (Current == this) Current = null;
        }

        void Start()
        {
            startTime = Time.time;
            string shrineName;
            if (EchoGame.TakePendingShrine(out shrineName) && ResumeAt(shrineName))
            {
                titleSeconds = 0f;   // coming back: no title card
                return;
            }
            if (chapterIndex >= 0) EchoGame.SaveChapterStart(chapterIndex);
        }

        bool ResumeAt(string shrineName)
        {
            foreach (EchoBellShrine shrine in FindObjectsOfType<EchoBellShrine>())
            {
                if (shrine.gameObject.name != shrineName) continue;
                shrine.ResumeHere();
                return true;
            }
            return false;
        }

        /// <summary>Called by the goal once its title has been shown.</summary>
        public void FinishChapter()
        {
            if (finishing) return;
            finishing = true;
            EchoGame.CompleteChapter(chapterIndex);
        }

        void OnGUI()
        {
            if (chapterIndex < 0 || chapterIndex >= EchoGame.Chapters.Length || titleSeconds <= 0f) return;
            float t = Time.time - startTime;
            if (t > titleSeconds) return;
            float alpha = Mathf.Clamp01((t - 0.8f) / 1.2f) * Mathf.Clamp01((titleSeconds - t) / 1.2f);
            if (alpha > 0.01f) EchoScreenText.DrawTitle(EchoGame.Chapters[chapterIndex].title, null, alpha);
        }
    }
}
