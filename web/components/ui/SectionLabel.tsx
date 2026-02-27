export default function SectionLabel({ children }: { children: React.ReactNode }) {
  return (
    <span className="inline-block text-xs font-semibold tracking-[0.14em] uppercase text-primary mb-3">
      {children}
    </span>
  );
}
