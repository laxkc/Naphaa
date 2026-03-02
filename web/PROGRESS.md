# SME Digital — Landing Page Progress

**Stack:** Next.js 16 · Tailwind CSS v4 · TypeScript · React 19
**Deploy target:** Vercel
**Last updated:** 2026-03-02

---

## Status Legend
- `[ ]` Not started
- `[~]` In progress
- `[x]` Done

---

## Phase 1 — Foundation
> Project scaffold, design tokens, shared components

- [x] `npx create-next-app` scaffold
- [x] Tailwind CSS v4 configured
- [x] Design system documented in `DESIGN.md`
- [x] Brand tokens in `globals.css` (blue ocean palette)
  - Primary `#023E8A`, Hover `#0077B6`, Accent `#0096C7`
  - Success `#16A34A`, Warning `#F59E0B`, Error `#DC2626`
  - Background `#F9FAFB`, Surface `#FFFFFF`, Text `#111827`
  - Typography scale, 8pt spacing grid, radius tokens
  - Usage hierarchy: 60% neutral · 25% primary · 10% accent · 5% semantic
- [x] Inter font wired in `layout.tsx`
- [x] `layout.tsx` metadata updated
  - Title: `SME Digital — Digital Ledger for Small Businesses`
  - Description, OG, Twitter card
- [ ] `/public` assets added (logo SVG, app screenshots, OG image)
- [x] Shared components
  - `components/ui/Button.tsx` — primary / secondary / danger / ghost · radius 8px · weight 500
  - `components/ui/SectionLabel.tsx`
  - `components/ui/StoreButtons.tsx`

---

## Phase 2 — Navigation
> File: `components/layout/Navbar.tsx`

- [x] Logo (teal wordmark left)
- [x] Nav links: Features · How it Works · Pricing
- [x] Language toggle (EN / नेपाली) — state only, no i18n yet
- [x] `Login` ghost button
- [x] `Start Free` solid teal button
- [x] Sticky on scroll + border-bottom shadow
- [x] Mobile hamburger → slide-down drawer

---

## Phase 3 — Hero Section
> File: `components/sections/Hero.tsx`

- [x] Left column: badge, H1, body copy, dual CTAs, trust row
- [x] Right column: phone mockup (pure JSX — dashboard card + quick actions + low stock)
- [x] Background: `#F4F6F5` + radial teal glow behind phone
- [x] Responsive: stacked on mobile, 50/50 on desktop

---

## Phase 4 — Social Proof Bar
> File: `components/sections/SocialProof.tsx`

- [x] Dark teal (`#004D40`) full-width strip
- [x] Testimonial quote + attribution
- [x] Three stats: `500+ shops`, `Works offline`, `Free forever`
- [ ] Marquee scroll on mobile

---

## Phase 5 — Feature Grid
> File: `components/sections/Features.tsx`

- [x] Section header + 6 feature cards in 3×2 grid (1 col mobile)
  - [x] Lightning-fast sales
  - [x] Inventory tracking + low stock alerts
  - [x] Customer credit ledger
  - [x] Profit & cashflow reports
  - [x] Offline-first with auto sync
  - [x] PDF invoice generation
- [x] Card style: `#F4F6F5` bg, colored emoji icon circle, hover shadow + lift

---

## Phase 6 — How It Works
> File: `components/sections/HowItWorks.tsx`

- [x] Section header: "Up and running in 3 steps"
- [x] Step 1, 2, 3 with numbered badge, title, desc, tag pill
- [x] Horizontal connector line on desktop
- [x] Vertical stacked on mobile
- [ ] App screenshots as cropped mockup cards (needs real screenshots)

---

## Phase 7 — Pricing
> File: `components/sections/Pricing.tsx`

- [x] Free card (teal ring, `Rs. 0 / month`, feature list, `Start Free` CTA)
- [x] Pro card (dark teal gradient, "Coming Soon" badge, email notify capture)
- [x] Side-by-side on desktop, stacked on mobile

---

## Phase 8 — Final CTA + Footer
> Files: `components/sections/CallToAction.tsx`, `components/layout/Footer.tsx`

- [x] CTA block: teal gradient, "Ready to digitize your shop?", dual buttons
- [x] Footer: 4-column grid (Brand, Features, Company, Language)
- [x] Footer responsive: 2×2 on tablet, 1 col on mobile

---

## Phase 9 — Supporting Pages
- [ ] `/privacy` — Privacy policy page
- [ ] `/terms` — Terms of service page
- [ ] `/login` — Redirects to app or auth URL

---

## Phase 10 — Polish & Launch
- [ ] Mobile responsiveness pass (all sections)
- [ ] Lighthouse score ≥ 90 (perf, a11y, SEO)
- [ ] OG / Twitter card meta tags
- [ ] `sitemap.xml` + `robots.txt`
- [ ] Nepali copy pass (translate all strings)
- [ ] Deploy to Vercel + connect custom domain
- [ ] Analytics (Plausible or Vercel Analytics)

---

## Phase 11 — Design System Refactor (Implementation)
> Code refactor only (web landing), using existing `DESIGN.md` + `PROGRESS.md` plan

- [x] Token files created in `design-system/tokens/`
  - [x] `colors.json`
  - [x] `typography.json`
  - [x] `spacing.json`
  - [x] `radius.json`
  - [x] `shadow.json`
  - [x] token sync script added (`npm run tokens:sync`)
  - [x] generated token layers wired into:
    - [x] `app/generated-tokens.css` (raw `--ds-*` vars)
    - [x] `app/generated-theme-inline.css` (Tailwind `@theme inline`)
    - [x] `app/theme.css` (runtime theme mapping)
- [x] Refactor `components/sections/Pricing.tsx`
  - [x] remove inline visual styles for pricing cards/content
  - [x] use shared UI variants (`Button`, `Input`, `Badge`, `Card`)
  - [x] keep visual parity
- [x] Refactor `app/[locale]/pricing/page.tsx`
  - [x] align pricing visuals with shared section token/theme classes
- [x] Refactor `components/sections/CallToAction.tsx`
  - [x] remove inline rgba/gradient usage where component/theme variants should handle it
- [x] Refactor `components/sections/SocialProof.tsx`
  - [x] replace hardcoded section background/text tints with system styles
- [x] Refactor `components/sections/Features.tsx`
  - [x] replace per-card color styling with reusable pattern
- [x] Refactor `components/sections/Hero.tsx`
  - [x] keep phone mockup as exception zone (inline styles intentionally retained)
  - [x] refactor non-mockup hero copy/layout/button styles
- [x] Refactor shared UI primitives as needed during section migration
  - [x] no additional primitive changes required for this pass
- [x] Final pass
  - [x] responsive regression check (code-level class audit on refactored sections/pages)
  - [x] accessibility/focus state check (focus/hover states verified in shared UI + layouts)
  - [x] visual consistency check (all sections, code-level style cleanup)
  - [x] `npm run lint` pass

---

## Phase 12 — Positioning Redesign
> Reposition Naphaa away from competitor language and rebuild the marketing narrative around clarity, control, and confidence for Nepali shop owners.

- [~] Strategy and narrative reset
  - [x] ban competitor-style phrases across new copy direction
    - avoid: `all-in-one`
    - avoid: `accounting made easy`
    - avoid: `digital khata`
    - avoid: `POS solution`
    - avoid: `cloud accounting`
    - avoid: `business management software`
  - [x] lock new positioning pillars
    - control
    - profit clarity
    - simplicity
    - confidence
    - peace of mind
  - [~] refactor homepage into the new story
    - [x] Hero — `Know Your Shop. Control Your Profit.`
    - [x] Who This Is For
    - [x] What Makes Naphaa Different
    - [x] What You Can Do
    - [x] Trust
    - [x] How It Works
    - [x] Pricing
    - [x] FAQ
    - [x] Final CTA
- [~] Homepage redesign implementation
  - [~] reduce generic SaaS card-grid feel
  - [~] increase spacing and section rhythm
  - [~] make mobile mockup support the story, not dominate it
  - [x] simplify CTA system to `Start Free Today` + `Watch 60-Second Demo`
  - [~] ensure homepage language reads like shop-owner conversation, not software marketing
- [ ] Supporting pages alignment
  - [x] `/features` → outcomes / philosophy aligned to homepage
  - [x] `/pricing` → lighter, calmer, growth-oriented
  - [x] `/how-it-works` → plain-language onboarding story
- [~] Copy and localization
  - [~] English copy pass complete
  - [~] Nepali copy aligned with final English positioning
  - [x] banned phrase audit across all message files and pages
- [ ] Interaction and conversion cleanup
  - [x] define real destination for `Start Free Today`
  - [x] define placeholder destination for `Watch 60-Second Demo`
  - [ ] decide whether pricing `Notify me` stays and connect it to a real flow if kept
- [ ] Final QA
  - [ ] homepage visual consistency pass
  - [ ] mobile spacing and readability pass
  - [x] lint pass after first homepage redesign pass

---

## Open Questions

| # | Question | Status |
|---|---|---|
| 1 | Domain decided? (e.g. `smedigital.com.np`) | Pending |
| 2 | App store links ready? (Play Store / App Store) | Pending |
| 3 | Real device screenshots available? | Pending |
| 4 | "Start Free" → where does it go? (app download / web signup) | Pending |
| 5 | Pro plan pricing decided? | Pending |

---

## File Structure (target)

```
web/
├── app/
│   ├── layout.tsx          ← metadata, fonts
│   ├── page.tsx            ← assembles all sections
│   ├── globals.css         ← brand tokens + base styles
│   ├── privacy/page.tsx
│   └── terms/page.tsx
├── components/
│   ├── layout/
│   │   ├── Navbar.tsx
│   │   └── Footer.tsx
│   ├── sections/
│   │   ├── Hero.tsx
│   │   ├── SocialProof.tsx
│   │   ├── Features.tsx
│   │   ├── HowItWorks.tsx
│   │   ├── Pricing.tsx
│   │   └── CallToAction.tsx
│   └── ui/
│       ├── Button.tsx
│       ├── Badge.tsx
│       └── SectionLabel.tsx
└── public/
    ├── logo.svg
    ├── og-image.png
    └── screenshots/
        ├── dashboard.png
        ├── create-sale.png
        ├── product-form.png
        └── onboarding.png
```
