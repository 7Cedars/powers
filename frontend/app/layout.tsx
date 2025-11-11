import React from "react";
import type { Metadata, Viewport } from "next";
import { Providers } from "../context/Providers"
import "./globals.css";

export const metadata: Metadata = {
  title: "Powers Protocol",
  description: "UI to interact with organisations using the Powers Protocol.",
};

export const viewport: Viewport = {
  themeColor: "#475569",
  width: "device-width",
  initialScale: 1,
  maximumScale: 1,
  userScalable: false,
};

export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {

  // Full screen layout for landing page -- integrate here? 
//   <div className="w-full h-full grid grid-cols-1 overflow-y-scroll" id="navigation-bar">
//   <main className="w-full h-full grid grid-cols-1 overflow-y-scroll">
//     {children}
//   </main>
// </div>

{/* <Footer />  */}

  return (
    <html lang="en">
      <head />
      <body className="h-dvh w-screen relative bg-slate-100 overflow-hidden">
        <Providers>
          {children}
        </Providers>
      </body>
    </html>
  );
}
