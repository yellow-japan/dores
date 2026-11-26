import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { getIsPlatformAdmin } from "@/lib/platform";

// DO'reS運営の画面はDO'reS運営スタッフだけ。それ以外は会社アプリ(/)へ。
export default async function PlatformLayout({ children }: { children: React.ReactNode }) {
  const supabase = await createClient();
  const isAdmin = await getIsPlatformAdmin(supabase);
  if (!isAdmin) redirect("/");
  return <>{children}</>;
}
