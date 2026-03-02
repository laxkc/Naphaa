"use client";

import { useTranslations, useLocale } from "next-intl";
import Image from "next/image";
import { appConfig } from "@/lib/config";

// Bikram Sambat year — Nepali new year falls ~April 14 each year
function getBSYear(): number {
  const now   = new Date();
  const after = now.getMonth() > 3 || (now.getMonth() === 3 && now.getDate() >= 14);
  return now.getFullYear() + (after ? 57 : 56);
}

const NE_DIGITS: Record<string, string> = {
  "0": "०", "1": "१", "2": "२", "3": "३", "4": "४",
  "5": "५", "6": "६", "7": "७", "8": "८", "9": "९",
};

function toNepaliNumeral(n: number): string {
  return String(n).replace(/[0-9]/g, (d) => NE_DIGITS[d]);
}

export default function Footer() {
  const t      = useTranslations("footer");
  const locale = useLocale();
  const bsYear = getBSYear();
  const year   = locale === "ne" ? toNepaliNumeral(bsYear) : bsYear;

  return (
    <footer className="bg-surface border-t border-border">
      <div className="max-w-6xl mx-auto px-4 sm:px-6 lg:px-8 py-6 sm:py-7 flex flex-col lg:flex-row items-center justify-between gap-3 sm:gap-4">

        <div className="flex items-center gap-2.5">
          <Image src="/logos/logo.svg" alt={appConfig.name} width={22} height={22} />
          <span className="text-sm font-semibold tracking-tight text-primary">{appConfig.name}</span>
        </div>

        <p className="text-xs sm:text-sm text-muted-foreground text-center max-w-xs sm:max-w-none">
          © {year} {appConfig.name}. {t("copy")}
        </p>

        <p className="text-xs sm:text-sm text-muted-foreground text-center max-w-xs sm:max-w-none">{t("made")}</p>

      </div>
    </footer>
  );
}
