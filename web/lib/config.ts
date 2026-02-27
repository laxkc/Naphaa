export const appConfig = {
  name:        process.env.NEXT_PUBLIC_APP_NAME        ?? "Naphaa",
  description: process.env.NEXT_PUBLIC_APP_DESCRIPTION ?? "Digital Ledger for Small Businesses",
  url:         process.env.NEXT_PUBLIC_APP_URL          ?? "https://smedigital.app",
} as const;
