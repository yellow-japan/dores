import Link from "next/link";
import AppShell from "@/components/AppShell";
import AckButton from "@/components/notices/AckButton";

export default function PreviewNoticeDetail() {
  return (
    <AppShell companyName="yellow.inc" storeName="テスト店舗A" backgroundUrl="/default-bg.jpg">
      <div className="space-y-4 pt-2">
        <Link href="/preview/notices" className="inline-flex text-sm text-white/70">← お知らせ一覧</Link>
        <article className="rounded-3xl border border-white/15 bg-black/35 p-5 backdrop-blur-xl">
          <span className="rounded-md bg-rose-500/90 px-2 py-0.5 text-[11px] font-bold text-white">重要</span>
          <h1 className="mt-2 text-xl font-bold text-white">【重要】テスト全社お知らせ</h1>
          <p className="mt-4 whitespace-pre-wrap text-[15px] leading-relaxed text-white/90">
            全員向けの重要なお知らせです。{"\n"}内容を確認したら「確認しました」を押してください。
          </p>
        </article>
        <AckButton noticeId="demo" personId="demo" initialAckedAt={null} />
        <div className="flex flex-wrap gap-2">
          <span className="flex min-h-[44px] items-center rounded-xl border border-white/15 bg-white/10 px-4 text-sm font-bold text-white">確認状況を見る</span>
          <span className="flex min-h-[44px] items-center rounded-xl border border-white/15 bg-white/10 px-4 text-sm font-bold text-white">編集する</span>
        </div>
      </div>
    </AppShell>
  );
}
