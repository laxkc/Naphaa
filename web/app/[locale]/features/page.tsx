import { useTranslations } from "next-intl";
import SectionLabel from "@/components/ui/SectionLabel";
import Features from "@/components/sections/Features";
import Outcomes from "@/components/sections/Outcomes";
import Trust from "@/components/sections/Trust";

export default function FeaturesPage() {
  const t = useTranslations("featuresPage");

  return (
    <div className="bg-surface page-enter">
      <section className="page-intro">
        <div className="page-intro-inner">
          <div className="page-intro-content">
            <SectionLabel>{t("label")}</SectionLabel>
            <h1 className="section-title">
              {t("heading")}
            </h1>
            <p className="section-copy mt-4 max-w-2xl">
              {t("desc")}
            </p>
          </div>
        </div>
      </section>

      <Features />
      <Outcomes />
      <Trust />
    </div>
  );
}
