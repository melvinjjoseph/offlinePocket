---
name: Cyber Sentinel
colors:
  surface: '#0d1518'
  surface-dim: '#0d1518'
  surface-bright: '#323a3e'
  surface-container-lowest: '#070f12'
  surface-container-low: '#151d20'
  surface-container: '#192124'
  surface-container-high: '#232b2e'
  surface-container-highest: '#2e3639'
  on-surface: '#dbe4e8'
  on-surface-variant: '#b9caca'
  inverse-surface: '#dbe4e8'
  inverse-on-surface: '#2a3235'
  outline: '#849495'
  outline-variant: '#3a494a'
  surface-tint: '#00dce5'
  primary: '#e9feff'
  on-primary: '#003739'
  primary-container: '#00f5ff'
  on-primary-container: '#006c71'
  inverse-primary: '#00696e'
  secondary: '#b6cad1'
  on-secondary: '#213339'
  secondary-container: '#374a50'
  on-secondary-container: '#a5b8c0'
  tertiary: '#f3fbff'
  on-tertiary: '#283236'
  tertiary-container: '#d4dfe4'
  on-tertiary-container: '#586367'
  error: '#ffb4ab'
  on-error: '#690005'
  error-container: '#93000a'
  on-error-container: '#ffdad6'
  primary-fixed: '#63f7ff'
  primary-fixed-dim: '#00dce5'
  on-primary-fixed: '#002021'
  on-primary-fixed-variant: '#004f53'
  secondary-fixed: '#d2e6ed'
  secondary-fixed-dim: '#b6cad1'
  on-secondary-fixed: '#0b1e24'
  on-secondary-fixed-variant: '#374a50'
  tertiary-fixed: '#d9e4e9'
  tertiary-fixed-dim: '#bdc8cd'
  on-tertiary-fixed: '#131d21'
  on-tertiary-fixed-variant: '#3e484d'
  background: '#0d1518'
  on-background: '#dbe4e8'
  surface-variant: '#2e3639'
typography:
  headline-lg:
    fontFamily: Geist
    fontSize: 32px
    fontWeight: '600'
    lineHeight: 40px
    letterSpacing: -0.02em
  headline-md:
    fontFamily: Geist
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 32px
    letterSpacing: -0.01em
  body-lg:
    fontFamily: Geist
    fontSize: 18px
    fontWeight: '400'
    lineHeight: 28px
  body-md:
    fontFamily: Geist
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  label-md:
    fontFamily: JetBrains Mono
    fontSize: 14px
    fontWeight: '500'
    lineHeight: 20px
    letterSpacing: 0.05em
  label-sm:
    fontFamily: JetBrains Mono
    fontSize: 12px
    fontWeight: '500'
    lineHeight: 16px
    letterSpacing: 0.08em
  headline-lg-mobile:
    fontFamily: Geist
    fontSize: 26px
    fontWeight: '600'
    lineHeight: 32px
rounded:
  sm: 0.125rem
  DEFAULT: 0.25rem
  md: 0.375rem
  lg: 0.5rem
  xl: 0.75rem
  full: 9999px
spacing:
  base: 4px
  xs: 4px
  sm: 8px
  md: 16px
  lg: 24px
  xl: 32px
  2xl: 48px
  gutter: 20px
  margin-mobile: 16px
  margin-desktop: 40px
---

## Brand & Style

The design system is engineered to evoke feelings of impenetrable security, technical precision, and modern encryption. It targets a security-conscious audience that values privacy and robust data protection.

The visual style is a fusion of **Corporate Modern** and **Technological Minimalism** with a **Tactile** edge. It utilizes a dark-mode-first approach to create a "vault" atmosphere. Key characteristics include:
- **High-Tech Aesthetic:** Inspired by modern cryptography and hardware security modules.
- **Precision:** Mathematical spacing and razor-sharp alignment.
- **Subtle Depth:** Using tonal layers and glowing accents to indicate status and importance rather than traditional skeuomorphism.

## Colors

The palette is anchored by a vibrant, electrified cyan primary color that represents active protection and energy. This is contrasted against a deep, multi-layered neutral scale derived from gunmetal and slate greys.

- **Primary (#00f5ff):** Used exclusively for primary actions, active status indicators, and focus states. It should feel like a light source against the dark background.
- **Secondary / Surface (#2c3e44):** Used for elevated containers, cards, and UI elements that need to stand out from the base.
- **Tertiary / Sub-surface (#1a2428):** Used for inner wells, input fields, and recessed areas.
- **Neutral / Background (#0f171a):** The core canvas color, providing a deep, stable foundation.
- **Success/Error:** Use primary cyan for positive reinforcement and a muted ruby (#ff4b5c) for critical errors.

## Typography

This design system utilizes a dual-font strategy to balance readability with a technical "developer" aesthetic.

1.  **Geist:** Used for headlines and body copy. Its clean, geometric sans-serif nature provides a modern, high-tech feel while maintaining excellent legibility at all sizes.
2.  **JetBrains Mono:** Used for labels, metadata, and system status. The monospaced nature reinforces the technical, encrypted narrative of the "offlinePocket" brand.

All type should be rendered with optimized legibility. Headlines use tighter tracking for a more "locked-in" look, while monospaced labels use expanded tracking for clarity.

## Layout & Spacing

The layout philosophy is based on a **Strict Grid System** that emphasizes structure and containment.

- **Grid:** A 12-column fluid grid for desktop and a 4-column grid for mobile.
- **Rhythm:** An 8px linear scale (with 4px increments for micro-spacing) ensures all elements feel mathematically aligned.
- **Margins:** Generous outer margins on desktop create a centered "vault" experience, while tighter margins on mobile maximize utility.
- **Reflow:** On mobile, complex dashboard widgets collapse into a single-column stack, prioritizing data hierarchy.

## Elevation & Depth

Visual hierarchy is established through **Tonal Layering** and **Cyan Glows**.

- **Stacked Tiers:** Depth is created by lightening the surface color as it "rises" toward the user. Base background is the darkest, while active modals are the lightest slate grey.
- **Inner Shadows:** Recessed areas (like input fields) use subtle inner shadows to create a "etched" or "carved" look.
- **Status Glows:** Instead of heavy drop shadows, use a 0px 0px 12px #00f5ff33 (low opacity cyan) glow to indicate focused states or active security shields.
- **Borders:** Use 1px solid borders in a slightly lighter shade than the background (#ffffff15) to define boundaries without adding visual bulk.

## Shapes

The shape language is **Soft** but controlled. While pure sharp corners feel too aggressive, overly rounded corners feel too casual.

- **Corner Radius:** A consistent 0.25rem (4px) radius is used for small elements like buttons and checkboxes.
- **Large Components:** Cards and containers use 0.5rem (8px) or 0.75rem (12px) for a sophisticated, structural feel that mimics high-end hardware.
- **Iconography:** Use line-based icons with consistent stroke weights (1.5px or 2px) to match the technical typography.

## Components

### Buttons
- **Primary:** Background #00f5ff, text #0f171a (High contrast). On hover, add a subtle cyan outer glow.
- **Secondary:** Transparent background, 1px border #00f5ff, text #00f5ff.
- **Tertiary:** Background #2c3e44, text #ffffff.

### Input Fields
- **Default:** Background #1a2428, 1px border #2c3e44, text #ffffff.
- **Focused:** Border #00f5ff, soft inner glow.
- **Placeholder:** #ffffff40.

### Cards & Containers
- Containers should utilize a subtle gradient (top-left to bottom-right) from #2c3e44 to #1a2428 to mimic the metallic sheen of the logo's shield.

### Chips & Badges
- Use JetBrains Mono for badge text.
- Security "Status" chips should use the primary cyan with 10% opacity for the background and 100% opacity for the text.

### Progress Bars
- Track: #1a2428.
- Fill: #00f5ff. For critical system processes, use a "pulsing" animation effect on the fill.