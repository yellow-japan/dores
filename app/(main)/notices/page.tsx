import { createClient } from "@/lib/supabase/server";
import { getMe, getIsMas } from "@/lib/data";
import NoticeList, { type NoticeItem } from "@/components/notices/NoticeList";

export default async function NoticesPage() {
  const supabase = await createClient();

  // 本人・MAS判定・お知らせ一覧を並行取得（RLS: MASは下書き含め全部／他は公開中かつ自分が対象）
  const [me, isMas, noticesRes] = await Promise.all([
    getMe(supabase),
    getIsMas(supabase),
    supabase.from("notices").select("id, title, is_important, published_at, status"),
  ]);
  const noticesData = noticesRes.data;

  const { data: acksData } = me
    ? await supabase.from("notice_acks").select("notice_id").eq("person_id", me.id)
    : { data: [] as { notice_id: string }[] };
  const acked = new Set((acksData ?? []).map((a) => a.notice_id));

  const items: NoticeItem[] = (noticesData ?? []).map((n) => ({
    id: n.id,
    title: n.title,
    is_important: n.is_important,
    published_at: n.published_at,
    status: n.status,
    isRead: acked.has(n.id),
  }));

  return <NoticeList items={items} isMas={isMas} />;
}
