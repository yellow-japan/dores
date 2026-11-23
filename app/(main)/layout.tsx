import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import AppShell from "@/components/AppShell";
import { getMe, getBranding, getStoreName } from "@/lib/data";

export default async function MainLayout({ children }: { children: React.ReactNode }) {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) redirect("/login");

  const me = await getMe(supabase);
  const branding = await getBranding(supabase);
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
