"use client";

import { useTranslations } from "next-intl";
import SectionLabel from "@/components/ui/SectionLabel";
import Pricing from "@/components/sections/Pricing";
import FAQ from "@/components/sections/FAQ";
import CallToAction from "@/components/sections/CallToAction";

export default function PricingPage() {
  const t = useTranslations("pricingPage");

  return (
    <div className="bg-surface page-enter">
      <section className="page-intro">
        <div className="page-intro-inner">
          <div className="page-intro-content mx-auto md:mx-0 text-center md:text-left">
            <SectionLabel>{t("label")}</SectionLabel>
            <h1 className="section-title">
              {t("heading")}
            </h1>
            <p className="section-copy mt-4 max-w-2xl mx-auto md:mx-0">
              {t("desc")}
            </p>
          </div>
        </div>
      </section>

      <Pricing />
      <FAQ />
      <CallToAction />
    </div>
  );
}
