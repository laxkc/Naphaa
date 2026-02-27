import { useTranslations } from "next-intl";
import { Bell, Package } from "lucide-react";
import StoreButtons from "@/components/ui/StoreButtons";
import { Badge } from "@/components/ui/badge";

function PhoneMockup() {
  const quickActions = [
    { label: "New Sale",  color: "#0b3954" },
    { label: "Expense",   color: "#c81d25" },
    { label: "Customers", color: "#ff5a5f" },
    { label: "Products",  color: "#087e8b" },
  ];

  const lowStockItems = [
    { name: "Rice (5kg)",  qty: "3" },
    { name: "Cooking Oil", qty: "2" },
  ];

  return (
    <div className="relative mx-auto w-[272px] select-none">
      {/* Glow behind phone */}
      <div className="absolute inset-0 -m-10 rounded-[70px] blur-3xl"
        style={{ background: "radial-gradient(ellipse, #0b395422 0%, transparent 70%)" }}
      />

      {/* Phone body */}
      <div className="relative rounded-[40px] p-[10px] shadow-2xl"
        style={{ background: "linear-gradient(145deg, #2a2a2a, #1a1a1a)" }}
      >
        {/* Dynamic island */}
        <div className="absolute top-3 left-1/2 -translate-x-1/2 w-24 h-5 rounded-full z-10"
          style={{ background: "#1a1a1a" }}
        />

        {/* Screen */}
        <div className="rounded-[32px] overflow-hidden bg-[#F9FAFB]" style={{ minHeight: 530 }}>

          {/* Status bar */}
          <div className="flex justify-between items-center px-5 pt-9 pb-1">
            <span className="text-[10px] font-semibold text-[#111827]">9:41</span>
            <div className="flex items-center gap-1">
              <div className="w-3 h-[7px] rounded-[2px] border border-[#6B7280] relative overflow-hidden">
                <div className="absolute inset-0.5 right-auto w-1/2 bg-[#16A34A] rounded-[1px]" />
              </div>
            </div>
          </div>

          <div className="px-3 pb-4">

            {/* Page header */}
            <div className="flex items-center justify-between mb-3 px-1">
              <span className="text-[13px] font-bold text-[#111827]">Dashboard</span>
              <div className="w-7 h-7 rounded-full bg-white flex items-center justify-center shadow-sm">
                <Bell className="w-[14px] h-[14px] text-[#111827]" strokeWidth={1.8} />
              </div>
            </div>

            {/* Hero card */}
            <div
              className="relative rounded-2xl overflow-hidden p-4 mb-3"
              style={{ background: "linear-gradient(135deg, #0b3954 0%, #082c42 100%)" }}
            >
              <div className="absolute -top-5 -right-5 w-20 h-20 rounded-full" style={{ background: "rgba(255,255,255,0.06)" }} />
              <div className="absolute -bottom-8 right-12 w-16 h-16 rounded-full" style={{ background: "rgba(255,255,255,0.04)" }} />

              <div className="relative">
                <div className="flex items-center justify-between mb-2">
                  <span className="text-[9px] font-semibold tracking-widest uppercase text-white/70">
                    Dashboard Overview
                  </span>
                  <span className="text-[9px] text-white/60 px-2 py-0.5 rounded-full" style={{ background: "rgba(255,255,255,0.15)" }}>
                    Today
                  </span>
                </div>
                <div className="text-[22px] font-semibold text-white tracking-tight leading-none mb-0.5">
                  Rs. 24,580
                </div>
                <div className="text-[9px] text-white/60 mb-3 flex items-center gap-1">
                  <span>↑</span> Today&apos;s Sales
                </div>
                <div className="h-px mb-3" style={{ background: "rgba(255,255,255,0.15)" }} />
                <div className="flex items-center">
                  <div className="flex-1">
                    <div className="text-[9px] text-white/60 mb-0.5">Expenses</div>
                    <div className="text-[11px] font-bold text-white">Rs. 3,200</div>
                  </div>
                  <div className="w-px h-7 mx-2" style={{ background: "rgba(255,255,255,0.2)" }} />
                  <div className="flex-1">
                    <div className="text-[9px] text-white/60 mb-0.5">Net Profit</div>
                    <div className="text-[11px] font-bold" style={{ color: "#087e8b" }}>Rs. 21,380</div>
                  </div>
                </div>
              </div>
            </div>

            {/* Quick actions */}
            <div className="grid grid-cols-4 gap-1.5 mb-3">
              {quickActions.map(({ label, color }) => (
                <div
                  key={label}
                  className="rounded-xl flex flex-col items-center py-2.5 gap-1.5"
                  style={{ background: `${color}14` }}
                >
                  <div
                    className="w-7 h-7 rounded-full flex items-center justify-center"
                    style={{ background: `${color}2E` }}
                  >
                    <div className="w-2 h-2 rounded-sm" style={{ background: color }} />
                  </div>
                  <span className="text-[7.5px] font-semibold text-center leading-tight" style={{ color: "#374151" }}>
                    {label}
                  </span>
                </div>
              ))}
            </div>

            {/* Low stock card */}
            <div className="bg-white rounded-xl p-3 shadow-sm">
              <div className="flex items-center gap-1.5 mb-2.5">
                <Package className="w-3 h-3 shrink-0" stroke="#F59E0B" strokeWidth={2} />
                <span className="text-[9px] font-semibold text-[#111827]">Low Stock</span>
              </div>
              {lowStockItems.map(({ name, qty }) => (
                <div key={name} className="flex items-center justify-between mb-1.5 last:mb-0">
                  <div className="flex items-center gap-1.5">
                    <div className="w-1.5 h-1.5 rounded-full bg-[#F59E0B]" />
                    <span className="text-[9px] text-[#111827]">{name}</span>
                  </div>
                  <span
                    className="text-[8px] font-semibold px-1.5 py-0.5 rounded-full"
                    style={{ background: "#FFFBEB", color: "#F59E0B" }}
                  >
                    {qty} left
                  </span>
                </div>
              ))}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

export default function Hero() {
  const t = useTranslations("hero");
  const trustItems = [t("trust1"), t("trust2"), t("trust3")];

  return (
    <section className="bg-bg page-enter">
      <div className="max-w-6xl mx-auto px-4 sm:px-6 py-16 lg:py-20 w-full">
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-12 lg:gap-16 items-center">

          {/* Left: copy */}
          <div>
            <Badge className="gap-2 rounded-full px-3.5 py-1.5 mb-6 bg-primary/10 text-primary border-0 text-xs font-semibold">
              <span>🇳🇵</span>
              <span>{t("badge")}</span>
            </Badge>

            <p className="text-xs font-bold uppercase tracking-[0.18em] text-primary mb-3">
              {t("h1Brand")}
            </p>
            <h1 className="text-[32px] leading-[40px] font-bold text-label tracking-tight mb-5">
              {t("h1Tagline")}
            </h1>

            <p className="text-sm text-muted leading-5 mb-8 max-w-md">
              {t("desc")}
            </p>

            <div className="flex flex-col sm:flex-row gap-3 mb-9">
              <a
                href="#how-it-works"
                className="inline-flex items-center justify-center px-6 py-2.5 text-sm font-medium text-primary border border-border rounded-md hover:bg-hover-overlay transition-colors"
              >
                {t("cta2")}
              </a>
            </div>

            <div className="flex flex-wrap gap-x-6 gap-y-2 mb-8">
              {trustItems.map((item) => (
                <span key={item} className="text-sm text-muted font-medium">{item}</span>
              ))}
            </div>

            <div>
              <p className="text-xs font-semibold uppercase tracking-wider text-muted mb-3">
                {t("download")}
              </p>
              <StoreButtons theme="dark" />
            </div>
          </div>

          {/* Right: phone mockup */}
          <div className="hidden lg:flex justify-center lg:justify-end">
            <PhoneMockup />
          </div>

        </div>
      </div>
    </section>
  );
}
