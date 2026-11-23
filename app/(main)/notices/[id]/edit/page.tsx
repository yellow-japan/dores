import { notFound, redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { getMe, getIsMas, loadNoticeOptions } from "@/lib/data";
import NoticeForm, { type NoticeTargets } from "@/components/notices/NoticeForm";

export default async function EditNoticePage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = await params;
  const supabase = await createClient();
  const me = await getMe(supabase);
  const isMas = await getIsMas(supabase);
  if (!me || !isMas) redirect(`/notices/${id}`);

  const { data: notice } = await supabase
    .from("notices")
    .select("id, title, body, is_important, status")
    .eq("id", id)
    .maybeSingle();
  if (!notice) notFound();

  const { data: targetRows } = await supabase
    .from("notice_targets")
    .select("target_type, target_id")
    .eq("notice_id", id)
    .eq("active", true);

  const targets: NoticeTargets = {
    all: false,
    storeIds: [],
    areaIds: [],
    rankIds: [],
    personIds: [],
  };
  (targetRows ?? []).forEach((r) => {
    if (r.target_type === "all") targets.all = true;
    else if (r.target_type === "store" && r.target_id) targets.storeIds.push(r.target_id);
    else if (r.target_type === "area" && r.target_id) targets.areaIds.push(r.target_id);
    else if (r.target_type === "rank" && r.target_id) targets.rankIds.push(r.target_id);
    else if (r.target_type === "person" && r.target_id) targets.personIds.push(r.target_id);
  });

  const options = await loadNoticeOptions(supabase);

  return (
    <NoticeForm
      mode="edit"
      meId={me.id}
      options={options}
      initial={{
        id: notice.id,
        title: notice.title,
        body: notice.body,
        is_important: notice.is_important,
        status: notice.status,
        targets,
      }}
    />
  );
}
