"use client";

import { BarChart3, Smartphone, SlidersHorizontal, Wifi } from "lucide-react";
import { useTranslations } from "next-intl";
import SectionLabel from "@/components/ui/SectionLabel";
import { Card, CardContent } from "@/components/ui/card";

const featureKeys = ["profit", "phoneFirst", "simple", "offline"] as const;
const featureMeta: Record<typeof featureKeys[number], { icon: React.ComponentType<{ className?: string }>; iconTintClass: string; iconClass: string }> = {
  profit: {
    icon: BarChart3,
    iconTintClass: "bg-primary/10",
    iconClass: "text-primary",
  },
  phoneFirst: {
    icon: Smartphone,
    iconTintClass: "bg-accent/10",
    iconClass: "text-accent",
  },
  simple: {
    icon: SlidersHorizontal,
    iconTintClass: "bg-warning/10",
    iconClass: "text-warning",
  },
  offline: {
    icon: Wifi,
    iconTintClass: "bg-success/10",
    iconClass: "text-success",
  },
};
const featureCardTint: Record<typeof featureKeys[number], string> = {
  profit: "ring-primary/14",
  phoneFirst: "ring-accent/18",
  simple: "ring-warning/18",
  offline: "ring-success/18",
};
const featureTitleTint: Record<typeof featureKeys[number], string> = {
  profit: "text-primary",
  phoneFirst: "text-accent",
  simple: "text-warning",
  offline: "text-success",
};

export default function Features() {
  const t = useTranslations("difference");

  return (
    <section id="features" className="section-shell bg-card">
      <div className="section-container">
        <div className="section-header">
          <SectionLabel>{t("label")}</SectionLabel>
          <h2 className="section-title">
            {t("heading")}
          </h2>
          <p className="section-copy mt-4 max-w-2xl mx-auto">{t("subtext")}</p>
        </div>

        <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 sm:gap-6 max-w-4xl mx-auto">
          {featureKeys.map((key) => {
            const { icon: Icon, iconTintClass, iconClass } = featureMeta[key];
            return (
              <Card
                key={key}
                className={`bg-background rounded-3xl p-0 gap-0 border border-border shadow-sm ring-1 ${featureCardTint[key]}`}
              >
                <CardContent className="p-5 sm:p-7">
                  <div className={`w-12 h-12 rounded-2xl flex items-center justify-center mb-5 ${iconTintClass}`}>
                    <Icon className={`w-5 h-5 ${iconClass}`} />
                  </div>
                  <h3 className={`text-[17px] font-semibold leading-6 mb-2 ${featureTitleTint[key]}`}>
                    {t(`items.${key}.title`)}
                  </h3>
                  <p className="text-sm text-muted-foreground leading-6">{t(`items.${key}.desc`)}</p>
                </CardContent>
              </Card>
            );
          })}
        </div>
      </div>
    </section>
  );
}
