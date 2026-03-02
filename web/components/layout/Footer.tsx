"use client";

import { useTranslations, useLocale } from "next-intl";
import { usePathname } from "next/navigation";
import Image from "next/image";
import { Separator } from "@/components/ui/separator";
import { appConfig } from "@/lib/config";
import LocaleToggle from "@/components/ui/LocaleToggle";

export default function Footer() {
  const t        = useTranslations("footer");
  const locale   = useLocale();
  const pathname = usePathname();

  const featureLinks = t.raw("featureLinks") as string[];
  const companyLinks = t.raw("companyLinks") as { label: string; href: string }[];

  return (
    <footer className="bg-surface border-t border-border">
      <div className="max-w-6xl mx-auto px-4 sm:px-6 py-12">

        {/* Grid */}
        <div className="grid grid-cols-2 md:grid-cols-4 gap-8 mb-10">

          {/* Brand */}
          <div className="col-span-2 md:col-span-1">
            <div className="flex items-center gap-2 mb-3">
              <Image
                src="/logos/logo.svg"
                alt={appConfig.name}
                width={28}
                height={28}
              />
              <span className="text-base font-semibold text-label">{appConfig.name}</span>
            </div>
            <p className="text-sm text-muted leading-relaxed max-w-[180px]">
              {t("tagline")}
            </p>
          </div>

          {/* Features */}
          <div>
            <p className="text-xs font-semibold uppercase tracking-wider text-muted mb-4">
              {t("sections.features")}
            </p>
            <ul className="space-y-2.5">
              {featureLinks.map((item) => (
                <li key={item}>
                  <a href="#features" className="text-sm text-muted hover:text-label transition-colors">
                    {item}
                  </a>
                </li>
              ))}
            </ul>
          </div>

          {/* Company */}
          <div>
            <p className="text-xs font-semibold uppercase tracking-wider text-muted mb-4">
              {t("sections.company")}
            </p>
            <ul className="space-y-2.5">
              {companyLinks.map(({ label, href }) => {
                const localHref = href.startsWith("/") && href !== "#"
                  ? `/${locale}${href}`
                  : href;
                return (
                  <li key={label}>
                    <a href={localHref} className="text-sm text-muted hover:text-label transition-colors">
                      {label}
                    </a>
                  </li>
                );
              })}
            </ul>
          </div>

          {/* Language */}
          <div>
            <p className="text-xs font-semibold uppercase tracking-wider text-muted mb-4">
              {t("sections.language")}
            </p>
            <LocaleToggle pathname={pathname} locale={locale} />
          </div>
        </div>

        <Separator className="mb-8" />

        {/* Bottom bar */}
        <div className="flex flex-col sm:flex-row items-center justify-between gap-2">
          <p className="text-xs text-muted">© {new Date().getFullYear()} {appConfig.name}. {t("copy")}</p>
          <p className="text-xs text-muted">{t("made")}</p>
        </div>
      </div>
    </footer>
  );
}
