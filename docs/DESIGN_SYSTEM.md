# Cairo Airport Digital Twin — Aviation Operations Workspace

**Design System — Phase 01 (Design Foundation)**

> Status: approved foundation. This document is the single visual reference for
> Phase 02 (Live Events redesign) and every later screen. Do not create a
> per-feature design system. If a value is missing here, extend the tokens in
> `lib/core/theme/tokens.dart` first — never hardcode it inside a feature.

Scope of Phase 01: tokens, `ThemeData`, shared widgets, and the App Shell only.
Feature screens, fixtures, models, routing, permissions, and business logic are
unchanged.

---

## 1. Design Philosophy

This is an **operations workspace**, not a marketing dashboard. The interface
must be quiet, precise, and fast to scan during live duty.

Principles:

- **Data first.** Every visual element must have a functional purpose.
- **Calm by default.** No gradients, neon, glassmorphism, glow, bounce, or
  permanent animation.
- **Hierarchy over decoration.** Size, weight, and spacing communicate order —
  not borders, badges, and shadows.
- **Honest data.** Fixtures are labelled as fixtures. Never imply a live backend
  that does not exist.
- **One language per screen.** Arabic RTL and English LTR are mirrored; IDs,
  flight numbers, codes, times and numeric values stay LTR in both.
- **Consistency over novelty.** Reuse shared components; do not copy styling
  into feature files.

Anti-patterns explicitly banned: every value in its own card, coloured borders
around every card, repeated page titles, a badge beside every line, bold on
everything, decorative icons, dense gridlines, and cloned layouts for all 15
screens.

---

## 2. Color Tokens

Single source: `AppColors` in `lib/core/theme/tokens.dart`.

### Main surfaces

| Token | Hex | Usage |
|---|---|---|
| `canvas` | `#F5F7FA` | Application background |
| `surface` | `#FFFFFF` | Cards, tables, top bar |
| `surfaceSoft` | `#F8FAFB` | Secondary regions, table headers |
| `surfaceHover` | `#F2F7F8` | Hover on rows/cards |
| `surfaceSelected` | `#EAF5F5` | Selected rows/items |
| `border` | `#DCE5EA` | Input borders when needed |
| `divider` | `#E5ECF1` | Internal separators |

### Sidebar

| Token | Hex |
|---|---|
| `sidebar` | `#183448` |
| `sidebarHover` | `#24485C` |
| `sidebarSelected` | `#2B5262` |
| `sidebarText` | `#F7FAFC` |
| `sidebarMuted` | `#ADC2CD` |

### Brand & actions

| Token | Hex |
|---|---|
| `primary` | `#0B8588` |
| `primaryHover` | `#096F73` |
| `primaryPressed` | `#075A5E` |
| `primaryStrong` | `#08666B` |
| `primarySoft` | `#E6F4F3` |
| `primaryBorder` | `#B9D9D8` |

`primaryStrong` is the default for white-text buttons and accent text:
`#0B8588` on white measures **4.43:1**, just below the 4.5:1 requirement for
normal text. The lighter value is still kept for non-text accent surfaces and
`focus` borders. This is the one documented contrast adjustment.

### Text

| Token | Hex | Usage |
|---|---|---|
| `textPrimary` | `#243746` | Headings, operational values |
| `textSecondary` | `#596D7B` | Labels, subtitles |
| `textTertiary` | `#788B98` | Metadata, axis text |
| `textDisabled` | `#94A3AE` | Disabled controls only |
| `textOnDark` | `#FFFFFF` | Sidebar / filled buttons |

Never use a light grey for important operational data.

### Semantic palettes

| State | Text | Background | Border |
|---|---|---|---|
| Success | `#247A5A` | `#E9F6EF` | `#BFE5D0` |
| Warning | `#946112` | `#FFF5E7` | `#F1D8A6` |
| Error | `#AD4141` | `#FDEFEF` | `#F0CBCB` |
| Info | `#315E91` | `#EAF2FC` | `#C8DBF2` |
| Neutral | `#617581` | `#F0F3F5` | `#DCE4E8` |

Use semantic colours **only for real states**. Never for decoration. Always
pair colour with a written label. `AppTones.from(color)` maps legacy status
colours to these palettes so existing feature calls stay safe.

### Legacy aliases

`page → canvas`, `soft → surfaceSoft`, `border/divider` unchanged,
`action → primaryStrong`, `navy/text → textPrimary`, `muted → textSecondary`,
`success/warning/info` point to the darker semantic text values, `danger → error`,
`tealSoft → primarySoft`, `onSidebar → sidebarText`. New code must use semantic
names.

---

## 3. Typography Scale

Fonts: **Cairo** for Arabic, **Inter** for English and all numbers/IDs/times.
Files: `assets/fonts/Cairo.ttf`, `assets/fonts/Inter.ttf`.

| Style | Size | Weight | Line height | Token |
|---|---|---|---|---|
| Display | 32 | 700 | 1.30 | `AppTypography.display` |
| Page title | 28 | 700 | 1.35 | `pageTitle` |
| Section title | 20 | 600 | 1.40 | `sectionTitle` |
| Card title | 16 | 600 | 1.45 | `cardTitle` |
| Body primary | 14 | 400 | 1.55 | `bodyPrimary` |
| Body emphasis | 14 | 600 | 1.55 | `bodyEmphasis` |
| Table text | 13 | 400 | 1.45 | `tableText` |
| Button text | 13 | 600 | 1.35 | `buttonText` |
| Label | 12 | 500 | 1.45 | `label` |
| Metadata | 12 | 400 | 1.45 | `metadata` |
| KPI value | 30 | 700 | 1.20 | `kpiValue` |

Rules:

- Minimum visible size in core UI is **12px**. Never 8px or 9px for operational
  data.
- Use `FontFeature.tabularFigures()` for all numbers in KPIs, tables, timelines
  and IDs (`AppTypography.numeric`, `LtrText`, `Mono`).
- Reduce bold usage; not every label or cell is bold.
- No ALL CAPS for Arabic. Use `TextOverflow.ellipsis` with the full value
  available through tooltip/detail panel.
- **Known constraint:** only single-weight TTF files exist in `assets/fonts/`.
  Requests for 500/600/700 use Flutter's synthetic weight emulation. Fixing
  this requires adding real weight files — a separate, approved asset change,
  not part of Phase 01.

---

## 4. Spacing & Layout

`AppSpace`: `space1=4`, `space2=8`, `space3=12`, `space4=16`, `space5=20`,
`space6=24`, `space7=32`, `space8=40`, `space9=48`, `space10=64`.

| Context | Value |
|---|---|
| Page padding — desktop / tablet / mobile | 28 / 20 / 16 |
| Section gap | 32 (`space7`) |
| Card gap | 16 (`space4`) |
| Card padding | 20 (`space5`) |
| Compact card padding | 16 |
| Form field gap | 16 |
| Label → control gap | 8 |
| Icon → text gap | 10 |
| Small metadata gap | 6 |
| Page content max width | 1560 |

No arbitrary 7/13/19px values unless documented as optical alignment.
`PageBody` applies responsive padding and the max width; `ResponsiveGrid`
drops columns at breakpoints.

Content hierarchy: page header → primary actions → key metrics → filters →
main workspace → secondary details → supporting metadata. Not every screen must
use all seven.

---

## 5. Radius & Elevation

Radius (`AppRadius`): small elements **6**, chips/controls **8**,
inputs/buttons **10**, cards **14**, panels/drawers **16**, dialogs **18**,
pills **999**.

| Level | Shadow | Usage |
|---|---|---|
| 0 — flat | none | text, rows, dividers |
| 1 — standard | `#183448` 6%, blur 12, spread 0, offset (0,2) | normal cards |
| 2 — floating | `#183448` 9%, blur 24, spread 0, offset (0,6) | dropdowns, details panels |
| 3 — modal | `#183448` 14%, blur 40, spread 0, offset (0,16) | dialogs, overlays |

Never combine a strong shadow with a visible full border on the same element.
Do not shadow buttons, chips, or rows. No neon, glow or glassmorphism.

---

## 6. Buttons

| Type | Height | Style |
|---|---|---|
| Primary (FilledButton) | 42 | `#08666B`, white 13/600, radius 10, padding 16 |
| Secondary (OutlinedButton) | 42 | white, `#DCE5EA` border, `#243746` text |
| Tertiary (TextButton) | 42 | transparent, `#08666B` text, hover `#E6F4F3` |
| Destructive (FilledButton with error colour) | 42 | error palette, explicit confirmation |
| Icon button | 40×40 | 18px icon, radius 10, tooltip, keyboard accessible |

States: hover 150ms, focus ring 2px, min target 44×44 where possible. Loading
preserves button width. Configure once in `ThemeData`; features pass labels and
callbacks only.

---

## 7. Inputs, Filters & Search

- Text input: 44px high, white, 1px `#DCE5EA`, radius 10, 14px horizontal
  padding, 13px text; focus 2px `#0B8588`; error uses semantic error palette.
- Search: 280–360px on desktop, 100% on mobile, 18px icon, clear action when
  non-empty. Search behaviour is unchanged from the existing implementation.
- Filter controls: 38–40px high, 12px padding, radius 8, no strong shadows.
- Show only the most important filters inline; move secondary options into a
  dropdown. Align search and filters to the same height/baseline.
- Selected filter state: `surfaceSelected` + `primaryBorder`, not a loud badge.

Phase 01 provides the components/rules. The Live Events filter area is **not**
redesigned in this phase.

---

## 8. Cards & KPI

Standard card: white, radius 14, padding 20, Elevation 1, **no default border**.
Use 16px gaps between inner sections. `AppCard` adds a light hover/selected
surface when tappable; `selected: true` uses `surfaceSelected`.

KPI card: min height 120, padding 20, label 13 secondary, value 30/700 tabular,
unit 12 secondary, context 12. Icons/badges are optional — never all three.
Maximum four main text elements.

One card = one coherent information group. No card-within-card nesting without
a functional reason.

---

## 9. Data Tables

`AppTable` is the only operational table styling.

- Header: 44px, `#F8FAFB`, 12/600 `#596D7B`, bottom divider.
- Rows: ≥52px, 13px text, 16px horizontal / 12px vertical padding.
- Dividers only — no vertical gridlines, no strong borders.
- Hover `#F2F7F8` (120ms), selected `#EAF5F5` + 3px accent marker on the
  appropriate side for RTL/LTR.
- Flight numbers and times LTR with tabular figures; numeric values aligned.
- One semantic status indicator per cell, text included.
- Narrow widths scroll horizontally; important columns are never hidden.
  Sorting/filtering/selection logic is untouched.

---

## 10. Status Badges

`StatusPill`: 24px high, 9px horizontal padding, radius 999, 11–12px/600,
soft semantic background, dark semantic text, **no border by default**, dot or
optional icon plus a written label.

Mapping: Critical → error, Warning → warning, Normal → success/neutral,
Unknown/Stale → neutral with explicit text.

Use `SourceBadge` for provenance as a plain metadata line
(mode · freshness · as-of time), not as stacked badges. No pulsing/animated
indicator unless a defined live function exists — fixtures must not pulse.

---

## 11. Charts

`SeriesChart`, `HBarChart`, `SimpleBarChart` follow one visual language: white
background, no heavy container border, minimal `#E5ECF1` gridlines, 12px
secondary axis/legend text, Elevation 2 tooltips.

Encoding: observed = solid, predicted = dashed, simulated = shaded/distinct,
alerts = semantic warning/error, selected series = primary accent. Always show
units and available source/freshness/timestamps. Never invent data or change
calculations/fixtures. Gridlines must never be stronger than the data.

---

## 12. Navigation

App Shell (`lib/app/shell.dart`) only — routes and permissions unchanged.

Desktop sidebar: solid `#183448` (no gradient), 256px expanded / 72px compact
(1024–1279px), drawer below 1024px. Header ~76px; items 42px high, radius 10,
19px icon, 13px/500 text (active 600), 12px icon–text gap, 12px horizontal
padding, 4px vertical gap, 24px group spacing. Group labels 11/600 in
`#ADC2CD`.

Active: `#2B5262` + white icon/text + 3px accent marker on the correct
RTL/LTR side; no full border. Hover: `#24485C` in 150ms with no size change.
Footer states "Demo mode · fixture data" and version; no fake connection
status. Extra badges are limited to real open counts.

TopBar: 64px, white, `#E5ECF1` bottom divider, 24px horizontal padding, quiet
breadcrumb only — the page title is rendered once inside `PageIntro`. Clock,
role switch and language toggle keep their existing behaviour.

---

## 13. Details Panels & Overlays

`DetailsPanel` (`lib/core/widgets/details_panel.dart`) is the reusable Phase 02
component. Width 340–420px, white, radius 16, Elevation 2, 24px padding, 20px
section gaps, subtle dividers. Title 18, description 13, labels 12, values 13;
IDs rendered LTR. Status sits near the title. Close has a tooltip and keyboard
support. The Digital Twin inspector already uses it.

Dialogs: radius 18, padding 24, Elevation 3, content-based max width, explicit
Close/Cancel.

Phase 01 does **not** reorganise the Live Events screen; Phase 02 will use this
panel to show event details on selection instead of a permanent fixed column.

---

## 14. Responsive Rules

| Range | Behaviour |
|---|---|
| <640 mobile | drawer, 16px page padding, stacked controls, scrollable tables |
| 640–1023 tablet | compact sidebar or drawer, 20px padding, fewer grid columns |
| 1024–1279 small desktop | 72px compact sidebar, 20px padding |
| 1280–1599 desktop | 256px sidebar, 28px padding |
| ≥1600 wide desktop | 256px sidebar, max content width 1560 |

No whole-page horizontal overflow; no primary action hidden without an
accessible alternative. Test viewports: 1600×900, 1440×900, 1280×800,
1024×768, 768×1024, 390×844 — in both RTL and LTR.

---

## 15. RTL / LTR

- `AppStrings.direction` drives `Directionality` at app root; layouts mirror
  through `AlignmentDirectional`, `EdgeInsetsDirectional` and `Padding` start/end.
- Arabic uses Cairo; English uses Inter.
- IDs, flight numbers, times, coordinates and numeric values are wrapped in
  `LtrText` / `Mono` / `IdText`, forcing `TextDirection.ltr`, Inter and tabular
  figures inside both locales.
- The active sidebar marker uses the appropriate directional side.
- Do not use ALL CAPS for Arabic; allow ellipsis with a way to see full text.
- Verify that Arabic glyphs are not clipped at 125%/150% zoom and text scaling.

---

## 16. Accessibility

- Keyboard navigation and visible 2px focus ring on all interactive elements.
- Tooltips on icon-only buttons; semantic labels via `Semantics`.
- Contrast: ≥4.5:1 normal text, ≥3:1 large text and interactive elements.
  `primaryStrong` is used where `primary` fell short (see §2).
- Touch targets 44×44 where possible (40×40 icons with padded tap area).
- State is never colour-only: every badge includes text.
- Skeleton loading keeps layout to reduce shift; no flashing animation.
- Support text scaling and zoom to 150%; respect `MediaQuery.disableAnimationsOf`
  through `AppMotion.effective`.

---

## 17. Motion

| Token | Duration | Easing |
|---|---|---|
| `hover` | 150ms | `easeOutCubic` |
| `selection` | 150ms | `easeOutCubic` |
| `panel` | 200ms | `easeOutCubic` in, suitable out |
| `dialog` | 200ms | `easeOutCubic` in, suitable out |

Short transitions only. No bounce, parallax, animated gradients or perpetual
motion. Motion must never be used to hide slow loading. Respect Reduce Motion.

---

## 18. Component Usage Examples

```dart
// Page header (title appears once)
PageIntro(
  title: s.tr('Live Events', 'الأحداث المباشرة'),
  subtitle: s.tr('Operational activity feed', 'سجل النشاط التشغيلي'),
  actions: [FilledButton(onPressed: _create, child: Text(s.tr('New', 'جديد')))],
)

// KPI grid — tokens only, no hardcoded colors
ResponsiveGrid(
  children: [for (final k in kpis) KpiTileCard(kpi: k, s: s)],
)

// Semantic status, no border, no second badge
StatusPill(label: state.label(s), color: state.color)

// Reusable details surface (Phase 02 will reuse this directly)
DetailsPanel(
  title: event.title,
  status: StatusPill(label: status, color: statusColor),
  onClose: () => context.go(Routes.events),
  children: [DetailsSection(title: 'Timeline', children: [...])],
)

// Numbers / IDs stay LTR even in Arabic
LtrText('MS561', style: AppTypography.label)
```

Never create a local `Container(color: Color(0xFF...), borderRadius: ...)` to
imitate a card; use `AppCard`. Never set `fontSize: 9` in a feature.

---

## 19. Do / Don't

| Do | Don't |
|---|---|
| Read all styles from tokens/theme | Repeat hex values in feature files |
| Use one semantic badge per state | Add a badge beside every line |
| Use soft semantic background + dark text | Use bright red/green blocks as decoration |
| Use Elevation 1 on cards only | Stack shadow + full border on the same element |
| Keep title once, in `PageIntro` | Repeat page title in TopBar and content |
| Mirror layouts with directional padding | Hardcode left/right for RTL screens |
| Scroll tables horizontally on mobile | Hide important columns |
| Label fixtures as fixture data | Show a fake "Connected" pulse |
| Use `AppTable` / `AppCard` / `DetailsPanel` | Copy their styling into a feature |
| Add real font weights when approved | Rely on synthetic weights forever |

---

## 20. Migration Notes

- All Phase 01 token names and legacy aliases live in `tokens.dart`; existing
  features compile unchanged. Prefer new semantic names in new code.
- `StatusPill` keeps its `color` parameter but now maps it to a soft palette;
  the default border was removed. `SourceBadge` is now a plain metadata line
  (dot + mode + freshness + as-of) instead of stacked badges.
- `AppCard` gained `selected`, uses radius 14 / padding 20 / Elevation 1 and no
  default border. `PageBody` spacing now defaults to `space7` (32).
- `EntityInspector` now renders through `DetailsPanel` — a direct example for
  the Phase 02 Live Events details interaction.
- `AppTable` keeps its public constructors; only visual styling changed.
- Single-weight Cairo/Inter font files mean 500/600/700 are synthetically
  emulated; add real weight assets in a separate approved change.
- Feature screens still contain legacy hardcoded sizes/aliases. Phase 01 did
  not redesign them; they are intentionally out of scope and will be migrated
  screen by screen in Phase 02+.
- Validation baseline for this phase: `flutter analyze` clean, 9 design system
  tests passing, web build with `--no-tree-shake-icons` (the Arabic workspace
  path breaks Flutter's icon font subsetting). Visual QA in a real browser
  could not be automated in this environment; see the final delivery report.

---

**End of Phase 01 design foundation. Do not proceed to the Live Events redesign
until this document is reviewed and approved.**
