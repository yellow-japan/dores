import Link from "next/link";
import { notFound } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { getMe, getIsMas, canManageNotices } from "@/lib/data";
import AckButton from "@/components/notices/AckButton";

const statusLabel: Record<string, string> = {
  draft: "下書き",
  published: "公開中",
  closed: "終了",
};

export default async function NoticeDetailPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = await params;
  const supabase = await createClient();

  const { data: notice } = await supabase
    .from("notices")
    .select("id, title, body, is_important, status, published_at")
    .eq("id", id)
    .maybeSingle();
  if (!notice) notFound();

  const me = await getMe(supabase);
  const isMas = await getIsMas(supabase);
  const canManage = isMas || (me ? await canManageNotices(supabase, me.id) : false);

  const { data: myAck } = me
    ? await supabase
        .from("notice_acks")
        .select("acked_at")
        .eq("notice_id", id)
        .eq("person_id", me.id)
        .maybeSingle()
    : { data: null };

  return (
    <div className="space-y-4 pt-2">
      <Link href="/notices" className="inline-flex text-sm text-white/70 hover:text-white">
        ← お知らせ一覧
      </Link>

      <article className="rounded-3xl border border-white/15 bg-black/35 p-5 backdrop-blur-xl">
        <div className="flex flex-wrap items-center gap-2">
          {notice.is_important && (
            <span className="rounded-md bg-rose-500/90 px-2 py-0.5 text-[11px] font-bold text-white">
              重要
            </span>
          )}
          {notice.status !== "published" && (
            <span className="rounded-md border border-white/20 bg-white/10 px-2 py-0.5 text-[11px] font-medium text-white/80">
              {statusLabel[notice.status]}
            </span>
          )}
        </div>
        <h1 className="mt-2 text-xl font-bold text-white">{notice.title}</h1>
        <p className="mt-4 whitespace-pre-wrap text-[15px] leading-relaxed text-white/90">
          {notice.body}
        </p>
      </article>

      {/* 確認しました（公開中のみ） */}
      {notice.status === "published" && me && (
        <AckButton noticeId={id} personId={me.id} initialAckedAt={myAck?.acked_at ?? null} />
      )}

      {/* 本部・管理職のリンク */}
      {canManage && (
        <div className="flex flex-wrap gap-2">
          <Link
            href={`/notices/${id}/status`}
            className="flex min-h-[44px] items-center rounded-xl border border-white/15 bg-white/10 px-4 text-sm font-bold text-white transition hover:bg-white/20"
          >
            確認状況を見る
          </Link>
          {isMas && (
            <Link
              href={`/notices/${id}/edit`}
              className="flex min-h-[44px] items-center rounded-xl border border-white/15 bg-white/10 px-4 text-sm font-bold text-white transition hover:bg-white/20"
            >
              編集する
            </Link>
          )}
        </div>
      )}
    </div>
  );
}
