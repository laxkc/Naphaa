"use client";

import { useTranslations } from "next-intl";
import SectionLabel from "@/components/ui/SectionLabel";

const outcomeKeys = ["sale", "profit", "credit", "stock", "performance"] as const;
const outcomeTint: Record<typeof outcomeKeys[number], { ring: string; check: string }> = {
  sale: { ring: "ring-accent/18", check: "text-accent" },
  profit: { ring: "ring-primary/14", check: "text-primary" },
  credit: { ring: "ring-success/16", check: "text-success" },
  stock: { ring: "ring-warning/20", check: "text-warning" },
  performance: { ring: "ring-primary/12", check: "text-primary" },
};

export default function Outcomes() {
  const t = useTranslations("outcomes");

  return (
    <section className="section-shell bg-background">
      <div className="section-container">
        <div className="section-header">
          <SectionLabel>{t("label")}</SectionLabel>
          <h2 className="section-title">
            {t("heading")}
          </h2>
          <p className="section-copy mt-4 max-w-2xl mx-auto">
            {t("subtext")}
          </p>
        </div>

        <div className="max-w-4xl mx-auto grid grid-cols-1 md:grid-cols-2 gap-4 sm:gap-5">
          {outcomeKeys.map((key) => (
            <div
              key={key}
              className={`surface-panel px-5 py-4.5 text-sm text-foreground leading-6 ring-1 ${outcomeTint[key].ring}`}
            >
              <span className={`font-semibold mr-2 ${outcomeTint[key].check}`}>✔</span>
              {t(`items.${key}`)}
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}
