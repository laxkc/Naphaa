"use client";

import { useTranslations } from "next-intl";
import SectionLabel from "@/components/ui/SectionLabel";

const DEMO_URL = "https://youtu.be/UF8uR6Z6KLc?si=zsdxoe3KvaFDiarj";
const DEMO_EMBED_URL = "https://www.youtube-nocookie.com/embed/UF8uR6Z6KLc?rel=0";

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

            <div className="mt-6 sm:mt-7 flex flex-col gap-3 text-sm text-foreground">
              {(t.raw("points") as string[]).map((point, index) => (
                <div key={point} className={`surface-panel px-4 py-3.5 bg-background ring-1 ${pointTints[index] ?? "ring-primary/12 bg-background"}`}>
                  <span className={`${index === 1 ? "text-success" : index === 2 ? "text-warning" : "text-primary"} font-semibold mr-2`}>•</span>
                  {point}
                </div>
              ))}
            </div>

            <div className="mt-6 flex flex-col sm:flex-row gap-3">
              <a
                href={DEMO_URL}
                target="_blank"
                rel="noreferrer"
                className="inline-flex items-center justify-center rounded-xl bg-primary text-primary-foreground text-sm font-semibold px-5 py-3 hover:bg-primary/90 transition-colors"
              >
                {t("primaryCta")}
              </a>
              <a
                href="#pricing"
                className="inline-flex items-center justify-center rounded-xl border border-border bg-background text-sm font-medium text-foreground px-5 py-3 hover:bg-muted/60 transition-colors"
              >
                {t("secondaryCta")}
              </a>
            </div>
          </div>

          <div className="surface-panel rounded-[24px] sm:rounded-[28px] bg-background p-3.5 sm:p-5 ring-1 ring-ring/20">
            <div className="relative aspect-video rounded-[22px] overflow-hidden bg-black ring-1 ring-border">
              <iframe
                className="absolute inset-0 h-full w-full"
                src={DEMO_EMBED_URL}
                title={t("videoTitle")}
                loading="lazy"
                allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share"
                referrerPolicy="strict-origin-when-cross-origin"
                allowFullScreen
              />
            </div>

            <div className="mt-4 rounded-2xl bg-card border border-border px-4 py-4 text-sm text-muted-foreground leading-6 ring-1 ring-success/12">
              <div className="font-medium text-foreground mb-1">{t("noteTitle")}</div>
              <div>{t("note")}</div>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}
