import type { Metadata } from "next";
import { Playfair_Display, Merriweather } from "next/font/google";
import Link from "next/link";
import "./globals.css";

const playfair = Playfair_Display({
  variable: "--font-playfair",
  subsets: ["latin"],
  style: ["normal", "italic"],
});

const merriweather = Merriweather({
  variable: "--font-merriweather",
  subsets: ["latin"],
  weight: ["300", "400", "700"],
});

export const metadata: Metadata = {
  title: "Cognata — The Language Decryption Engine",
  description:
    "You already know 3,000 words in German, Spanish, Italian and French — you just don't know the cipher yet.",
};

const NAV = [
  { href: "/daily", label: "Daily Cognate" },
  { href: "/matrix", label: "Decryption Matrix" },
  { href: "/tree", label: "Kinship Tree" },
  { href: "/about", label: "About" },
];

export default function RootLayout({
  children,
}: Readonly<{ children: React.ReactNode }>) {
  return (
    <html lang="en">
      <body className={`${playfair.variable} ${merriweather.variable} antialiased`}>
        <header className="border-b border-[#e5dcc8] bg-[#fffdf7]/80 backdrop-blur sticky top-0 z-10">
          <div className="mx-auto flex max-w-5xl items-center justify-between px-4 py-3">
            <Link href="/" className="font-display text-2xl font-bold tracking-tight">
              Cognata
              <span className="ml-2 hidden text-xs font-normal uppercase tracking-[0.2em] text-faded sm:inline">
                the language cipher
              </span>
            </Link>
            <nav className="flex gap-3 text-sm sm:gap-5">
              {NAV.map((n) => (
                <Link
                  key={n.href}
                  href={n.href}
                  className="text-faded transition-colors hover:text-accent"
                >
                  {n.label}
                </Link>
              ))}
            </nav>
          </div>
        </header>
        <main className="mx-auto max-w-5xl px-4 py-10">{children}</main>
        <footer className="mt-16 border-t border-[#e5dcc8] py-8 text-center text-sm text-faded">
          Built on historical linguistics — Grimm&apos;s Law, the High German shift, and the
          Wiktionary etymology community.
        </footer>
      </body>
    </html>
  );
}
