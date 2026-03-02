"use client";

import { PlayCircle } from "lucide-react";
import { useTranslations } from "next-intl";
import SectionLabel from "@/components/ui/SectionLabel";

export default function Demo() {
  const t = useTranslations("demo");
  const pointTints = [
    "ring-primary/12 bg-primary/5",
    "ring-success/14 bg-success/5",
    "ring-warning/16 bg-warning/6",
  ] as const;

  return (
    <section id="demo" className="section-shell bg-card">
      <div className="section-container">
        <div className="grid grid-cols-1 lg:grid-cols-[0.9fr_1.1fr] gap-8 lg:gap-12 items-center">
          <div className="max-w-xl">
            <SectionLabel>{t("label")}</SectionLabel>
            <h2 className="section-title">
              {t("heading")}
            </h2>
            <p className="section-copy mt-4">
              {t("desc")}
            </p>

            <div className="mt-7 flex flex-col gap-3 text-sm text-foreground">
              {(t.raw("points") as string[]).map((point, index) => (
                <div key={point} className={`surface-panel px-4 py-3.5 bg-background ring-1 ${pointTints[index] ?? "ring-primary/12 bg-background"}`}>
                  <span className={`${index === 1 ? "text-success" : index === 2 ? "text-warning" : "text-primary"} font-semibold mr-2`}>•</span>
                  {point}
                </div>
              ))}
            </div>
          </div>

          <div className="surface-panel rounded-[28px] bg-background p-4 sm:p-5 ring-1 ring-ring/20">
            <div className="relative aspect-video rounded-[22px] overflow-hidden bg-gradient-to-br from-primary to-primary-hover ring-2 ring-white/12">
              <div className="absolute inset-0 bg-[radial-gradient(circle_at_top_left,rgba(255,255,255,0.14),transparent_38%),radial-gradient(circle_at_bottom_right,rgba(255,255,255,0.12),transparent_32%)]" />
              <div className="relative h-full w-full flex flex-col items-center justify-center text-center px-6">
                <PlayCircle className="w-14 h-14 text-white/90 mb-4 drop-shadow-sm" />
                <div className="text-white text-lg font-semibold tracking-tight">
                  {t("placeholderTitle")}
                </div>
                <p className="text-white/70 text-sm mt-2 max-w-sm leading-6">
                  {t("placeholderDesc")}
                </p>
              </div>
            </div>

            <div className="mt-4 rounded-2xl bg-card border border-border px-4 py-4 text-sm text-muted-foreground leading-6 ring-1 ring-success/12">
              {t("note")}
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}
