import { createClient } from "@/lib/supabase/server";
import AppShell from "@/components/AppShell";
import { getMe, getBranding, getStoreName } from "@/lib/data";

export default async function MainLayout({ children }: { children: React.ReactNode }) {
  // 未ログインは middleware が /login に送るので、ここでは本人情報と設定を並行取得する
  const supabase = await createClient();
  const [me, branding] = await Promise.all([getMe(supabase), getBranding(supabase)]);
  const storeName = me ? await getStoreName(supabase, me.id) : null;

  return (
    <AppShell
      companyName={branding.companyName}
      storeName={storeName}
      backgroundUrl={branding.backgroundUrl}
    >
      {children}
    </AppShell>
  );
}
