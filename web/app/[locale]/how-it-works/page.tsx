import { useTranslations } from "next-intl";
import SectionLabel from "@/components/ui/SectionLabel";
import { Badge } from "@/components/ui/badge";

const stepKeys = ["one", "two", "three"] as const;

function HowItWorksContent() {
  const t = useTranslations("howItWorks");

  return (
    <div className="h-full flex flex-col justify-center bg-bg page-enter">
      <div className="max-w-6xl mx-auto px-4 sm:px-6 py-10 w-full">

        <div className="text-center mb-12">
          <SectionLabel>{t("label")}</SectionLabel>
          <h1 className="text-[22px] font-semibold text-label leading-[28px] tracking-tight">
            {t("heading")}
          </h1>
          <p className="text-sm text-muted mt-2 max-w-xs mx-auto leading-5">{t("subtext")}</p>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-3 gap-6 relative">

          {/* Desktop connector line */}
          <div className="hidden md:block absolute top-10 left-[calc(16.67%+1rem)] right-[calc(16.67%+1rem)] h-px bg-border z-0" />

          {stepKeys.map((key) => (
            <div key={key} className="relative flex flex-col items-center text-center md:items-start md:text-left">

              <div className="relative z-10 w-20 h-20 rounded-2xl bg-surface border border-border shadow-sm flex items-center justify-center mb-5 shrink-0">
                <span className="text-[22px] font-semibold text-primary">{t(`steps.${key}.number`)}</span>
              </div>

              <h3 className="text-base font-semibold text-label leading-[22px] mb-2">{t(`steps.${key}.title`)}</h3>
              <p className="text-sm text-muted leading-5 mb-3">{t(`steps.${key}.desc`)}</p>

              <Badge className="border-0 rounded-full px-3 py-1 text-xs font-medium bg-primary/8 text-primary mb-2">
                {t(`steps.${key}.tag`)}
              </Badge>

              <span className="text-xs text-muted italic">{t(`steps.${key}.detail`)}</span>
            </div>
          ))}

        </div>
      </div>
    </div>
  );
}

export default function HowItWorksPage() {
  return <HowItWorksContent />;
}
