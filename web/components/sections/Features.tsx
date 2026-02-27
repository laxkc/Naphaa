"use client";

import { useTranslations } from "next-intl";
import SectionLabel from "@/components/ui/SectionLabel";
import { Card, CardContent } from "@/components/ui/card";

const featureKeys = ["sales", "inventory", "credit", "reports", "offline", "invoices"] as const;
const featureMeta: Record<typeof featureKeys[number], { emoji: string; iconTintClass: string }> = {
  sales:     { emoji: "⚡", iconTintClass: "bg-primary/10" },
  inventory: { emoji: "📦", iconTintClass: "bg-accent/10" },
  credit:    { emoji: "👥", iconTintClass: "bg-primary-hover/10" },
  reports:   { emoji: "📊", iconTintClass: "bg-primary/10" },
  offline:   { emoji: "🔌", iconTintClass: "bg-success/10" },
  invoices:  { emoji: "🧾", iconTintClass: "bg-accent/10" },
};

export default function Features() {
  const t = useTranslations("features");

  return (
    <section id="features" className="py-20 bg-surface">
      <div className="max-w-6xl mx-auto px-4 sm:px-6">

        {/* Header */}
        <div className="text-center mb-14">
          <SectionLabel>{t("label")}</SectionLabel>
          <h2 className="text-[22px] font-semibold text-label leading-[28px] tracking-tight">
            {t("heading")}
          </h2>
          <p className="text-sm text-muted mt-2 leading-5">{t("subheading")}</p>
        </div>

        {/* Grid */}
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-5">
          {featureKeys.map((key) => {
            const { emoji, iconTintClass } = featureMeta[key];
            return (
              <Card
                key={key}
                className="bg-bg rounded-2xl p-0 gap-0 border-0 shadow-none hover:shadow-md transition-all duration-200 hover:-translate-y-0.5"
              >
                <CardContent className="p-6">
                  <div className={`w-11 h-11 rounded-2xl flex items-center justify-center text-xl mb-4 ${iconTintClass}`}>
                    {emoji}
                  </div>
                  <h3 className="text-base font-semibold text-label leading-[22px] mb-1.5">
                    {t(`items.${key}.title`)}
                  </h3>
                  <p className="text-sm text-muted leading-5">{t(`items.${key}.desc`)}</p>
                </CardContent>
              </Card>
            );
          })}
        </div>

      </div>
    </section>
  );
}
