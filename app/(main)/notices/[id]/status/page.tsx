import Link from "next/link";
import { notFound, redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { getMe, getIsMas, canManageNotices } from "@/lib/data";

export default async function NoticeStatusPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = await params;
  const supabase = await createClient();

  const { data: notice } = await supabase
    .from("notices")
    .select("id, title")
    .eq("id", id)
    .maybeSingle();
  if (!notice) notFound();

  const me = await getMe(supabase);
  const isMas = await getIsMas(supabase);
  const canManage = isMas || (me ? await canManageNotices(supabase, me.id) : false);
  if (!canManage) redirect(`/notices/${id}`);

  // 対象者（展開）→ 見てよい人だけに絞る（people の RLS）
  const { data: targetIdsRaw } = await supabase.rpc("notice_target_person_ids", {
    p_notice: id,
  });
  const targetIds: string[] = (targetIdsRaw ?? []) as string[];

  const { data: peopleData } = targetIds.length
    ? await supabase.from("people").select("id, display_name, employee_code").in("id", targetIds)
    : { data: [] as { id: string; display_name: string; employee_code: string }[] };
  const people = peopleData ?? [];

  const { data: acksData } = await supabase
    .from("notice_acks")
    .select("person_id")
    .eq("notice_id", id);
  const ackedSet = new Set((acksData ?? []).map((a) => a.person_id));

  const confirmed = people.filter((p) => ackedSet.has(p.id));
  const unconfirmed = people.filter((p) => !ackedSet.has(p.id));

  return (
    <div className="space-y-4 pt-2">
      <Link href={`/notices/${id}`} className="inline-flex text-sm text-white/70 hover:text-white">
        ← お知らせ
      </Link>
      <h1 className="text-xl font-bold text-white drop-shadow">確認状況</h1>
      <p className="-mt-2 text-sm text-white/70">{notice.title}</p>

      {!isMas && (
        <p className="rounded-xl border border-white/15 bg-black/30 px-3 py-2 text-xs text-white/70 backdrop-blur-md">
          ※ あなたが見てよい人の分だけを表示しています。
        </p>
      )}

      {/* 集計 */}
      <div className="grid grid-cols-3 gap-2">
        {[
          { label: "対象人数", value: people.length, tone: "text-white" },
          { label: "確認済み", value: confirmed.length, tone: "text-emerald-300" },
          { label: "未確認", value: unconfirmed.length, tone: "text-amber-300" },
        ].map((c) => (
          <div
            key={c.label}
            className="rounded-2xl border border-white/15 bg-black/35 px-3 py-4 text-center backdrop-blur-xl"
          >
            <div className={`text-2xl font-black ${c.tone}`}>{c.value}</div>
            <div className="mt-0.5 text-xs text-white/70">{c.label}</div>
          </div>
        ))}
      </div>

      {/* 未確認の人 */}
      <section className="rounded-3xl border border-white/15 bg-black/35 p-4 backdrop-blur-xl">
        <h2 className="text-sm font-bold text-amber-300">未確認（{unconfirmed.length}）</h2>
        <ul className="mt-2 space-y-1.5">
          {unconfirmed.length === 0 && (
            <li className="text-sm text-white/60">全員が確認済みです。</li>
          )}
          {unconfirmed.map((p) => (
            <li
              key={p.id}
              className="flex items-center gap-2 rounded-xl border border-white/10 bg-white/5 px-3 py-2.5"
            >
              <span className="h-2 w-2 shrink-0 rounded-full bg-amber-400" />
              <span className="text-sm font-medium text-white/95">{p.display_name}</span>
              <span className="ml-auto text-[11px] text-white/45">{p.employee_code}</span>
            </li>
          ))}
        </ul>
      </section>

      {/* 確認済みの人 */}
      {confirmed.length > 0 && (
        <section className="rounded-3xl border border-white/15 bg-black/35 p-4 backdrop-blur-xl">
          <h2 className="text-sm font-bold text-emerald-300">確認済み（{confirmed.length}）</h2>
          <div className="mt-2 flex flex-wrap gap-1.5">
            {confirmed.map((p) => (
              <span
                key={p.id}
                className="rounded-full border border-emerald-400/20 bg-emerald-500/10 px-2.5 py-1 text-xs text-white/90"
              >
                {p.display_name}
              </span>
            ))}
          </div>
        </section>
      )}
    </div>
  );
}
