"""コピペ用のソースページ (左: 説明と手順 / 右: コードだけ) を作る。

使い方:
    python3 DioramaMuseum/tools/make_source_page.py <段階の番号> <出力先.html>

段階ごとの中身は stepN.py に書く (STEP_* / FILES / NOTICE / OVERVIEW / museum_map / FLOW / SEE / PHASES / CHECKS / TROUBLE / NEXT)。
FILES の状態: "新規" = その回で初めて作るファイル / "変更" = 前回から書き換えたファイル / "そのまま" = 前回から変わっていない
"""
import html
import importlib
import json
import pathlib
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent  # DioramaMuseum/

TEMPLATE = (pathlib.Path(__file__).parent / "source_page_template.html").read_text(encoding="utf-8")


def main(step, out_path):
    st = importlib.import_module(f"step{step}")
    files = []
    for rel, status, desc in st.FILES:
        src = (ROOT / rel).read_text(encoding="utf-8")
        p = pathlib.PurePosixPath(rel)
        files.append({
            "name": p.name,
            "folder": str(p.parent) + "/",
            "status": status,
            "desc": desc,
            "lines": src.count("\n") + (0 if src.endswith("\n") else 1),
            "code": src,
        })
    payload = {"notice": getattr(st, "NOTICE", None), "files": files, "overview": st.OVERVIEW, "map": st.museum_map(),
               "flow": st.FLOW, "see": st.SEE, "phases": st.PHASES, "checks": st.CHECKS, "trouble": st.TROUBLE,
               "next": st.NEXT}
    data = json.dumps(payload, ensure_ascii=False).replace("</", "<\\/")
    page = (TEMPLATE
            .replace("{{STEP_LABEL}}", html.escape(st.STEP_LABEL))
            .replace("{{STEP_TITLE}}", html.escape(st.STEP_TITLE))
            .replace("{{DATA}}", data))
    pathlib.Path(out_path).write_text(page, encoding="utf-8")
    print(f"wrote {out_path} ({len(files)} files)")


if __name__ == "__main__":
    sys.path.insert(0, str(pathlib.Path(__file__).parent))
    main(sys.argv[1] if len(sys.argv) > 1 else "1", sys.argv[2] if len(sys.argv) > 2 else "source.html")
