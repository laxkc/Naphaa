"use client";

import { useState } from "react";
import { useTranslations } from "next-intl";
import SectionLabel from "@/components/ui/SectionLabel";

export default function FAQ() {
  const t     = useTranslations("faq");
  const items = t.raw("items") as { q: string; a: string }[];
  const [open, setOpen] = useState<number | null>(null);

  function toggle(i: number) {
    setOpen((prev) => (prev === i ? null : i));
  }

  return (
    <section className="section-shell bg-card">
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

        <div className="max-w-3xl mx-auto flex flex-col gap-3">
          {items.map(({ q, a }, i) => (
            <div
              key={q}
              className={`surface-panel overflow-hidden bg-background transition-colors ${
                i === open ? "ring-2 ring-ring/24 bg-primary/5" : "ring-1 ring-border hover:ring-ring/18"
              }`}
            >
              <button
                onClick={() => toggle(i)}
                className="w-full flex items-center justify-between gap-4 px-5 sm:px-6 py-4.5 sm:py-5 text-left"
                aria-expanded={open === i}
              >
                <span className={`text-sm sm:text-base font-semibold leading-6 ${
                  i === 0
                    ? "text-success"
                    : i === 2
                      ? "text-warning"
                      : "text-foreground"
                }`}>{q}</span>
                <span
                  className={`text-lg leading-none shrink-0 transition-transform duration-200 ${
                    i === open ? "text-ring" : "text-primary"
                  }`}
                  style={{ transform: open === i ? "rotate(45deg)" : "rotate(0deg)" }}
                >
                  +
                </span>
              </button>

              {open === i && (
                <div className="px-5 sm:px-6 pb-5 sm:pb-6">
                  <p className="text-sm text-muted-foreground leading-7">{a}</p>
                </div>
              )}
            </div>
          ))}
        </div>

      </div>
    </section>
  );
}
