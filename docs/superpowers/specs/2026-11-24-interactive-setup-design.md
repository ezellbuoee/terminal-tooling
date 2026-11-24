# Design: interactive setup (background, panes, sidebar tool)

Date: 2026-11-24

## Intent
Let a user choose their wallpaper, the number of panes, and the tool shown in the
sidebar through a few prompts, at install time and again later, without editing
Zellij or Ghostty config by hand. Choices must survive updates.

## Goals
- `terminal-tooling setup` (and `./setup.sh`): numbered prompts, Enter keeps the default.
- Answers live in `~/.config/terminal-tooling/setup.conf` (shell `KEY=value`), never
  overwritten by an install, only by running setup again.
- Every install re-applies the answers after copying the config folders, so
  `brew upgrade && terminal-tooling configs` keeps the user's layout and wallpaper.
- A plain `install` asks the questions once when stdin is a terminal and no
  setup.conf exists; otherwise defaults are written silently.
- Defaults reproduce today's shipped setup exactly (3 panes, yazi, yujiro wallpaper).

## Non-goals
- Choosing install units here (that stays `--skip/--only`).
- A full-screen TUI; plain `read` prompts, bash 3.2.
- Editing anything in the layouts outside the pane block.

## Choices
| key | values | default |
|---|---|---|
| `TT_BACKGROUND` | path to an image, or `none` | `~/Pictures/ghostty/yujiro-demon-back.jpg` |
| `TT_PANES` | `2` (sidebar + work) or `3` (sidebar + work + shell) | `3` |
| `TT_SIDEBAR` | `yazi` `lazygit` `btop` `shell` | `yazi` |

## How it is applied
- The shipped `config/zellij/layouts/dev.kdl` and `dev-tab.kdl` carry the pane block
  between `// tt:panes-begin` and `// tt:panes-end`. `setup.sh --apply` regenerates
  only that block in the installed copies. Widths: 3 panes 22/56/22, 2 panes 25/75.
  The sidebar pane keeps the name `files` and `borderless=true`; its command is
  `files-pane` for yazi, `lazygit`/`btop` for those, none for `shell`.
- Ghostty: the `background-image =` line in the installed config is rewritten to the
  chosen path, or commented out (`#background-image = ...`) for `none`.
- Files that are not installed (unit skipped) are left alone, without error.
- `backup.sh` no longer copies the two layout files back into the repo, so a personal
  layout choice cannot overwrite the shipped template.

## Approaches considered
1. Generate the pane block from answers between markers (chosen): small, idempotent,
   leaves the status-bar config untouched, defaults are byte-identical to the shipped files.
2. Ship one layout file per combination: 8 near-identical files to maintain.
3. Template with placeholders and `envsubst`: needs a template plus a rendered copy in
   the repo, and the shipped file would stop being usable as-is.

## Left to the builder
Prompt wording; how the wallpaper list is numbered (shipped images in
`~/Pictures/ghostty`, falling back to the repo's `pictures/ghostty`).
