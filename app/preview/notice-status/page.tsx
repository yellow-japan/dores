import Link from "next/link";
import AppShell from "@/components/AppShell";

const confirmed = ["テスト店長A", "テスト社員"];
const unconfirmed = [
  { name: "テストアルバイト1", code: "E006" },
  { name: "テストアルバイト2", code: "E007" },
  { name: "テスト店長B", code: "E004" },
];

export default function PreviewNoticeStatus() {
  const total = confirmed.length + unconfirmed.length;
  return (
    <AppShell companyName="yellow.inc" storeName="テスト店舗A" backgroundUrl="/default-bg.jpg">
      <div className="space-y-4 pt-2">
        <Link href="/preview/notice" className="inline-flex text-sm text-white/70">← お知らせ</Link>
        <h1 className="text-xl font-bold text-white drop-shadow">確認状況</h1>
        <p className="-mt-2 text-sm text-white/70">【重要】テスト全社お知らせ</p>

        <div className="grid grid-cols-3 gap-2">
          <div className="rounded-2xl border border-white/15 bg-black/35 px-3 py-4 text-center backdrop-blur-xl">
            <div className="text-2xl font-black text-white">{total}</div>
            <div className="mt-0.5 text-xs text-white/70">対象人数</div>
          </div>
          <div className="rounded-2xl border border-white/15 bg-black/35 px-3 py-4 text-center backdrop-blur-xl">
            <div className="text-2xl font-black text-emerald-300">{confirmed.length}</div>
            <div className="mt-0.5 text-xs text-white/70">確認済み</div>
          </div>
          <div className="rounded-2xl border border-white/15 bg-black/35 px-3 py-4 text-center backdrop-blur-xl">
            <div className="text-2xl font-black text-amber-300">{unconfirmed.length}</div>
            <div className="mt-0.5 text-xs text-white/70">未確認</div>
          </div>
        </div>

        <section className="rounded-3xl border border-white/15 bg-black/35 p-4 backdrop-blur-xl">
          <h2 className="text-sm font-bold text-amber-300">未確認（{unconfirmed.length}）</h2>
          <ul className="mt-2 space-y-1.5">
            {unconfirmed.map((p) => (
              <li key={p.code} className="flex items-center gap-2 rounded-xl border border-white/10 bg-white/5 px-3 py-2.5">
                <span className="h-2 w-2 shrink-0 rounded-full bg-amber-400" />
                <span className="text-sm font-medium text-white/95">{p.name}</span>
                <span className="ml-auto text-[11px] text-white/45">{p.code}</span>
              </li>
            ))}
          </ul>
        </section>

        <section className="rounded-3xl border border-white/15 bg-black/35 p-4 backdrop-blur-xl">
          <h2 className="text-sm font-bold text-emerald-300">確認済み（{confirmed.length}）</h2>
          <div className="mt-2 flex flex-wrap gap-1.5">
            {confirmed.map((n) => (
              <span key={n} className="rounded-full border border-emerald-400/20 bg-emerald-500/10 px-2.5 py-1 text-xs text-white/90">
                {n}
              </span>
            ))}
          </div>
        </section>
      </div>
    </AppShell>
  );
}
