import type { Metadata } from "next";
import { Geist, Geist_Mono } from "next/font/google";
import { Analytics } from "@vercel/analytics/next";
import "./globals.css";

const geistSans = Geist({
  variable: "--font-geist-sans",
  subsets: ["latin"],
});

const geistMono = Geist_Mono({
  variable: "--font-geist-mono",
  subsets: ["latin"],
});

export const metadata: Metadata = {
  title: "committed - accountability you can't escape",
  description:
    "macOS menu bar app that forces pre-mortems, post-mortems, and Brier-scored forecasting. You can't use your computer without active commitments.",
  icons: {
    icon: [
      { url: "/favicon-32.png", sizes: "32x32", type: "image/png" },
      { url: "/favicon-64.png", sizes: "64x64", type: "image/png" },
    ],
    apple: "/apple-touch-icon.png",
  },
  openGraph: {
    title: "committed",
    description: "Accountability you can't escape. macOS menu bar app with forced pre/post mortems and Brier scoring.",
    type: "website",
    url: "https://committed-app.vercel.app",
    images: [
      {
        url: "/og-image.png",
        width: 1200,
        height: 630,
        alt: "committed - accountability you can't escape",
      },
    ],
  },
  twitter: {
    card: "summary_large_image",
    title: "committed",
    description: "Accountability you can't escape. macOS menu bar app with forced pre/post mortems and Brier scoring.",
    images: ["/og-image.png"],
  },
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html
      lang="en"
      className={`${geistSans.variable} ${geistMono.variable} h-full antialiased`}
    >
      <body className="min-h-full flex flex-col">
        {children}
        <Analytics />
      </body>
    </html>
  );
}
