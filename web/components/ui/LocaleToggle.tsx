"use client";

import Link from "next/link";
import { saveLocale } from "@/components/LocaleSync";

const locales = [
  { code: "en", label: "EN", text: "English" },
  { code: "ne", label: "NE", text: "नेपाली"  },
] as const;

export default function LocaleToggle({
  pathname,
  locale,
  onSwitch,
}: {
  pathname: string;
  locale: string;
  onSwitch?: () => void;
}) {
  return (
    <div className="flex items-center rounded-lg border border-border overflow-hidden">
      {locales.map(({ code, label, text }, i) => {
        const href   = pathname.replace(new RegExp(`^/${locale}(/|$)`), `/${code}$1`);
        const active = locale === code;

        return (
          <div key={code} className="flex items-center">
            {i > 0 && <span className="w-px h-4 bg-border" />}
            <Link
              href={href}
              onClick={() => { saveLocale(code); onSwitch?.(); }}
              className={`flex items-center gap-1.5 px-3 py-1.5 transition-colors ${
                active
                  ? "bg-primary text-primary-foreground"
                  : "text-muted-foreground hover:text-foreground hover:bg-muted"
              }`}
            >
              <span className="text-[10px] font-bold uppercase tracking-wide leading-none">
                {label}
              </span>
              <span className="text-xs font-medium leading-none">
                {text}
              </span>
            </Link>
          </div>
        );
      })}
    </div>
  );
}
