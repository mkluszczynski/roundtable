# UI Design System — Roundtable panel

Companion to `DESIGN-DOC.md` (product/architecture spec). This file is the
source of truth for **visual design**: colors, typography, component
patterns, and per-screen layout for `roundtable_flutter`.

The mockups this file describes were built as a Design canvas (7 artboards
covering the task lifecycle, machine/agent/project onboarding). That canvas
is a private Claude Artifact, not part of this repo — this file is the
portable, implementation-ready extract of it. Nothing here depends on
having access to that canvas.

Currently `roundtable_flutter` uses the stock Serverpod scaffold theme
(`ColorScheme.fromSeed(seedColor: Colors.blue)` in `lib/main.dart`) and
default Material widgets throughout. Nothing described below is wired up
yet — this is the target to implement against.

## 1. Design tokens

### Palette

Dark theme only for the panel (this is a dev tool, not a marketing site).
Base is true black; one violet accent for anything that needs the dev's
attention or action; lime for "the agent is actively working" / success;
red for destructive/error. Avoid introducing other hues.

| Token | Hex | Flutter `Color` | Use |
|---|---|---|---|
| `bg0` | `#000000` | `Color(0xFF000000)` | Page/canvas background |
| `bg1` | `#131316` | `Color(0xFF131316)` | Panels, nav rail, sidebars, cards, modals |
| `bg2` | `#1C1C21` | `Color(0xFF1C1C21)` | Nested surfaces (inputs, code block chrome, tags) |
| `bg3` | `#26262C` | `Color(0xFF26262C)` | Track/inactive fill (progress bars, count pills) |
| `border` | `rgba(255,255,255,.10)` | `Colors.white.withOpacity(0.10)` | Default hairline border |
| `borderStrong` | `rgba(255,255,255,.22)` | `Colors.white.withOpacity(0.22)` | Emphasized border (modals, selected state) |
| `text0` | `#FFFFFF` | `Colors.white` | Primary text |
| `text1` | `#A0A0A8` | `Color(0xFFA0A0A8)` | Secondary text, labels |
| `text2` | `#6B6B72` | `Color(0xFF6B6B72)` | Tertiary/dim text, timestamps, placeholders |
| `accent` | `#7D39EB` | `Color(0xFF7D39EB)` | Primary CTA, brand mark, "needs your attention" |
| `accentInk` | `#FFFFFF` | `Colors.white` | Text/icon on top of `accent` |
| `accentSoft` | `#A78BFA` | `Color(0xFFA78BFA)` | Accent text on tinted/dark backgrounds, links |
| `live` | `#C6FF33` | `Color(0xFFC6FF33)` | "Agent is working" / success / diff additions |
| `liveInk` | `#0A1400` | `Color(0xFF0A1400)` | Text/icon on top of `live` |
| `red` | `#FF3D57` | `Color(0xFFFF3D57)` | Cancel/destructive/error, diff deletions |

Recommended `ColorScheme` mapping (replace the seeded blue in `main.dart`):
`primary: accent`, `onPrimary: accentInk`, `secondary: live`,
`onSecondary: liveInk`, `error: red`, `surface: bg1`, `onSurface: text0`,
`surfaceContainerHighest: bg2`, `outline: border`. Only build `darkTheme`
seriously; `themeMode` can stay `ThemeMode.dark` for this app rather than
following system light/dark.

### Semantic status colors

Map enum values to colors consistently everywhere a status renders
(dashboard cards, task detail header, machine list):

| Enum | Value | Color | Notes |
|---|---|---|---|
| `MachineStatus` | `online` | `live` | dot, no pulse |
| | `offline` | `text2` (dim gray) | |
| `AgentStatus` | `idle` | `text2` | |
| | `busy` | `live`, pulsing | agent actively running |
| | `waitingForResponse` | `accent`, pulsing | needs a decision/answer from the dev |
| `TaskStatus` | `queued`, `cloning` | `text2` | |
| | `planning`, `running` | `live`, pulsing | agent working |
| | `waitingForAnswer`, `planReady`, `awaitingReview` | `accent` | needs the dev |
| | `done` | `live` (static) | |
| | `failed` | `red` | |
| | `cancelled` | `text2` | |

"Pulsing" = a `1.6s` opacity tween between `1.0` and `0.35` on the status
dot only (an `AnimatedOpacity`/`AnimationController` loop), never on the
whole row/card.

### Typography

Google Fonts: **IBM Plex Sans** (UI text) + **IBM Plex Mono** (code, logs,
diffs, tokens/ids, model names). Add the `google_fonts` package rather than
bundling font assets.

| Role | Family | Size | Weight |
|---|---|---|---|
| Screen title | Sans | 20px | 600 |
| Card/dialog title | Sans | 18px | 600 |
| Body | Sans | 13.5–14px | 400–500 |
| Label/eyebrow | Sans | 11–12px, uppercase, `letterSpacing: 0.04em` | 600 |
| Caption/timestamp | Sans | 11–12px | 400 |
| Code/mono (logs, diffs, tokens, branch names, model ids) | Mono | 12–13px | 400–500 |

### Spacing, radius, elevation

- Spacing scale: 4 / 6 / 8 / 10 / 12 / 14 / 16 / 20 / 24 / 28 / 32px.
- Corner radius: 7–8px (buttons, inputs, small chips), 10px (cards),
  14–16px (modals).
- No drop shadows except modals (`0 24px 60px rgba(0,0,0,0.5)`); flat
  elsewhere — depth comes from the `bg0`→`bg1`→`bg2`→`bg3` surface ladder,
  not shadows.
- No left-border accent-color cards, no gradients, no emoji as UI glyphs.
  Icons are inline stroke SVGs / Material icons at 1.3–1.6px stroke
  equivalent, never filled unless indicating "selected".

## 2. Component patterns

**Status pill** — small pill, `background: color.withOpacity(0.14)`,
`border: 1px solid color.withOpacity(0.35)`, a 6px dot + label in `color`,
text 12px/500.

**Card** (kanban card, machine card) — `bg1`, `1px solid border`, radius
10px, 10–14px padding, column layout with 6–8px gaps.

**Code block** (install commands, tokens, diff) — background `#0B0B0D`
(near-black, distinct from `bg0`), `1px solid border`, radius 8px, mono
font, a copy button pinned top-right (`bg2` chip, copy icon).

**Pill selector** (role, model, effort, single-select choices) — a wrapped
row of pill buttons; selected = `border: accent`, `background:
accent.withOpacity(0.14)`, `text0`; unselected = `border`, `bg2`, `text1`.
Used instead of a `DropdownButton` wherever the option set is small (≤6)
and picking visually matters (role, effort, execution mode).

**Modal dialog** — centered card, width 480–560px, `bg1`, `1px solid
borderStrong`, radius 16px, 28px padding, scrim `rgba(0,0,0,0.6)` behind.
Header row: title (+ optional subtitle/context chip) on the left, a ghost
close (X) button on the right. Footer: right-aligned button row, ghost
"Cancel"/"Close" + filled `accent` primary action.

**Diff view** (`widgets/diff_view.dart`) — per line: a fixed-width
(16px) marker column (`+`/`−`/blank) in `text2`, then the line text.
Additions: text `#E4FFA3` on `live.withOpacity(0.10)` background.
Deletions: text `#FFC2CC` on `red.withOpacity(0.10)` background. Context
lines: `text1` on transparent. Mono font throughout.

## 3. Screens → files

| Canvas artboard | Target file(s) | Notes |
|---|---|---|
| Dashboard (nav rail + kanban + machines panel) | `screens/panel_shell.dart` (nav rail) + a new `screens/dashboard_screen.dart` | Replace `NavigationRail`'s Material look with the dark nav rail pattern above; kanban is new, doesn't exist yet. `projects_screen.dart`/`machines_screen.dart`/`agents_screen.dart` currently exist as separate top-level tabs — consider folding the machines+agents list into the Dashboard's "Machines" panel per the design, keeping standalone list screens for management (edit/delete). |
| Task detail — waiting for answer / plan approval / live execution / diff review | New `screens/task_detail_screen.dart` (one screen, four sub-states switched on `Task.status`), replacing/absorbing `screens/task_diff_screen.dart` | The canvas modeled these as 4 separate artboards for review purposes; in code this is **one** screen reacting to `TaskStatus` via `TaskDetailBloc` (already the plan in `DESIGN-DOC.md` §3.3). `task_diff_screen.dart`'s `_ChangedFiles`/`_SelectedFileDiff` split (file list + selected diff) already matches the "Diff review" artboard — keep that structure, restyle it. |
| Add machine (name → token + install command) | New dialog, e.g. `widgets/add_machine_dialog.dart`, opened from `machines_screen.dart` | Two-step: name form → generated token/command. Token shown once; no back button once generated. |
| Remove machine — still online guard | `widgets/machine_online_delete_blocked_dialog.dart` | **Already implemented**, plain `AlertDialog`. Restyle to the modal pattern above (dark card, warning icon, code block with copy button) — content/copy is already correct, matches the design almost verbatim. |
| Add project (name, repo URL, token + help accordion) | New dialog, e.g. `widgets/add_project_dialog.dart`, opened from `projects_screen.dart` | The expandable "How do I do this?" steps (design doc §6.5.1) are the one piece of copy worth lifting verbatim from the canvas — it's already written out in the artboard. |
| Add agent (name, role, model, effort, execution mode) | New dialog, e.g. `widgets/add_agent_dialog.dart`, opened from `agents_screen.dart` | Role/model/effort as pill selectors, not dropdowns. Execution mode: `native` selected, `docker` rendered disabled with a "Coming soon" tag — don't let the dev pick it yet, the enum value exists but isn't implemented (design doc §6.10). |

## 4. Suggested build order

1. Theme: add `google_fonts`, replace the seeded blue `ColorScheme` in
   `main.dart` with the token table above, force dark mode.
2. Shared widgets: status pill, pill-selector, modal shell, code block —
   small reusable widgets under `lib/widgets/`, since all four onboarding
   dialogs and the task detail screen reuse them.
3. Restyle `machine_online_delete_blocked_dialog.dart` (already
   functionally correct, smallest visual gap to close).
4. Restyle `task_diff_screen.dart` into the full task detail screen with
   its 4 states.
5. Dashboard (kanban + machines panel) — the biggest net-new screen.
6. Add machine / Add project / Add agent dialogs.
