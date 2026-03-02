"use client";

import { useTranslations } from "next-intl";
import SectionLabel from "@/components/ui/SectionLabel";

export default function Problem() {
  const t = useTranslations("whoItsFor");
  const items = t.raw("items") as string[];

  return (
    <section className="section-shell bg-card">
      <div className="section-container">
        <div className="section-header">
          <SectionLabel>{t("label")}</SectionLabel>
          <h2 className="section-title">
            {t("heading")}
          </h2>
          <p className="section-copy mt-4 max-w-3xl mx-auto">
            {t("desc")}
          </p>
        </div>

        <div className="max-w-5xl mx-auto grid grid-cols-1 lg:grid-cols-[1.05fr_0.95fr] gap-6 lg:gap-8 items-start">
          <div className="surface-panel bg-background p-6 sm:p-8">
            <div className="text-sm font-semibold text-foreground mb-5">
              {t("shopTypesHeading")}
            </div>
            <div className="flex flex-wrap gap-3">
              {(t.raw("shopTypes") as string[]).map((shopType) => (
                <span
                  key={shopType}
                  className="rounded-full border border-border bg-card px-4 py-2.5 text-sm text-foreground"
                >
                  {shopType}
                </span>
              ))}
            </div>
          </div>

          <div className="flex flex-col gap-3.5">
            {items.map((item) => (
              <div key={item} className="surface-panel bg-background px-5 py-4.5 text-sm text-foreground leading-6">
                <span className="text-primary font-semibold mr-2">✔</span>
                {item}
              </div>
            ))}
          </div>
        </div>
      </div>
    </section>
  );
}
