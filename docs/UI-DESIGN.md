# UI Design System — Roundtable panel

Source of truth for the panel's **visual design**: colors, typography,
component patterns, and which screen lives in which file of
`roundtable_flutter`. Architecture and flows are in
[ARCHITECTURE.md](ARCHITECTURE.md) and [FLOWS.md](FLOWS.md).

All of this is implemented. The tokens are in `lib/theme/` (`colors.dart`,
`typography.dart`, `spacing.dart`, `app_theme.dart`; dark-only,
`themeMode: ThemeMode.dark`). The components are in `lib/widgets/`. When you
change a token, change it here too.

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
| `text2` | `#8A8A92` | `Color(0xFF8A8A92)` | Tertiary/dim text, timestamps, placeholders (≥4.5:1 on `bg0`–`bg2`, WCAG AA) |
| `accent` | `#7D39EB` | `Color(0xFF7D39EB)` | Primary CTA, brand mark, "needs your attention" |
| `accentInk` | `#FFFFFF` | `Colors.white` | Text/icon on top of `accent` |
| `accentSoft` | `#A78BFA` | `Color(0xFFA78BFA)` | Accent text on tinted/dark backgrounds, links |
| `live` | `#C6FF33` | `Color(0xFFC6FF33)` | "Agent is working" / success / diff additions |
| `liveInk` | `#0A1400` | `Color(0xFF0A1400)` | Text/icon on top of `live` |
| `red` | `#FF3D57` | `Color(0xFFFF3D57)` | Cancel/destructive/error, diff deletions |
| `warning` | `#FFB020` | `Color(0xFFFFB020)` | Degraded-but-not-failed (e.g. `claude` not launchable on a machine) |
| `codeBg` | `#0B0B0D` | `Color(0xFF0B0B0D)` | Code block / diff background |

`ColorScheme` mapping (in `app_theme.dart`):
`primary: accent`, `onPrimary: accentInk`, `secondary: live`,
`onSecondary: liveInk`, `error: red`, `surface: bg1`, `onSurface: text0`,
`surfaceContainerHighest: bg2`, `outline: border`. Only build `darkTheme`
seriously. `themeMode` is fixed to `ThemeMode.dark`.

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
| | `cancelled`, `draft` | `text2` | |

"Pulsing" = a `1.6s` opacity tween between `1.0` and `0.35` on the status
dot only (an `AnimatedOpacity`/`AnimationController` loop), never on the
whole row/card.

### Typography

Google Fonts: **IBM Plex Sans** (UI text) + **IBM Plex Mono** (code, logs,
diffs, tokens/ids, model names), loaded with `google_fonts`.

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

Navigation (`screens/panel_shell.dart` + `widgets/nav_rail.dart`):
**Dashboard · Projects · Machines**. Agents don't have their own screen.
They're listed under their machine, with a ⋯ menu (Edit / Delete).

| Screen | File | Contents / notes |
|---|---|---|
| Dashboard | `screens/dashboard_screen.dart` | The title is a project filter ("All projects" or one project). Kanban (`kanban_column.dart`, `kanban_card.dart`; columns Backlog / In progress / Review / Done), plus a machines panel (`machine_summary_card.dart`, `machine_metrics.dart`). The New task button opens `create_task_dialog.dart` with the filtered project preset |
| Projects | `screens/projects_screen.dart` → `project_detail_screen.dart` | Project list with 7-day activity. Detail: repo, token status (`update_token_dialog.dart`, `token_help_accordion.dart`), a kanban scoped to the project, delete |
| Machines | `screens/machines_screen.dart` → `machine_detail_screen.dart` | Machine cards with their agents (Edit / Delete menu), CPU/RAM (`machine_metrics.dart`), `claude_warning_banner.dart`, `runner_update_banner.dart`. Add machine/agent dialogs. Delete guard `machine_online_delete_blocked_dialog.dart` |
| Task detail | `screens/task_detail_screen.dart` (+ `blocs/task_detail_bloc.dart`) | One screen whose sub-state depends on `Task.status`: **waiting for answer** (question + options) · **plan approval** (`plan_content.dart`, approve / feedback) · **live execution** (log tail, `task_log_line.dart`) · **diff review** (file list + `diff_view.dart`, feedback, `request_review_dialog.dart`, `review_comment_card.dart`, accept & merge / resolve conflicts). Side rail: project, agent (`agent_avatar.dart`, `reassign_agent_dialog.dart`), branch, PR. Actions: cancel / retry / delete |

Dialogs: `add_machine_dialog.dart` (two steps: name → one-time token +
install command with Claude token help, `claude_token_help_accordion.dart`),
`add_project_dialog.dart` (name, repo URL, token + "How do I do this?"
accordion), `add_agent_dialog.dart` (also used for editing; role/model/effort
as pill selectors; execution mode `docker` disabled with a "Coming soon"
tag, and fixed when editing).

Shared building blocks: `status_pill.dart`, `app_card.dart`, `app_modal.dart`,
`code_block.dart`, `pill_selector.dart`, `tag_chip.dart`, `load_failed_view.dart`
(a detail screen's error / not-found state with Back + Retry). Widget tests
are in `test/widgets/`.

Accessibility: every icon-only button has a `tooltip`. Text colors keep at
least 4.5:1 contrast on `bg0`–`bg2`.
