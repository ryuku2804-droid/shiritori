using UnityEngine;
using VoidCloak;

namespace EchoKnight
{
    /// <summary>
    /// Esc (gamepad Start) pauses the game: つづける / タイトルへもどる.
    /// Put it on any object in a stage scene (the stage builder puts it on the stage info object).
    /// </summary>
    [DisallowMultipleComponent]
    public class EchoPauseMenu : MonoBehaviour
    {
        static readonly string[] Items = { "つづける", "タイトルへもどる" };

        int selected;
        VoidCloakFollowCamera followCamera;

        void OnDisable()
        {
            if (EchoGame.Paused) SetPaused(false);
        }

        void Update()
        {
            if (EchoSceneFader.Busy) return;
            if (EchoMenuInput.PauseToggle())
            {
                SetPaused(!EchoGame.Paused);
                return;
            }
            if (!EchoGame.Paused) return;

            int move = EchoMenuInput.Vertical();
            if (move != 0) selected = (selected + move + Items.Length) % Items.Length;
            if (EchoMenuInput.Confirm()) Choose(selected);
        }

        void SetPaused(bool paused)
        {
            EchoGame.SetPaused(paused);
            selected = 0;
            // the camera would still turn with the mouse; hold it still while paused
            if (followCamera == null) followCamera = FindObjectOfType<VoidCloakFollowCamera>();
            if (followCamera != null) followCamera.enabled = !paused;
        }

        void Choose(int index)
        {
            if (index == 0)
            {
                SetPaused(false);
            }
            else
            {
                if (followCamera != null) followCamera.enabled = true;
                EchoGame.BackToTitle();   // the fader unpauses when the title scene loads
            }
        }

        void OnGUI()
        {
            if (!EchoGame.Paused) return;
            EchoScreenText.DrawTitle("一時停止", null, 0.9f);
            int clicked = EchoMenuDraw.Draw(Items, null, selected, Screen.height * 0.62f, 1f);
            if (clicked >= 0) Choose(clicked);
        }
    }
}
