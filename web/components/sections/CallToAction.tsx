"use client";

import { useTranslations } from "next-intl";
import StoreButtons from "@/components/ui/StoreButtons";
import { Badge } from "@/components/ui/badge";
import { appConfig } from "@/lib/config";

export default function CallToAction() {
  const t = useTranslations("cta");

  return (
    <section className="py-20 bg-bg">
      <div className="max-w-6xl mx-auto px-4 sm:px-6">
        <div
          className="relative rounded-3xl px-8 py-16 text-center overflow-hidden bg-gradient-to-br from-primary to-primary-hover"
        >
          {/* Decorative circles */}
          <div className="absolute -top-10 -right-10 w-48 h-48 rounded-full pointer-events-none bg-white/5" />
          <div className="absolute -bottom-14 left-8 w-36 h-36 rounded-full pointer-events-none bg-white/4" />

          <div className="relative">
            <Badge
              className="gap-2 px-4 py-1.5 rounded-full mb-6 border-0 text-xs font-semibold bg-white/15 text-white/85"
            >
              🚀 {t("badge")} {appConfig.name}
            </Badge>

            <h2 className="text-[28px] font-semibold text-white leading-[34px] tracking-tight mb-4">
              {t("heading")}
            </h2>
            <p className="text-sm mb-9 max-w-xs mx-auto leading-5 text-white/65">
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
