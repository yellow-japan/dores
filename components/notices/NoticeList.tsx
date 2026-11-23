"use client";

import { useState } from "react";
import Link from "next/link";

export type NoticeItem = {
  id: string;
  title: string;
  is_important: boolean;
  published_at: string | null;
  status: "draft" | "published" | "closed";
  isRead: boolean;
};

const statusLabel: Record<string, string> = { draft: "下書き", closed: "終了" };

export default function NoticeList({ items, isMas }: { items: NoticeItem[]; isMas: boolean }) {
  const [unreadOnly, setUnreadOnly] = useState(false);

  const sorted = [...items].sort((a, b) => {
    const ua = a.isRead ? 1 : 0;
    const ub = b.isRead ? 1 : 0;
    if (ua !== ub) return ua - ub;
    if (a.is_important !== b.is_important) return a.is_important ? -1 : 1;
    return (b.published_at ?? "").localeCompare(a.published_at ?? "");
  });
  const shown = unreadOnly ? sorted.filter((n) => !n.isRead && n.status === "published") : sorted;

  return (
    <div className="space-y-4 pt-2">
      <div className="flex items-center gap-3">
        <h1 className="text-xl font-bold text-white drop-shadow">お知らせ</h1>
        {isMas && (
          <Link
            href="/notices/new"
            className="ml-auto flex min-h-[44px] items-center rounded-xl border border-white/15 bg-amber-400 px-4 text-sm font-bold text-black transition hover:bg-amber-300"
          >
            ＋ 新規作成
          </Link>
        )}
      </div>

      <label className="flex min-h-[44px] w-fit cursor-pointer select-none items-center gap-2 rounded-full border border-white/15 bg-black/30 px-4 backdrop-blur-md">
        <input
          type="checkbox"
          checked={unreadOnly}
          onChange={(e) => setUnreadOnly(e.target.checked)}
          className="h-4 w-4 accent-amber-400"
        />
        <span className="text-sm font-medium text-white/90">未確認だけ</span>
      </label>

      <div className="space-y-2">
        {shown.length === 0 && (
          <p className="rounded-2xl border border-white/15 bg-black/35 px-4 py-6 text-center text-sm text-white/70 backdrop-blur-xl">
            {unreadOnly ? "未確認のお知らせはありません" : "お知らせはありません"}
          </p>
        )}
        {shown.map((n) => (
          <Link
            key={n.id}
            href={`/notices/${n.id}`}
            className={[
              "flex items-center gap-2 rounded-2xl border px-4 py-4 backdrop-blur-xl transition",
              n.is_important
                ? "border-rose-400/40 bg-rose-500/15 hover:bg-rose-500/25"
                : "border-white/15 bg-black/35 hover:bg-black/45",
            ].join(" ")}
          >
            {!n.isRead && n.status === "published" && (
              <span className="h-2 w-2 shrink-0 rounded-full bg-amber-400" />
            )}
            {n.is_important && (
              <span className="shrink-0 rounded-md bg-rose-500/90 px-1.5 py-0.5 text-[10px] font-bold text-white">
                重要
              </span>
            )}
            <span className="truncate text-sm font-medium text-white/95">{n.title}</span>
            <span className="ml-auto shrink-0 text-[11px] text-white/55">
              {n.status !== "published"
                ? statusLabel[n.status]
                : n.isRead
                  ? "確認済み"
                  : "未確認"}
            </span>
          </Link>
        ))}
      </div>
    </div>
  );
}
