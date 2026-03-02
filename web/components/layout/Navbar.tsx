"use client";

import { useState } from "react";
import Link from "next/link";
import Image from "next/image";
import { usePathname } from "next/navigation";
import { useTranslations, useLocale } from "next-intl";
import { Menu, X } from "lucide-react";
import { appConfig } from "@/lib/config";
import LocaleToggle from "@/components/ui/LocaleToggle";

export default function Navbar() {
  const [open, setOpen] = useState(false);
  const pathname        = usePathname();
  const locale          = useLocale();
  const t               = useTranslations("nav");

  const navLinks = [
    { label: t("home"),       href: `/${locale}`              },
    { label: t("features"),   href: `/${locale}/features`     },
    { label: t("howItWorks"), href: `/${locale}/how-it-works` },
    { label: t("pricing"),    href: `/${locale}/pricing`      },
  ];

  const isActive = (href: string) =>
    href === `/${locale}` ? pathname === `/${locale}` : pathname.startsWith(href);

  return (
    <header className="shrink-0 z-50 bg-surface border-b border-border">
      <div className="max-w-6xl mx-auto px-4 sm:px-6 h-16 flex items-center">

        {/* ── Left: Logo ─────────────────────────────── */}
        <Link href={`/${locale}`} className="flex items-center gap-2 shrink-0">
          {/* Mobile: 24px */}
          <Image
            src="/logos/logo.svg"
            alt={appConfig.name}
            width={24}
            height={24}
            className="md:hidden"
            priority
          />
          {/* Desktop: 32px */}
          <Image
            src="/logos/logo.svg"
            alt={appConfig.name}
            width={32}
            height={32}
            className="hidden md:block"
            priority
          />
          <span className="text-lg font-semibold tracking-tight text-primary">
            {appConfig.name}
          </span>
        </Link>

        {/* ── Center: Nav links ───────────────────────── */}
        <nav className="hidden md:flex items-center gap-1 flex-1 justify-center">
          {navLinks.map(({ label, href }) => (
            <Link
              key={href}
              href={href}
              className={`px-3.5 py-1.5 text-sm rounded-lg transition-colors ${
                isActive(href)
                  ? "text-primary font-semibold bg-hover-overlay"
                  : "text-label-sub hover:text-primary hover:bg-hover-overlay"
              }`}
            >
              {label}
            </Link>
          ))}
        </nav>

        {/* ── Right: Language ─────────────────────────── */}
        <div className="hidden md:flex items-center gap-2 ml-auto">
          <LocaleToggle pathname={pathname} locale={locale} />
        </div>

        {/* ── Mobile: Hamburger ───────────────────────── */}
        <button
          className="md:hidden ml-auto p-2 rounded-lg text-label hover:bg-hover-overlay transition-colors"
          onClick={() => setOpen(!open)}
          aria-label="Toggle menu"
        >
          {open ? <X className="w-5 h-5" /> : <Menu className="w-5 h-5" />}
        </button>
      </div>

      {/* ── Mobile drawer ───────────────────────────── */}
      {open && (
        <div className="md:hidden bg-surface border-t border-border px-4 pb-5">
          <nav className="flex flex-col gap-0.5 pt-3">
            {navLinks.map(({ label, href }) => (
              <Link
                key={href}
                href={href}
                onClick={() => setOpen(false)}
                className={`py-2.5 px-3 text-sm rounded-lg transition-colors ${
                  isActive(href)
                    ? "text-primary font-semibold bg-hover-overlay"
                    : "text-label-sub hover:text-primary hover:bg-hover-overlay"
                }`}
              >
                {label}
              </Link>
            ))}
          </nav>

          <div className="mt-4 pt-4 border-t border-border">
            <LocaleToggle pathname={pathname} locale={locale} onSwitch={() => setOpen(false)} />
          </div>
        </div>
      )}
    </header>
  );
}
