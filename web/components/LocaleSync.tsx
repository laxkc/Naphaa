"use client";

import { useEffect } from "react";
import { useRouter, usePathname } from "next/navigation";

const VALID_LOCALES = ["en", "ne"] as const;
const KEY = "sme_locale";

/**
 * Runs once on mount. If the user has a saved locale preference that
 * differs from the current URL locale, silently redirects to the
 * preferred locale while keeping the same path.
 */
export default function LocaleSync({ locale }: { locale: string }) {
  const router   = useRouter();
  const pathname = usePathname();

  useEffect(() => {
    const saved = localStorage.getItem(KEY) as string | null;

    if (saved && VALID_LOCALES.includes(saved as (typeof VALID_LOCALES)[number]) && saved !== locale) {
      const newPath = pathname.replace(
        new RegExp(`^/${locale}(/|$)`),
        `/${saved}$1`,
      );
      router.replace(newPath);
    }
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  return null;
}

/** Call this whenever the user explicitly picks a locale. */
export function saveLocale(locale: string) {
  localStorage.setItem(KEY, locale);
}
