import type { Metadata, Viewport } from "next";
import { Providers } from "../context/Providers"
import { NavBars } from "../components/NavBars";
import { PWAInstallPrompt } from "../components/PWAInstallPrompt";
import "./globals.css";
import { Inter } from 'next/font/google'

const inter = Inter({ subsets: ['latin'] })

export const metadata: Metadata = {
  title: "Powers Protocol",
  description: "UI to interact with organisations using the Powers Protocol.",
  manifest: "/manifest.json",
  appleWebApp: {
    capable: true,
    statusBarStyle: "default",
    title: "Powers Protocol",
  },
  icons: {
    icon: "/icon-192x192.png",
    apple: "/icon-192x192.png",
  },
};

export const viewport: Viewport = {
  themeColor: "#475569",
  width: "device-width",
  initialScale: 1,
  maximumScale: 1,
  userScalable: false,
};

export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {

  return (
    <html lang="en">
      <head>
        <meta name="mobile-web-app-capable" content="yes" />
        <meta name="apple-mobile-web-app-capable" content="yes" />
        <meta name="apple-mobile-web-app-status-bar-style" content="default" />
        <meta name="apple-mobile-web-app-title" content="Powers" />
        <link rel="apple-touch-icon" href="/icon-192x192.png" />
        <meta name="theme-color" content="#f8fafc" />
      </head>
      <body className="h-dvh w-screen relative bg-slate-100 overflow-hidden">
        <Providers>
          {/* <ThemeProvider> */}
            <NavBars > 
              {children}
            </NavBars > 
            <PWAInstallPrompt />
          {/* </ThemeProvider> */}
        </Providers>
      </body>
    </html>
  );
}
