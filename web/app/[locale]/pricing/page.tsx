"use client";

import { useState } from "react";
import { useTranslations } from "next-intl";
import { Check } from "lucide-react";
import SectionLabel from "@/components/ui/SectionLabel";
import { Button as ShadcnButton } from "@/components/ui/Button";
import { Badge } from "@/components/ui/badge";
import { Card, CardContent } from "@/components/ui/card";
import { Input } from "@/components/ui/input";

export default function PricingPage() {
  const t            = useTranslations("pricing");
  const [email,     setEmail]     = useState("");
  const [submitted, setSubmitted] = useState(false);

  const freeFeatures = t.raw("free.features") as string[];
  const proFeatures  = t.raw("pro.features")  as string[];

  return (
    <div className="h-full flex flex-col justify-center bg-surface page-enter">
      <div className="max-w-5xl mx-auto px-4 sm:px-6 py-10 w-full">

        <div className="text-center mb-8">
          <SectionLabel>{t("label")}</SectionLabel>
          <h1 className="text-[22px] font-semibold text-label leading-[28px] tracking-tight">
            {t("heading")}
          </h1>
          <p className="text-muted mt-2 text-sm max-w-xs mx-auto">
            {t("subtext")}
          </p>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-5 max-w-3xl mx-auto">

          {/* Free card */}
          <Card className="bg-bg rounded-2xl p-0 gap-0 ring-2 ring-primary/25 border-0 shadow-none">
            <CardContent className="p-6 flex flex-col h-full">
              <Badge className="bg-primary/10 text-primary border-0 gap-1.5 mb-4 self-start">
                {t("free.badge")}
              </Badge>
              <div className="mb-1">
                <span className="text-[18px] font-semibold text-label leading-6">{t("free.price")}</span>
                <span className="text-muted text-sm ml-1">{t("free.period")}</span>
              </div>
              <p className="text-xs text-muted mb-5">{t("free.desc")}</p>
              <ul className="space-y-2 mb-6 flex-1">
                {freeFeatures.map((f) => (
                  <li key={f} className="flex items-start gap-2 text-sm text-label-sub">
                    <span className="text-primary"><Check className="w-4 h-4 shrink-0 mt-0.5" /></span>{f}
                  </li>
                ))}
              </ul>
              <ShadcnButton asChild size="default" className="w-full justify-center">
                <a href="#download">{t("free.cta")}</a>
              </ShadcnButton>
            </CardContent>
          </Card>

          {/* Pro card */}
          <Card
            className="rounded-2xl p-0 gap-0 border-0 shadow-none relative overflow-hidden bg-gradient-to-br from-primary to-primary-hover"
          >
            <div className="absolute -top-6 -right-6 w-28 h-28 rounded-full bg-white/5" />
            <CardContent className="p-6 relative flex flex-col h-full">
              <Badge
                className="border-0 gap-1.5 mb-4 self-start bg-white/15 text-white/90"
              >
                {t("pro.badge")}
              </Badge>
              <div className="mb-1">
                <span className="text-[18px] font-semibold text-white leading-6">{t("pro.title")}</span>
              </div>
              <p className="text-xs mb-5 text-white/60">
                {t("pro.desc")}
              </p>
              <ul className="space-y-2 mb-6 flex-1">
                {proFeatures.map((f) => (
                  <li key={f} className="flex items-start gap-2 text-sm text-white/80">
                    <span className="text-white/90"><Check className="w-4 h-4 shrink-0 mt-0.5" /></span>{f}
                  </li>
                ))}
              </ul>
              {submitted ? (
                <div className="text-center py-3 text-sm font-semibold rounded-xl bg-white/15 text-white/90">
                  {t("pro.notifyDone")}
                </div>
              ) : (
                <div className="flex gap-2">
                  <Input
                    type="email"
                    placeholder={t("pro.notifyPlaceholder")}
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                    onKeyDown={(e) => e.key === "Enter" && email && setSubmitted(true)}
                    className="flex-1 min-w-0 rounded-xl text-white placeholder:text-white/40 border-white/20 focus-visible:ring-white/30 h-auto py-2.5"
                  />
                  <ShadcnButton
                    onClick={() => { if (email) setSubmitted(true); }}
                    className="bg-white text-primary hover:bg-white/90 shrink-0 rounded-xl"
                  >
                    {t("pro.notifyBtn")}
                  </ShadcnButton>
                </div>
              )}
            </CardContent>
          </Card>
        </div>

      </div>
    </div>
  );
}
