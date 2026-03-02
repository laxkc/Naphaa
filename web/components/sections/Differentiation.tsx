"use client";

import { useTranslations } from "next-intl";
import SectionLabel from "@/components/ui/SectionLabel";

export default function Differentiation() {
  const t     = useTranslations("differentiation");
  const items = t.raw("items") as { vs: string; text: string }[];

  return (
    <section className="py-20 bg-background">
      <div className="max-w-6xl mx-auto px-4 sm:px-6">

        <div className="text-center mb-12">
          <SectionLabel>{t("label")}</SectionLabel>
          <h2 className="text-[22px] font-semibold text-foreground leading-[28px] tracking-tight">
            {t("heading")}
          </h2>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-3 gap-5 max-w-4xl mx-auto">
          {items.map(({ vs, text }) => (
            <div
              key={vs}
              className="flex flex-col gap-3 rounded-2xl bg-card border border-border p-6"
            >
              <span className="inline-block text-xs font-semibold uppercase tracking-wider text-primary bg-primary/8 rounded-full px-3 py-1 self-start">
                {vs}
              </span>
              <p className="text-sm text-muted-foreground leading-relaxed">{text}</p>
            </div>
          ))}
        </div>

      </div>
    </section>
  );
}
