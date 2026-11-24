# Interactive setup — Implementation Plan

**Goal:** `setup.sh` asks background / panes / sidebar, stores answers in `~/.config/terminal-tooling/setup.conf`, and regenerates the Zellij pane block and the Ghostty background line; the installer applies it on every run.
**Spec:** docs/superpowers/specs/2026-11-24-interactive-setup-design.md
**Constraints:** bash 3.2; tests hermetic (temp HOME, piped stdin); defaults byte-identical to shipped layouts.

### Task 1: markers + setup.sh + tests/test_setup.sh
- Add `// tt:panes-begin` / `// tt:panes-end` around the pane block in both shipped layouts.
- `setup.sh [--apply | --defaults]`: functions `ask`, `write_conf`, `read_conf`, `render_panes`, `apply_zellij`, `apply_ghostty`.
- Tests: defaults → conf + layouts identical to shipped; piped answers (own image, 2 panes, lazygit); `none` background toggles comment; invalid path re-prompts; missing zellij config tolerated; apply idempotent.

### Task 2: installer + command + backup + README
- `install.sh`: after the path rewrite, `setup.sh --defaults` (or interactive ask when `-t 0` and no conf) then `setup.sh --apply`; tests: non-tty run → defaults; pre-existing conf with panes=2 → regenerated after rsync.
- `bin/terminal-tooling setup`; help text; `backup.sh` excludes the two layout files; README "Setup mode".
