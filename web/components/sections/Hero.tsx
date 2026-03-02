import { useTranslations, useLocale } from "next-intl";
import Image from "next/image";
import { Badge } from "@/components/ui/badge";

function PhoneMockup() {
  const locale = useLocale();
  const src = locale === "ne" ? "/screenshots/mobile-np.png" : "/screenshots/mobile-en.png";
  const alt = locale === "ne" ? "Naphaa App – नेपाली" : "Naphaa App – English";

  return (
    <div className="relative flex items-center justify-center py-10">
      <div className="absolute w-[340px] h-[520px] bg-primary/10 rounded-full blur-3xl pointer-events-none" />
      <div
        className="relative rounded-[44px] overflow-hidden"
        style={{
          boxShadow:
            "0 0 0 1px rgba(0,0,0,0.08), 0 24px 64px -12px rgba(0,0,0,0.28), 0 8px 24px -6px rgba(0,0,0,0.16)",
          width: 285,
        }}
      >
        <Image
          src={src}
          alt={alt}
          width={300}
          height={600}
          className="w-full h-auto block"
          priority
        />
      </div>
    </div>
  );
}

export default function Hero() {
  const t = useTranslations("hero");

  return (
    <section className="relative bg-background overflow-hidden page-enter">
      <div className="absolute top-0 right-0 w-[500px] h-[500px] bg-primary/5 rounded-full blur-3xl pointer-events-none -translate-y-1/2 translate-x-1/4" />
      <div className="absolute left-0 bottom-0 w-[360px] h-[360px] bg-accent/6 rounded-full blur-3xl pointer-events-none translate-y-1/3 -translate-x-1/4" />

      <div className="relative section-container py-16 sm:py-20 lg:py-28">
        <div className="grid grid-cols-1 lg:grid-cols-[1.05fr_0.95fr] gap-14 lg:gap-18 items-center">
          <div className="flex flex-col">
            <Badge className="gap-2 rounded-full px-4 py-1.5 mb-6 sm:mb-7 bg-primary/10 text-primary border-0 text-xs font-semibold self-start">
              <span>🇳🇵</span>
              <span>{t("badge")}</span>
            </Badge>

            <h1 className="text-[42px] sm:text-[54px] lg:text-[62px] leading-[0.98] font-bold text-foreground tracking-tight mb-5 sm:mb-6 max-w-2xl">
              {t("h1Tagline")}
            </h1>

            <p className="text-base sm:text-lg text-muted-foreground leading-8 mb-8 sm:mb-9 max-w-xl">
              {t("desc")}
            </p>

            <div className="flex flex-col sm:flex-row items-start gap-3 mb-6">
              <a
                href="#download"
                className="inline-flex items-center justify-center rounded-xl bg-primary text-primary-foreground text-sm font-semibold px-6 py-3.5 hover:bg-primary/90 transition-colors min-w-[196px]"
              >
                {t("cta1")}
              </a>
              <a
                href="#demo"
                className="inline-flex items-center justify-center rounded-xl border border-border bg-white/60 text-sm font-medium text-foreground px-6 py-3.5 hover:bg-card transition-colors min-w-[196px]"
              >
                {t("cta2")}
              </a>
            </div>

            <div className="mb-8 sm:mb-10 flex flex-wrap gap-2.5">
              <span className="inline-flex items-center rounded-full bg-success/10 text-success px-3 py-1.5 text-xs sm:text-sm font-medium">
                ✓ Free forever
              </span>
              <span className="inline-flex items-center rounded-full bg-warning/10 text-warning px-3 py-1.5 text-xs sm:text-sm font-medium">
                ✓ Works offline
              </span>
              <span className="inline-flex items-center rounded-full bg-primary/10 text-primary px-3 py-1.5 text-xs sm:text-sm font-medium">
                ✓ Nepali & English
              </span>
            </div>

            <div className="grid grid-cols-1 sm:grid-cols-3 gap-3 sm:gap-4 max-w-3xl">
              <div className="surface-panel px-4 py-4 sm:px-5 sm:py-5 ring-1 ring-primary/12">
                <div className="text-xs uppercase tracking-[0.14em] text-primary font-semibold mb-1">
                  {t("focusLabel")}
                </div>
                <p className="text-sm text-foreground leading-6">{t("focusText")}</p>
              </div>
              <div className="surface-panel px-4 py-4 sm:px-5 sm:py-5 ring-1 ring-accent/16">
                <div className="text-xs uppercase tracking-[0.14em] text-accent font-semibold mb-1">
                  {t("simpleLabel")}
                </div>
                <p className="text-sm text-foreground leading-6">{t("simpleText")}</p>
              </div>
              <div className="surface-panel px-4 py-4 sm:px-5 sm:py-5 ring-1 ring-success/18">
                <div className="text-xs uppercase tracking-[0.14em] text-success font-semibold mb-1">
                  {t("offlineLabel")}
                </div>
                <p className="text-sm text-foreground leading-6">{t("offlineText")}</p>
              </div>
            </div>
          </div>

          <div className="hidden lg:flex justify-center items-end">
            <PhoneMockup />
          </div>
        </div>
      </div>
    </section>
  );
}
