import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { getMe, getIsMas, loadNoticeOptions } from "@/lib/data";
import NoticeForm from "@/components/notices/NoticeForm";

export default async function NewNoticePage() {
  const supabase = await createClient();
  const me = await getMe(supabase);
  const isMas = await getIsMas(supabase);
  if (!me || !isMas) redirect("/notices");

  const options = await loadNoticeOptions(supabase);
  return <NoticeForm mode="create" meId={me.id} options={options} />;
}
