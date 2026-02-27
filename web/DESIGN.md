# SME Digital — Design System

> Single source of truth for all web UI decisions.
> Last updated: 2026-02-26 — color system reworked to navy/coral palette

---

## 1. Typography

### Font Family

| Role      | Font   | Fallback | Style                     |
|-----------|--------|----------|---------------------------|
| Primary   | Inter  | Roboto   | Clean · Modern · Professional |
| Category  | Sans-serif | —    | —                         |

### Type Scale (Mobile-first)

| Usage         | Size  | Weight | Line Height | CSS Variable          |
|---------------|-------|--------|-------------|------------------------|
| Display       | 28px  | 600    | 34px        | `--text-display`       |
| Page Title    | 22px  | 600    | 28px        | `--text-page-title`    |
| Section Title | 18px  | 600    | 24px        | `--text-section-title` |
| Card Title    | 16px  | 600    | 22px        | `--text-card-title`    |
| Body          | 14px  | 400    | 20px        | `--text-body`          |
| Small Text    | 12px  | 400    | 16px        | `--text-small`         |
| Button Text   | 14px  | 500    | 20px        | `--text-button`        |
| Table Numbers | 14px  | 500    | 20px        | `--text-body`          |
| Total Amount  | 18px  | 600    | 24px        | `--text-total`         |

---

## 2. Color System

### Usage Hierarchy — 60 / 25 / 10 / 5

| Layer        | % of screen | Purpose                            |
|--------------|-------------|-------------------------------------|
| Neutral      | 60%         | Backgrounds, surfaces, white areas |
| Primary Navy | 25%         | Nav, headings, primary CTAs        |
| Accent Coral | 10%         | Icons, highlights, active chips    |
| Semantic     | 5%          | Success / error only               |

### Brand Colors

| Token          | Hex       | CSS Variable           | Usage                       |
|----------------|-----------|------------------------|-----------------------------|
| Primary        | `#0b3954` | `--color-primary`      | App bar, primary button     |
| Primary Hover  | `#082c42` | `--color-primary-hover`| Active / hover states       |
| Accent         | `#ff5a5f` | `--color-accent`       | Highlights, focus, chips    |

### Background Colors

| Token       | Hex       | CSS Variable          | Usage                        |
|-------------|-----------|-----------------------|------------------------------|
| Page        | `#F4F8FB` | `--color-bg`          | Page / section canvas        |
| Surface     | `#ffffff` | `--color-surface`     | Cards, navbar, panels        |
| Surface Alt | `#EEF2F7` | `--color-surface-alt` | Hover rows, subtle fills     |

### Border Colors

| Token   | Hex       | CSS Variable          | Usage              |
|---------|-----------|-----------------------|--------------------|
| Default | `#e3eaf0` | `--color-border`      | Dividers, inputs   |
| Strong  | `#5f7384` | `--color-border-strong`| Emphasis borders  |

### Text Colors

| Token     | Hex       | CSS Variable      | Usage              |
|-----------|-----------|-------------------|--------------------|
| Primary   | `#0b3954` | `--color-label`   | Main text          |
| Secondary | `#5f7384` | `--color-label-sub` / `--color-muted` | Subtext, captions |
| Inverse   | `#ffffff` | `--color-inverse` | Text on dark fills |

### Semantic Colors

| Token   | Text      | Background | CSS Variable (text)  | Usage         |
|---------|-----------|------------|----------------------|---------------|
| Success | `#087e8b` | `#E6F6F7`  | `--color-success`    | Paid, profit  |
| Error   | `#c81d25` | `#FDE8E8`  | `--color-danger`     | Unpaid, loss  |
| Accent  | `#ff5a5f` | `#ffffff`  | `--color-accent`     | Alerts, tags  |

### Interactive

| Token          | Hex       | CSS Variable          | Usage            |
|----------------|-----------|-----------------------|------------------|
| Hover Overlay  | `#e3eaf0` | `--color-hover-overlay`| Row / item hover|
| Focus Ring     | `#ff5a5f` | `--color-focus`       | Keyboard focus   |

---

## 3. Button System

### Variants

| Variant   | Background  | Text      | Border        | Hover           |
|-----------|-------------|-----------|---------------|-----------------|
| Primary   | `#023E8A`   | `#FFFFFF` | —             | `#0077B6`       |
| Secondary | Transparent | `#023E8A` | `#023E8A`     | `primary/8` tint |
| Danger    | `#DC2626`   | `#FFFFFF` | —             | opacity 90%     |
| Ghost     | Transparent | `#023E8A` | —             | `primary/8` tint |

### Shared Rules

| Property | Value        |
|----------|--------------|
| Radius   | 8px          |
| Padding  | 12px / 16px (md) |
| Font     | 14px / 500   |

---

## 4. Card System

| Property  | Value                                  |
|-----------|----------------------------------------|
| Background | `#FFFFFF`                             |
| Radius     | 12px (`--radius-lg`)                  |
| Padding    | 16px (`--space-md`)                   |
| Shadow     | `0px 2px 6px rgba(0,0,0,0.05)`        |

---

## 5. Table System

| Element           | Style              |
|-------------------|--------------------|
| Header Font       | 13px / 600         |
| Body Font         | 14px / 400         |
| Number Alignment  | Right              |
| Header Background | `#F9FAFB`          |
| Border            | `#E5E7EB`          |
| Row Height        | 44px               |

---

## 6. Invoice PDF Rules

| Element       | Style          |
|---------------|----------------|
| Header Color  | `#023E8A`      |
| Title Size    | 22px / 600     |
| Section Title | 16px / 600     |
| Body Text     | 14px           |
| Total         | 18px / 600     |
| Paid Badge    | `#16A34A`      |
| Unpaid Badge  | `#DC2626`      |

---

## 7. Spacing — 8pt Grid

| Token | px  | CSS Variable  | Tailwind approx |
|-------|-----|---------------|-----------------|
| xs    | 4   | `--space-xs`  | `p-1`           |
| sm    | 8   | `--space-sm`  | `p-2`           |
| md    | 16  | `--space-md`  | `p-4`           |
| lg    | 24  | `--space-lg`  | `p-6`           |
| xl    | 32  | `--space-xl`  | `p-8`           |
| xxl   | 48  | `--space-xxl` | `p-12`          |

---

## 8. Icon System

| Property       | Value          |
|----------------|----------------|
| Size           | 20–24px        |
| Style          | Outline        |
| Active Color   | `#023E8A`      |
| Inactive Color | `#9CA3AF`      |

---

## 9. Border Radius

| Token         | Value  | CSS Variable    | Usage                 |
|---------------|--------|-----------------|-----------------------|
| sm            | 6px    | `--radius-sm`   | Input fields, badges  |
| md            | 8px    | `--radius-md`   | Buttons               |
| lg            | 12px   | `--radius-lg`   | Cards                 |
| xl            | 16px   | `--radius-xl`   | Modals, large panels  |
| pill          | 9999px | `--radius-pill` | Tags, chips           |

---

## 10. Implementation Notes (Current Web)

### Source of Truth

- All design tokens live in `app/theme.css` — single file, no pipeline
- `app/globals.css` imports `theme.css` and contains only resets, animations, and base layer
- To change any color, spacing, radius, or shadow: edit `app/theme.css` only

### Token Flow

```
app/theme.css
  └── @theme inline {}     → Tailwind utility classes (bg-primary, text-label, …)
  └── :root {}             → shadcn/Radix CSS variables (light mode)
  └── .dark {}             → dark mode overrides
        ↓
app/globals.css @import "./theme.css"
        ↓
components / sections
```

### Refactor Rules (Implemented)

- Landing sections now prefer token/theme utility classes over inline visual styles
- Pricing, CTA, Social Proof, and Features were migrated away from inline color/gradient styling
- Locale pricing/features pages were aligned to the same token/theme styling approach

### Approved Exception (Current)

- `components/sections/Hero.tsx` phone mockup area keeps inline styles and arbitrary values intentionally
  - reason: it is artwork/mockup presentation, not reusable UI
  - non-mockup Hero content should still follow normal design-system rules

### Gradient Usage (Current Policy)

Allowed as section-level treatments only:

- Pricing Pro card
- Final CTA block
- Hero mockup/visual card (inside exception zone)

Not allowed as default styling for reusable UI primitives (`Button`, `Input`, `Badge`, `Card`).
