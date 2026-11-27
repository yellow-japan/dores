import type { Metadata } from "next";
import { headers } from "next/headers";
import { Noto_Sans_JP } from "next/font/google";
import "./globals.css";
import { createClient } from "@/lib/supabase/server";
import { resolveHost } from "@/lib/host";

const notoSansJp = Noto_Sans_JP({
  variable: "--font-noto-sans-jp",
  subsets: ["latin"],
  weight: ["400", "500", "700", "900"],
});

// タブに出る名前：会社のURLは会社名、dores-home は DO'reS（対応データから）。
export async function generateMetadata(): Promise<Metadata> {
  const h = await headers();
  const supabase = await createClient();
  const info = await resolveHost(supabase, h.get("host"));
  if (info.kind === "tenant") {
    return { title: info.displayName, description: `${info.displayName}｜DO'reS` };
  }
  return { title: "DO'reS", description: "DO'reS 運営" };
}

export default function RootLayout({ children }: LayoutProps<"/">) {
  return (
    <html lang="ja" className={`${notoSansJp.variable} h-full`}>
      <body className="min-h-full bg-neutral-900 text-white antialiased">
        {children}
      </body>
    </html>
  );
}
