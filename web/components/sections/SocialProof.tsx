"use client";

import { useTranslations } from "next-intl";
import { Separator } from "@/components/ui/separator";

export default function SocialProof() {
  const t     = useTranslations("socialProof");
  const stats = t.raw("stats") as { value: string; label: string }[];

  return (
    <section className="py-10 bg-primary">
      <div className="max-w-6xl mx-auto px-4 sm:px-6">
        <div className="flex flex-col md:flex-row items-center justify-between gap-8">

          {/* Quote */}
          <blockquote className="text-white/90 text-sm italic text-center md:text-left max-w-xs">
            &ldquo;{t("quote")}&rdquo;
            <cite className="block not-italic text-white/50 text-xs mt-1.5 font-medium">
              — {t("attribution")}
            </cite>
          </blockquote>

          {/* Divider */}
          <Separator orientation="vertical" className="hidden md:block self-stretch h-10 w-px bg-white/15" />

          {/* Stats */}
          <div className="flex gap-10 md:gap-14">
            {stats.map(({ value, label }) => (
              <div key={label} className="text-center">
                <div className="text-[18px] font-semibold text-white leading-6">{value}</div>
                <div className="text-xs mt-0.5 leading-4 text-white/55">{label}</div>
              </div>
            ))}
          </div>

        </div>
      </div>
    </section>
  );
}
