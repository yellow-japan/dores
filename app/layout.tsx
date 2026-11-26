import type { Metadata } from "next";
import { headers } from "next/headers";
import { Noto_Sans_JP } from "next/font/google";
import "./globals.css";
import { createClient } from "@/lib/supabase/server";
import { hostMode } from "@/lib/host";

const notoSansJp = Noto_Sans_JP({
  variable: "--font-noto-sans-jp",
  subsets: ["latin"],
  weight: ["400", "500", "700", "900"],
});

// タブに出る名前：会社のURLは会社名、dores-home は DO'reS。
export async function generateMetadata(): Promise<Metadata> {
  const h = await headers();
  const mode = hostMode(h.get("host"));
  if (mode.kind === "platform") {
    return { title: "DO'reS", description: "DO'reS 運営" };
  }
  const supabase = await createClient();
  const { data } = await supabase
    .from("app_settings")
    .select("company_display_name")
    .eq("id", 1)
    .maybeSingle();
  const companyName = data?.company_display_name ?? "yellow.inc";
  return { title: companyName, description: `${companyName}｜DO'reS` };
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
