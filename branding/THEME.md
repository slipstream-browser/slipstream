# Slipstream Browser — visual theme

**Direction: gray/black/blue, futuristic.** Dark-first, sharp geometry, cool
grays, electric-blue motion accents. Think cockpit HUD / wind-tunnel
telemetry, not neon cyberpunk soup.

## Palette

| Token | Hex | Use |
|---|---|---|
| `ink` | `#0B0E14` | Deepest background — browser frame, logo ground |
| `carbon` | `#10141C` | Toolbar / surface base |
| `graphite` | `#1B2230` | Raised surfaces, cards, omnibox |
| `steel` | `#8A94A6` | Secondary text, inactive icons |
| `mist` | `#C7CEDB` | Primary text on dark |
| `stream` | `#2F7DFF` | Primary accent — electric blue (buttons, active tab, links) |
| `ion` | `#00C8FF` | Secondary accent — cyan glow (gradients, highlights, focus) |
| `warn` | `#FFB454` | Warnings only (amber; sparing) |

Gradient signature: `stream → ion`, top-left to bottom-right, used in the
logo sweep and hero surfaces. Glow: `ion` at 15–25% opacity, tight blur.

Light mode exists but is secondary: `mist`-family backgrounds, `ink` text,
same blue accents. The brand ground is always dark.

## Geometry & type

- Sharp 45° bevels over round corners where Chromium allows; 8px radius max.
- Motion language: horizontal speed-lines trailing off elements (see logo).
- Wordmark: "SLIPSTREAM" in a geometric sans (Inter/Rajdhani class), wide
  tracking, `mist` on `ink`; "BROWSER" in `steel` at 60% size beneath or beside.

## Assets

- `assets/logo.svg` — master mark (angular S + speed lines, stream→ion
  gradient on ink roundrect). All raster sizes derive from this.
- Derived (generated, do not hand-edit): `product_logo_{16,24,32,48,64,128,256}.png`,
  `slipstream.ico` (16/24/32/48/64/128/256), installer bitmaps, Start tiles.
- Generation: ImageMagick from the SVG (`scripts/make-icons.ps1`, TODO).
  16px legibility rule: at 16px only the S mark renders (no speed lines) —
  use the `#mark-only` view or logo-16.svg variant if detail muddies.

## In-browser theme (planned)

1. **v0.1**: ship dark mode as the default appearance (`prefs` +
   `--force-dark-mode` equivalent default), accent color `stream` where
   Chromium's user-color/theme system allows (`kBrowserColorScheme`,
   `kUserColorSeed` defaults) — prefs-level, cheap.
2. **v0.1/v0.2**: `patches/90-slipstream-default-theme.patch` — default
   ThemeProperties/color-mixer overrides: frame `ink`, toolbar `carbon`,
   active-tab underline + FAB `stream`, NTP background `ink` with subtle
   grid. Kept small; full custom NTP is a non-goal until the rebase cadence
   is proven.
3. Users can override with any Web Store theme — we never lock appearance.
