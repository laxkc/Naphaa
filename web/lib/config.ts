export const appConfig = {
  name:        process.env.NEXT_PUBLIC_APP_NAME        ?? "Naphaa",
  description: process.env.NEXT_PUBLIC_APP_DESCRIPTION ?? "Digital Ledger for Nepal Shops",
  url:         process.env.NEXT_PUBLIC_APP_URL          ?? "https://naphaa.com",
} as const;
