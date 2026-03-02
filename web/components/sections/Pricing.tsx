"use client";

import { useState } from "react";
import { useTranslations } from "next-intl";
import { Check } from "lucide-react";
import SectionLabel from "@/components/ui/SectionLabel";
import { Button as ShadcnButton } from "@/components/ui/Button";
import { Badge } from "@/components/ui/badge";
import { Card, CardContent } from "@/components/ui/card";
import { Input } from "@/components/ui/input";

export default function Pricing() {
  const t = useTranslations("pricing");
  const [email, setEmail] = useState("");
  const [submitted, setSubmitted] = useState(false);
  const freeFeatures = t.raw("free.features") as string[];
  const proFeatures = t.raw("pro.features") as string[];

  function handleNotify() {
    if (!email) return;
    setSubmitted(true);
  }

  return (
    <section id="pricing" className="section-shell bg-card">
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

        <div className="grid grid-cols-1 md:grid-cols-2 gap-6 sm:gap-7 max-w-4xl mx-auto">
          <Card className="bg-background rounded-3xl p-0 gap-0 ring-2 ring-success/28 border-0 shadow-sm">
            <CardContent className="p-7 sm:p-8 flex flex-col h-full">
              <Badge className="bg-success/10 text-success border-0 gap-1.5 mb-5 self-start">
                {t("free.badge")}
              </Badge>
              <div className="mb-2">
                <span className="text-[20px] font-semibold text-foreground leading-7">{t("free.title")}</span>
              </div>
              <p className="text-sm text-muted-foreground leading-6 mb-2">{t("free.desc")}</p>
              <p className="text-sm font-semibold text-foreground mb-7">{t("free.priceLine")}</p>
              <ul className="space-y-3.5 mb-8 flex-1">
                {freeFeatures.map((f) => (
                  <li key={f} className="flex items-start gap-2.5 text-sm text-muted-foreground">
                    <span className="text-success"><Check className="w-4 h-4 shrink-0 mt-0.5" /></span>
                    {f}
                  </li>
                ))}
              </ul>
              <ShadcnButton asChild size="lg" className="w-full justify-center focus-visible:ring-success/40">
                <a href="#download">{t("free.cta")}</a>
              </ShadcnButton>
              <p className="text-xs text-muted-foreground text-center mt-3">
                {t("free.microcopy")}
              </p>
            </CardContent>
          </Card>

          <Card
            className="rounded-3xl p-0 gap-0 border-0 shadow-sm relative overflow-hidden bg-gradient-to-br from-primary to-primary-hover"
          >
            <div className="absolute -top-8 -right-8 w-32 h-32 rounded-full bg-white/5" />
            <CardContent className="p-7 sm:p-8 relative flex flex-col h-full">
              <Badge
                className="border-0 gap-1.5 mb-5 self-start bg-warning/20 text-white"
              >
                {t("pro.badge")}
              </Badge>
              <div className="mb-2">
                <span className="text-[20px] font-semibold text-primary-foreground leading-7">{t("pro.title")}</span>
              </div>
              <p className="text-sm leading-6 mb-7 text-primary-foreground/70">
                {t("pro.desc")}
              </p>
              <ul className="space-y-3.5 mb-8 flex-1">
                {proFeatures.map((f) => (
                  <li key={f} className="flex items-start gap-2.5 text-sm text-primary-foreground/80">
                    <span className="text-primary-foreground/70"><Check className="w-4 h-4 shrink-0 mt-0.5" /></span>
                    {f}
                  </li>
                ))}
              </ul>

              {submitted ? (
                <div className="text-center py-3.5 text-sm font-semibold rounded-xl bg-success/20 text-primary-foreground">
                  {t("pro.notifyDone")}
                </div>
              ) : (
                <div className="flex flex-col sm:flex-row gap-2">
                  <Input
                    type="email"
                    placeholder={t("pro.notifyPlaceholder")}
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                    onKeyDown={(e) => e.key === "Enter" && handleNotify()}
                    className="flex-1 min-w-0 rounded-xl text-primary-foreground placeholder:text-primary-foreground/40 border-white/20 focus-visible:ring-white/30 h-auto py-2.5"
                  />
                  <ShadcnButton
                    onClick={handleNotify}
                    size="default"
                    className="bg-white text-primary hover:bg-white/90 shrink-0 rounded-xl sm:min-w-[132px] focus-visible:ring-warning/35"
                  >
                    {t("pro.notifyBtn")}
                  </ShadcnButton>
                </div>
              )}
            </CardContent>
          </Card>

        </div>
      </div>
    </section>
  );
}
