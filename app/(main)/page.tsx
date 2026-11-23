import { createClient } from "@/lib/supabase/server";
import HomeView, { type NoticeLite } from "@/components/HomeView";
import { getMe } from "@/lib/data";

function greeting(h: number) {
  if (h >= 5 && h < 11) return "おはようございます";
  if (h >= 18 || h < 5) return "こんばんは";
  return "おつかれさまです";
}

export default async function HomePage() {
  const supabase = await createClient();
  const me = await getMe(supabase);
  const userName = me?.display_name ?? "ゲスト";

  const now = new Date();
  const dateStr = new Intl.DateTimeFormat("ja-JP", {
    month: "long",
    day: "numeric",
    weekday: "short",
  }).format(now);
  const greetingStr = greeting(now.getHours());

  // 自分に見えている公開中のお知らせ（RLSで自動的に絞られる）
  const { data: noticesData } = await supabase
    .from("notices")
    .select("id, title, is_important, published_at")
    .eq("status", "published");
  const notices: NoticeLite[] = noticesData ?? [];

  // 自分の確認済み
  const { data: acksData } = me
    ? await supabase.from("notice_acks").select("notice_id").eq("person_id", me.id)
    : { data: [] as { notice_id: string }[] };
  const acked = new Set((acksData ?? []).map((a) => a.notice_id));

  const unreadCount = notices.filter((n) => !acked.has(n.id)).length;

  // 未確認を上に → 重要を上に → 新しい順
  const latest = [...notices]
    .sort((a, b) => {
      const ua = acked.has(a.id) ? 1 : 0;
      const ub = acked.has(b.id) ? 1 : 0;
      if (ua !== ub) return ua - ub;
      if (a.is_important !== b.is_important) return a.is_important ? -1 : 1;
      return (b.published_at ?? "").localeCompare(a.published_at ?? "");
    })
    .slice(0, 4);

  return (
    <HomeView
      userName={userName}
      dateStr={dateStr}
      greetingStr={greetingStr}
      unreadCount={unreadCount}
      latest={latest}
    />
  );
}
