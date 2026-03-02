"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import Image from "next/image";
import { usePathname } from "next/navigation";
import { useTranslations, useLocale } from "next-intl";
import { Menu, X } from "lucide-react";
import { appConfig } from "@/lib/config";
import LocaleToggle from "@/components/ui/LocaleToggle";

export default function Navbar() {
  const [open, setOpen] = useState(false);
  const [hash, setHash] = useState("");
  const pathname        = usePathname();
  const locale          = useLocale();
  const t               = useTranslations("nav");
  const homeHref        = `/${locale}`;

  const navLinks = [
    {
      label: t("home"),
      href: homeHref,
      targetHash: "",
      routeMatches: [homeHref],
    },
    {
      label: t("features"),
      href: `${homeHref}#features`,
      targetHash: "#features",
      routeMatches: [`${locale ? `/${locale}/features` : ""}`],
    },
    {
      label: t("howItWorks"),
      href: `${homeHref}#how-it-works`,
      targetHash: "#how-it-works",
      routeMatches: [`${locale ? `/${locale}/how-it-works` : ""}`],
    },
  ];

  useEffect(() => {
    const syncHash = () => setHash(window.location.hash);
    syncHash();
    window.addEventListener("hashchange", syncHash);
    return () => window.removeEventListener("hashchange", syncHash);
  }, []);

  useEffect(() => {
    if (pathname !== homeHref) return;

    const sectionIds = ["features", "how-it-works"] as const;
    const sections = sectionIds
      .map((id) => document.getElementById(id))
      .filter((section): section is HTMLElement => Boolean(section));

    if (sections.length === 0) return;

    const updateActiveSection = () => {
      const navbarOffset = 96;
      const current = sections.findLast((section) => section.getBoundingClientRect().top - navbarOffset <= 0);
      const nextHash = current ? `#${current.id}` : "";

      setHash((prev) => (prev === nextHash ? prev : nextHash));
    };

    updateActiveSection();
    window.addEventListener("scroll", updateActiveSection, { passive: true });
    window.addEventListener("resize", updateActiveSection);

    return () => {
      window.removeEventListener("scroll", updateActiveSection);
      window.removeEventListener("resize", updateActiveSection);
    };
  }, [pathname, homeHref]);

  const isActive = (targetHash: string, routeMatches: string[]) => {
    if (pathname === homeHref) {
      if (!targetHash) return hash === "" || hash === "#";
      return hash === targetHash;
    }

    return routeMatches.includes(pathname);
  };

  return (
    <header className="sticky top-0 shrink-0 z-50 border-b border-border/80 bg-surface/88 backdrop-blur-md shadow-[0_1px_0_rgba(11,57,84,0.04)]">
      <div className="max-w-6xl mx-auto px-4 sm:px-6 lg:px-8 h-15 sm:h-16 flex items-center gap-3 sm:gap-4">

        <Link href={homeHref} className="flex items-center gap-2.5 shrink-0">
          <Image
            src="/logos/logo.svg"
            alt={appConfig.name}
            width={24}
            height={24}
            className="md:hidden"
            priority
          />
          <Image
            src="/logos/logo.svg"
            alt={appConfig.name}
            width={32}
            height={32}
            className="hidden md:block"
            priority
          />
          <span className="text-base sm:text-lg font-semibold tracking-tight text-primary">
            {appConfig.name}
          </span>
        </Link>

        <nav className="hidden md:flex items-center gap-1 flex-1 justify-center min-w-0">
          {navLinks.map(({ label, href, targetHash, routeMatches }) => (
            <Link
              key={href}
              href={href}
              scroll
              className={`px-3 py-2 lg:px-3.5 text-sm rounded-xl transition-all whitespace-nowrap ${
                isActive(targetHash, routeMatches)
                  ? "bg-primary text-primary-foreground font-semibold shadow-sm"
                  : "text-muted-foreground hover:text-foreground hover:bg-muted/80"
              }`}
            >
              {label}
            </Link>
          ))}
        </nav>

        <div className="hidden md:flex items-center gap-2 ml-auto">
          <LocaleToggle pathname={pathname} locale={locale} />
        </div>

        <button
          className="md:hidden ml-auto p-2 rounded-xl text-foreground hover:bg-muted/80 transition-colors shrink-0"
          onClick={() => setOpen(!open)}
          aria-label="Toggle menu"
        >
          {open ? <X className="w-5 h-5" /> : <Menu className="w-5 h-5" />}
        </button>
      </div>

      {open && (
        <div className="md:hidden bg-surface/96 backdrop-blur-md border-t border-border px-4 py-3 shadow-sm">
          <nav className="flex flex-col gap-1">
            {navLinks.map(({ label, href, targetHash, routeMatches }) => (
              <Link
                key={href}
                href={href}
                onClick={() => setOpen(false)}
                scroll
                className={`py-3 px-3.5 text-sm rounded-xl transition-all ${
                  isActive(targetHash, routeMatches)
                    ? "bg-primary text-primary-foreground font-semibold shadow-sm"
                    : "text-muted-foreground hover:text-foreground hover:bg-muted/80"
                }`}
              >
                {label}
              </Link>
            ))}
          </nav>

          <div className="mt-3 pt-3 border-t border-border">
            <LocaleToggle pathname={pathname} locale={locale} onSwitch={() => setOpen(false)} />
          </div>
        </div>
      )}
    </header>
  );
}
