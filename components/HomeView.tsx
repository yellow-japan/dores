import Link from "next/link";
import FeatureGrid from "@/components/FeatureGrid";
import { IconBell } from "@/components/icons";

export type NoticeLite = {
  id: string;
  title: string;
  is_important: boolean;
  published_at: string | null;
};

type Props = {
  userName: string;
  dateStr: string;
  greetingStr: string;
  unreadCount: number;
  latest: NoticeLite[]; // 最新の数件（未確認を上に）
};

export default function HomeView({ userName, dateStr, greetingStr, unreadCount, latest }: Props) {
  return (
    <div className="space-y-5">
      {/* あいさつ・日付 */}
      <section className="pt-2">
        <p className="text-sm text-white/70">{dateStr}</p>
        <h1 className="mt-1 text-2xl font-bold text-white drop-shadow">
          {greetingStr}、{userName}さん
        </h1>
      </section>

      {/* お知らせカード */}
      <section className="rounded-3xl border border-white/15 bg-black/35 p-4 backdrop-blur-xl">
        <div className="flex items-center gap-2">
          <span className="grid h-9 w-9 place-items-center rounded-xl border border-white/15 bg-white/10 text-white">
            <IconBell className="h-5 w-5" />
          </span>
          <h2 className="text-base font-bold text-white">お知らせ</h2>
          {unreadCount > 0 && (
            <span className="ml-auto rounded-full bg-amber-400 px-2.5 py-0.5 text-xs font-bold text-black">
              未確認 {unreadCount}
            </span>
          )}
        </div>

        <ul className="mt-3 space-y-2">
          {latest.length === 0 && (
            <li className="rounded-xl border border-white/10 bg-white/5 px-3 py-3 text-sm text-white/70">
              新しいお知らせはありません
            </li>
          )}
          {latest.map((n) => (
            <li
              key={n.id}
              className="flex items-center gap-2 rounded-xl border border-white/10 bg-white/5 px-3 py-3"
            >
              {n.is_important && (
                <span className="shrink-0 rounded-md bg-rose-500/90 px-1.5 py-0.5 text-[10px] font-bold text-white">
                  重要
                </span>
              )}
              <span className="truncate text-sm font-medium text-white/95">{n.title}</span>
            </li>
          ))}
        </ul>

        <Link
          href="/notices"
          className="mt-3 flex min-h-[44px] items-center justify-center rounded-xl border border-white/15 bg-white/10 text-sm font-bold text-white transition hover:bg-white/20"
        >
          お知らせをすべて見る
        </Link>
      </section>

      {/* 機能アイコン */}
      <section>
        <h2 className="mb-2 px-1 text-sm font-bold text-white/80">メニュー</h2>
        <FeatureGrid />
      </section>
    </div>
  );
}
