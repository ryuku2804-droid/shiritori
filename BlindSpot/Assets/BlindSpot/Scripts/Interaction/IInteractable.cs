namespace BlindSpot
{
    /// <summary>
    /// 「調べる」(E キー) で使えるものの約束ごと (インターフェース)。
    /// ロッカー・落ちている物・扉など、種類の違うものを同じ方法で扱えるようにする。
    /// </summary>
    public interface IInteractable
    {
        /// <summary>画面に出す説明 (例: 「ロッカーに隠れる」)。null なら調べられない。</summary>
        string GetPrompt(PlayerInteractor who);

        /// <summary>調べたときの処理。</summary>
        void Interact(PlayerInteractor who);
    }
}
