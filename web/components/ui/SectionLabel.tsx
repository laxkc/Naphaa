export default function SectionLabel({ children }: { children: React.ReactNode }) {
  return (
    <span className="inline-block text-[11px] sm:text-xs font-semibold tracking-[0.18em] uppercase text-primary mb-3 sm:mb-4">
      {children}
    </span>
  );
}
