import type { Metadata } from "next";
import { Inter, Noto_Sans_Devanagari } from "next/font/google";
import { NextIntlClientProvider } from "next-intl";
import { getMessages } from "next-intl/server";
import { notFound } from "next/navigation";
import { routing } from "@/i18n/routing";
import "../globals.css";
import Navbar from "@/components/layout/Navbar";
import Footer from "@/components/layout/Footer";
import LocaleSync from "@/components/LocaleSync";
import { appConfig } from "@/lib/config";

const inter = Inter({
  variable: "--font-inter",
  subsets:  ["latin"],
  display:  "swap",
});

const notoDevanagari = Noto_Sans_Devanagari({
  variable: "--font-nepali",
  subsets:  ["devanagari"],
  display:  "swap",
});

export const metadata: Metadata = {
  title:       `${appConfig.name}`,
  description: "Know your shop, control your profit, and run with confidence. Naphaa helps Nepali shop owners track sales, stock, and customer dues from one simple app.",
  keywords:    ["Nepal shops", "profit tracker", "sales tracker", "stock tracking", "customer dues", "small business Nepal", "Naphaa"],
  metadataBase: new URL(appConfig.url),
  openGraph: {
    title:       `${appConfig.name} - The Most Reliable Business System for Nepal Shops`,
    description: "Know your shop, control your profit, and run with confidence with one simple app built for Nepali shop owners.",
    type:        "website",
    siteName:    appConfig.name,
    url:         appConfig.url,
    locale:      "en_US",
  },
  twitter: {
    card:        "summary_large_image",
    title:       `${appConfig.name} - The Most Reliable Business System for Nepal Shops`,
    description: "Know your shop, control your profit, and run with confidence with one simple app built for Nepali shop owners.",
  },
  alternates: {
    canonical: appConfig.url,
  },
};

export function generateStaticParams() {
  return routing.locales.map((locale) => ({ locale }));
}

export default async function LocaleLayout({
  children,
  params,
}: {
  children: React.ReactNode;
  params: Promise<{ locale: string }>;
}) {
  const { locale } = await params;

  if (!routing.locales.includes(locale as "en" | "ne")) {
    notFound();
  }

  const messages = await getMessages();

  return (
    <html lang={locale} className="h-full">
      <body className={`${inter.variable} ${notoDevanagari.variable} font-sans antialiased min-h-full flex flex-col`}>        <NextIntlClientProvider messages={messages}>

          <LocaleSync locale={locale} />
          <Navbar />

          <main className="flex-1">
            {children}
            <Footer />
          </main>

        </NextIntlClientProvider>
      </body>
    </html>
  );
}
