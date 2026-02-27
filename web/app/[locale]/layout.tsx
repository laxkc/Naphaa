import type { Metadata } from "next";
import { Inter } from "next/font/google";
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

export const metadata: Metadata = {
  title:       `${appConfig.name} — ${appConfig.description}`,
  description: "Record sales in seconds. Track customer credit. Know your profit — even when offline.",
  openGraph: {
    title:       `${appConfig.name} — ${appConfig.description}`,
    description: "Record sales in seconds. Track customer credit. Know your profit — even when offline.",
    type:        "website",
    siteName:    appConfig.name,
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
      <body className={`${inter.variable} antialiased h-full flex flex-col overflow-hidden`}>
        <NextIntlClientProvider messages={messages}>

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
