"use client";

import { useTranslations } from "next-intl";
import SectionLabel from "@/components/ui/SectionLabel";
import { Badge } from "@/components/ui/badge";

const stepKeys = ["one", "two", "three"] as const;

export default function HowItWorks() {
  const t = useTranslations("howItWorks");

  return (
    <section id="how-it-works" className="py-20 bg-bg">
      <div className="max-w-6xl mx-auto px-4 sm:px-6">

        {/* Header */}
        <div className="text-center mb-14">
          <SectionLabel>{t("label")}</SectionLabel>
          <h2 className="text-[22px] font-semibold text-label leading-[28px] tracking-tight">
            {t("heading")}
          </h2>
          <p className="text-sm text-muted mt-3 max-w-sm mx-auto leading-5">
            {t("subtext")}
          </p>
        </div>

        {/* Steps */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-8 relative">

          {/* Connector line (desktop only) */}
          <div className="hidden md:block absolute top-10 left-[calc(16.67%+1rem)] right-[calc(16.67%+1rem)] h-px bg-border z-0" />

          {stepKeys.map((key) => (
            <div
              key={key}
              className="relative flex flex-col items-center text-center md:items-start md:text-left"
            >
              {/* Number badge */}
              <div className="relative z-10 w-20 h-20 rounded-2xl bg-surface border border-border shadow-sm flex flex-col items-center justify-center mb-5 shrink-0">
                <span className="text-[22px] font-semibold text-primary leading-none">
                  {t(`steps.${key}.number`)}
                </span>
              </div>

              <h3 className="text-base font-semibold text-label leading-[22px] mb-2">
                {t(`steps.${key}.title`)}
              </h3>
              <p className="text-sm text-muted leading-5 mb-3">{t(`steps.${key}.desc`)}</p>
              <Badge className="border-0 rounded-full px-3 py-1 text-xs font-medium bg-primary/8 text-primary">
                {t(`steps.${key}.tag`)}
              </Badge>
            </div>
          ))}

        </div>
      </div>
    </section>
  );
}
