"use client";

import { useState } from "react";
import { Check } from "lucide-react";
import SectionLabel from "@/components/ui/SectionLabel";
import { Button as ShadcnButton } from "@/components/ui/Button";
import { Badge } from "@/components/ui/badge";
import { Card, CardContent } from "@/components/ui/card";
import { Input } from "@/components/ui/input";

const freeFeatures = [
  "Unlimited cash & credit sales",
  "Up to 100 products",
  "Customer credit tracking",
  "Basic reports — sales & credit",
  "Offline-first local storage",
  "Nepali & English support",
];

const proFeatures = [
  "Everything in Free",
  "Cloud sync — multi-device",
  "PDF invoice generation",
  "Advanced analytics & exports",
  "Unlimited products",
  "Priority support",
];

export default function Pricing() {
  const [email, setEmail] = useState("");
  const [submitted, setSubmitted] = useState(false);

  function handleNotify() {
    if (!email) return;
    setSubmitted(true);
  }

  return (
    <section id="pricing" className="py-20 bg-surface">
      <div className="max-w-6xl mx-auto px-4 sm:px-6">

        {/* Header */}
        <div className="text-center mb-14">
          <SectionLabel>Pricing</SectionLabel>
          <h2 className="text-[22px] font-semibold text-label leading-[28px] tracking-tight">
            Simple pricing. Start free.
          </h2>
          <p className="text-muted mt-3 max-w-xs mx-auto">
            No credit card required. Upgrade whenever you&apos;re ready.
          </p>
        </div>

        {/* Cards */}
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6 max-w-3xl mx-auto">

          {/* Free card */}
          <Card className="bg-bg rounded-2xl p-0 gap-0 ring-2 ring-primary/25 border-0 shadow-none">
            <CardContent className="p-7 flex flex-col h-full">
              <Badge className="bg-primary/10 text-primary border-0 gap-1.5 mb-5 self-start">
                ✓ Most popular
              </Badge>
              <div className="mb-1">
                <span className="text-[18px] font-semibold text-label leading-6">Rs. 0</span>
                <span className="text-muted text-sm ml-1">/ month</span>
              </div>
              <p className="text-sm text-muted mb-6">Access core features at no cost, forever.</p>
              <ul className="space-y-3 mb-8 flex-1">
                {freeFeatures.map((f) => (
                  <li key={f} className="flex items-start gap-2.5 text-sm text-label-sub">
                    <span className="text-primary"><Check className="w-4 h-4 shrink-0 mt-0.5" /></span>
                    {f}
                  </li>
                ))}
              </ul>
              <ShadcnButton asChild size="lg" className="w-full justify-center">
                <a href="#download">Download Free</a>
              </ShadcnButton>
            </CardContent>
          </Card>

          {/* Pro card */}
          <Card
            className="rounded-2xl p-0 gap-0 border-0 shadow-none relative overflow-hidden bg-gradient-to-br from-primary to-primary-hover"
          >
            <div className="absolute -top-8 -right-8 w-32 h-32 rounded-full bg-white/5" />
            <CardContent className="p-7 relative flex flex-col h-full">
              <Badge
                className="border-0 gap-1.5 mb-5 self-start bg-white/15 text-white/90"
              >
                🚀 Coming Soon
              </Badge>
              <div className="mb-1">
                <span className="text-[18px] font-semibold text-white leading-6">Pro</span>
              </div>
              <p className="text-sm mb-6 text-white/65">
                Advanced features for growing businesses.
              </p>
              <ul className="space-y-3 mb-8 flex-1">
                {proFeatures.map((f) => (
                  <li key={f} className="flex items-start gap-2.5 text-sm text-white/80">
                    <span className="text-white/70"><Check className="w-4 h-4 shrink-0 mt-0.5" /></span>
                    {f}
                  </li>
                ))}
              </ul>

              {submitted ? (
                <div className="text-center py-3.5 text-sm font-semibold rounded-xl bg-white/15 text-white/90">
                  ✓ We&apos;ll notify you at launch!
                </div>
              ) : (
                <div className="flex gap-2">
                  <Input
                    type="email"
                    placeholder="your@email.com"
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                    onKeyDown={(e) => e.key === "Enter" && handleNotify()}
                    className="flex-1 min-w-0 rounded-xl text-white placeholder:text-white/40 border-white/20 focus-visible:ring-white/30 h-auto py-2.5"
                  />
                  <ShadcnButton
                    onClick={handleNotify}
                    size="default"
                    className="bg-white text-primary hover:bg-white/90 shrink-0 rounded-xl"
                  >
                    Notify me
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
