"use client";

import { useTranslations } from "next-intl";
import SectionLabel from "@/components/ui/SectionLabel";
import { Badge } from "@/components/ui/badge";

const stepKeys = ["one", "two", "three"] as const;

export default function HowItWorks() {
  const t = useTranslations("howItWorks");

  return (
    <section id="how-it-works" className="section-shell bg-background">
      <div className="section-container">
        <div className="section-header">
          <SectionLabel>{t("label")}</SectionLabel>
          <h2 className="section-title">
            {t("heading")}
          </h2>
          <p className="section-copy mt-4 max-w-xl mx-auto">
            {t("subtext")}
          </p>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-3 gap-7 sm:gap-10 relative">
          <div className="hidden md:block absolute top-10 left-[calc(16.67%+1rem)] right-[calc(16.67%+1rem)] h-px bg-border z-0" />

          {stepKeys.map((key) => (
            <div
              key={key}
              className="relative flex flex-col items-center text-center md:items-start md:text-left"
            >
              <div className="relative z-10 w-20 h-20 rounded-2xl bg-card border border-border shadow-sm flex flex-col items-center justify-center mb-5 sm:mb-6 shrink-0">
                <span className="text-[22px] font-semibold text-primary leading-none">
                  {t(`steps.${key}.number`)}
                </span>
              </div>

              <h3 className="text-[17px] font-semibold text-foreground leading-6 mb-2">
                {t(`steps.${key}.title`)}
              </h3>
              <p className="text-sm text-muted-foreground leading-6 mb-3">{t(`steps.${key}.desc`)}</p>
              <Badge className={`border-0 rounded-full px-3 py-1 text-xs font-medium ${
                key === "one"
                  ? "bg-success/10 text-success"
                  : key === "two"
                    ? "bg-warning/10 text-warning"
                    : "bg-primary/10 text-primary"
              }`}>
                {t(`steps.${key}.tag`)}
              </Badge>
              <p className="text-xs text-muted-foreground mt-3 leading-6 max-w-full md:max-w-[18rem]">
                {t(`steps.${key}.detail`)}
              </p>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}
