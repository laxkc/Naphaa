"use client";

import { useTranslations } from "next-intl";
import StoreButtons from "@/components/ui/StoreButtons";
import { Badge } from "@/components/ui/badge";

export default function CallToAction() {
  const t = useTranslations("cta");

  return (
    <section id="download" className="section-shell bg-background">
      <div className="section-container">
        <div
          className="relative rounded-[32px] px-6 sm:px-8 lg:px-12 py-14 sm:py-18 text-center overflow-hidden bg-gradient-to-br from-primary to-primary-hover"
        >
          {/* Decorative circles */}
          <div className="absolute -top-10 -right-10 w-48 h-48 rounded-full pointer-events-none bg-white/5" />
          <div className="absolute -bottom-14 left-8 w-36 h-36 rounded-full pointer-events-none bg-white/4" />

          <div className="relative">
            <Badge
              className="gap-2 px-4 py-1.5 rounded-full mb-6 border-0 text-xs font-semibold bg-white/15 text-white/85"
            >
              {t("badge")}
            </Badge>

            <h2 className="text-[30px] sm:text-[40px] font-semibold text-primary-foreground leading-[1.08] tracking-tight mb-4">
              {t("heading")}
            </h2>
            <p className="text-sm sm:text-base mb-9 max-w-xl mx-auto leading-7 text-primary-foreground/70">
              {t("desc")}
            </p>

            <div className="flex justify-center">
              <StoreButtons theme="light" />
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}
