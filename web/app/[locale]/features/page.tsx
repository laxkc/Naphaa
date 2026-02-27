import { useTranslations } from "next-intl";
import SectionLabel from "@/components/ui/SectionLabel";
import { Card, CardContent } from "@/components/ui/card";

const featureKeys = ["sales", "inventory", "credit", "reports", "offline", "invoices"] as const;
const featureMeta: Record<typeof featureKeys[number], { emoji: string; iconTintClass: string }> = {
  sales:     { emoji: "⚡", iconTintClass: "bg-primary/10" },
  inventory: { emoji: "📦", iconTintClass: "bg-accent/10" },
  credit:    { emoji: "👥", iconTintClass: "bg-primary-hover/10" },
  reports:   { emoji: "📊", iconTintClass: "bg-primary/10" },
  offline:   { emoji: "🔌", iconTintClass: "bg-success/10" },
  invoices:  { emoji: "🧾", iconTintClass: "bg-accent/10" },
};

function FeaturesContent() {
  const t = useTranslations("features");

  return (
    <div className="h-full flex flex-col justify-center bg-surface page-enter">
      <div className="max-w-6xl mx-auto px-4 sm:px-6 py-10 w-full">

        <div className="text-center mb-8">
          <SectionLabel>{t("label")}</SectionLabel>
          <h1 className="text-[22px] font-semibold text-label leading-[28px] tracking-tight">
            {t("heading")}
            <span className="text-muted font-normal"> {t("subheading")}</span>
          </h1>
        </div>

        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
          {featureKeys.map((key) => {
            const { emoji, iconTintClass } = featureMeta[key];
            return (
              <Card
                key={key}
                className="bg-bg rounded-2xl p-0 gap-0 border-0 shadow-none hover:shadow-md transition-all duration-200"
              >
                <CardContent className="p-5 flex gap-4 items-start">
                  <div className={`w-10 h-10 rounded-xl flex items-center justify-center text-lg shrink-0 ${iconTintClass}`}>
                    {emoji}
                  </div>
                  <div>
                    <h3 className="text-base font-semibold text-label leading-[22px] mb-1">
                      {t(`items.${key}.title`)}
                    </h3>
                    <p className="text-sm text-muted leading-5">
                      {t(`items.${key}.desc`)}
                    </p>
                  </div>
                </CardContent>
              </Card>
            );
          })}
        </div>

      </div>
    </div>
  );
}

export default function FeaturesPage() {
  return <FeaturesContent />;
}
