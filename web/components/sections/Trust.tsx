"use client";

import { useTranslations } from "next-intl";
import SectionLabel from "@/components/ui/SectionLabel";

export default function Trust() {
  const t = useTranslations("trust");
  const items = t.raw("items") as string[];
  const itemTints = [
    "bg-success-bg text-primary-foreground ring-1 ring-success/22",
    "bg-white/12 text-primary-foreground ring-1 ring-white/12",
    "bg-white/10 text-primary-foreground ring-1 ring-ring/24",
    "bg-white/12 text-primary-foreground ring-1 ring-warning/20",
    "bg-white/10 text-primary-foreground ring-1 ring-accent/20",
  ] as const;

  return (
    <section className="section-shell-tight bg-primary">
      <div className="section-container">
        <div className="section-header">
          <SectionLabel>{t("label")}</SectionLabel>
          <h2 className="section-title-inverse">
            {t("heading")}
          </h2>
          <p className="section-copy-inverse mt-4 max-w-2xl mx-auto">
            {t("subtext")}
          </p>
        </div>

        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-5 gap-3.5 sm:gap-5">
          {items.map((item) => (
            <div
              key={item}
              className={`rounded-2xl px-4 py-4.5 sm:px-5 sm:py-6 text-sm text-primary-foreground/88 text-center leading-6 ${itemTints[items.indexOf(item)] ?? "bg-white/10"}`}
            >
              {item}
            </div>
          ))}
        </div>

        <div className="mt-8 text-center text-sm text-primary-foreground/72">
          {t("footnote")}
        </div>
      </div>
    </section>
  );
}
