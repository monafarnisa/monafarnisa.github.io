# AGENTS.md

## Cursor Cloud specific instructions

This repository is a single static **Quarto website** (Mona Farnisa's personal/portfolio site). There is no backend, database, or long-running service — the only tooling required is the **Quarto CLI**. `quarto render`/`quarto preview` commands are standard (see [Quarto docs](https://quarto.org/)); config lives in `_quarto.yml`.

### Services / commands

- Build: `quarto render` — outputs the site to `docs/`.
- Dev server (run in development mode): `quarto preview --port 4200 --no-browser` — serves at `http://localhost:4200/`.
- There is no separate lint/test tooling in this repo; "build" is `quarto render`.

### Non-obvious gotchas

- `docs/` is committed and is the GitHub Pages publish folder (`output-dir: docs`). Running `quarto render` or `quarto preview` **regenerates `docs/` and deletes files there that are not produced by the render** — including the hand-maintained `docs/professional/` micro-site and other committed assets. After building/previewing for verification only, revert with `git checkout -- docs && git clean -fd docs` so you don't accidentally commit destructive output-dir changes. Only commit `docs/` when you intentionally mean to publish.
- The `.qmd` files contain **no executable code chunks** (only static ```` ```python ````/```` ```r ```` display blocks, not ```` ```{python} ````/```` ```{r} ````). So R and Jupyter are **not needed** to build the site, despite the presence of `requirements.txt` and `monafarnisa.Rproj`. `quarto check` will report R/Jupyter as "not available" — this is expected and harmless.
