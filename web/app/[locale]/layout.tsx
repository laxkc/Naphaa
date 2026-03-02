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
  description: "Record sales in seconds. Track who owes you money. Know your profit — even when the internet is out. Free digital ledger for small shops in Nepal.",
  keywords:    ["digital ledger", "Nepal shops", "sales tracker", "credit ledger", "offline POS", "small business Nepal", "Naphaa"],
  metadataBase: new URL(appConfig.url),
  openGraph: {
    title:       `${appConfig.name} - The Most Reliable Business System for Nepal Shops`,
    description: "Record sales in seconds. Track who owes you money. Know your profit — even when the internet is out.",
    type:        "website",
    siteName:    appConfig.name,
    url:         appConfig.url,
    locale:      "en_US",
  },
  twitter: {
    card:        "summary_large_image",
    title:       `${appConfig.name} - The Most Reliable Business System for Nepal Shops`,
    description: "Record sales in seconds. Track who owes you money. Know your profit — even when the internet is out.",
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
      <body className={`${inter.variable} ${notoDevanagari.variable} font-sans antialiased h-full flex flex-col overflow-hidden`}>        <NextIntlClientProvider messages={messages}>

          <LocaleSync locale={locale} />
          <Navbar />

          <main className="flex-1 overflow-y-auto">
            {children}
            <Footer />
          </main>

        </NextIntlClientProvider>
      </body>
    </html>
  );
}
