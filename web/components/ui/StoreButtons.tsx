interface StoreButtonsProps {
  /** Pass a light variant when rendering on a dark background */
  theme?: "dark" | "light";
  playStoreUrl?: string;
  appStoreUrl?: string;
}

const GooglePlayIcon = () => (
  <svg width="20" height="20" viewBox="0 0 24 24" fill="none">
    <path
      d="M3.18 1.02C2.74 1.27 2.46 1.76 2.46 2.35v19.3c0 .59.28 1.08.72 1.33l.1.06 10.82-10.82v-.26L3.28.96l-.1.06Z"
      fill="url(#gp_a)"
    />
    <path
      d="m17.56 15.6-3.6-3.6v-.27l3.6-3.6.08.05 4.27 2.43c1.22.69 1.22 1.82 0 2.51l-4.27 2.43-.08.05Z"
      fill="url(#gp_b)"
    />
    <path
      d="m17.64 15.55-3.68-3.68L3.18 22.65c.4.43 1.07.48 1.82.05l12.64-7.15"
      fill="url(#gp_c)"
    />
    <path
      d="M17.64 8.45 5 1.3C4.25.87 3.58.92 3.18 1.35l10.78 10.78 3.68-3.68Z"
      fill="url(#gp_d)"
    />
    <defs>
      <linearGradient id="gp_a" x1="12.37" y1="2.28" x2="-2.77" y2="12" gradientUnits="userSpaceOnUse">
        <stop stopColor="#00A0FF" />
        <stop offset="1" stopColor="#00A0FF" stopOpacity="0" />
      </linearGradient>
      <linearGradient id="gp_b" x1="23.37" y1="12" x2="2.11" y2="12" gradientUnits="userSpaceOnUse">
        <stop stopColor="#FFD800" />
        <stop offset="1" stopColor="#FF8A00" />
      </linearGradient>
      <linearGradient id="gp_c" x1="14.41" y1="13.59" x2="0.44" y2="27.56" gradientUnits="userSpaceOnUse">
        <stop stopColor="#FF3A44" />
        <stop offset="1" stopColor="#C31162" />
      </linearGradient>
      <linearGradient id="gp_d" x1="0.71" y1="-3.52" x2="7.58" y2="3.35" gradientUnits="userSpaceOnUse">
        <stop stopColor="#32A071" />
        <stop offset="1" stopColor="#2DA771" stopOpacity="0" />
      </linearGradient>
    </defs>
  </svg>
);

const AppleIcon = ({ white }: { white?: boolean }) => (
  <svg width="18" height="22" viewBox="0 0 814 1000" fill={white ? "white" : "black"}>
    <path d="M788.1 340.9c-5.8 4.5-108.2 62.2-108.2 190.5 0 148.4 130.3 200.9 134.2 202.2-.6 3.2-20.7 71.9-68.7 141.9-42.8 61.6-87.5 123.1-155.5 123.1s-85.5-39.5-164-39.5c-76 0-103.7 40.8-165.9 40.8s-105-57.8-155.5-127.4C46 790.7 0 663 0 541.8c0-207.5 135.4-317.3 269-317.3 70.1 0 128.4 46.4 172.5 46.4 42.8 0 109.6-49.1 190.5-49.1zm-23.5-181.1c31.1-36.9 53.1-88.1 53.1-139.3 0-7.1-.6-14.3-1.9-20.1-50.6 1.9-110.8 33.7-147.1 75.8-28.5 32.4-55.1 83.6-55.1 135.5 0 7.8 1.3 15.6 1.9 18.1 3.2.6 8.4 1.3 13.6 1.3 45.4 0 102.5-30.4 135.5-71.3z" />
  </svg>
);

export default function StoreButtons({
  theme = "dark",
  playStoreUrl = "#",
  appStoreUrl = "#",
}: StoreButtonsProps) {
  const isDark = theme === "dark";

  const baseClass =
    "inline-flex items-center gap-3 px-5 py-3 rounded-2xl transition-all duration-150 active:scale-[0.97] select-none";

  const darkClass = "bg-[#0a0a0a] hover:bg-[#1a1a1a] border border-white/10";
  const lightClass = "bg-white/15 hover:bg-white/25 border border-white/20";

  const btnClass = `${baseClass} ${isDark ? darkClass : lightClass}`;

  const labelColor  = isDark ? "text-white/55" : "text-white/60";
  const storeColor  = isDark ? "text-white"    : "text-white";

  return (
    <div className="flex flex-wrap gap-3">

      {/* Google Play */}
      <a href={playStoreUrl} className={btnClass} aria-label="Get it on Google Play">
        <GooglePlayIcon />
        <div className="leading-tight">
          <div className={`text-[10px] font-medium ${labelColor}`}>Get it on</div>
          <div className={`text-sm font-semibold tracking-tight ${storeColor}`}>Google Play</div>
        </div>
      </a>

      {/* App Store */}
      <a href={appStoreUrl} className={btnClass} aria-label="Download on the App Store">
        <AppleIcon white={isDark} />
        <div className="leading-tight">
          <div className={`text-[10px] font-medium ${labelColor}`}>Download on the</div>
          <div className={`text-sm font-semibold tracking-tight ${storeColor}`}>App Store</div>
        </div>
      </a>

    </div>
  );
}
