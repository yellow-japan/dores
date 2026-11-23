"use client";

import { useRouter } from "next/navigation";
import { NAV } from "@/components/nav";

// ホームの機能アイコン。お知らせ以外（href なし）は押すと「準備中」。
export default function FeatureGrid() {
  const router = useRouter();
  const items = NAV.filter((n) => n.key !== "home");

  return (
    <div className="grid grid-cols-4 gap-3">
      {items.map((item) => {
        const ready = !!item.href;
        return (
          <button
            key={item.key}
            type="button"
            onClick={() => (ready ? router.push(item.href!) : alert(`「${item.label}」は準備中です`))}
            className="flex min-h-[44px] flex-col items-center gap-1.5 rounded-2xl border border-white/15 bg-white/10 px-1 py-3 text-center backdrop-blur-md transition hover:bg-white/20"
          >
            <span className="grid h-11 w-11 place-items-center rounded-xl border border-white/15 bg-white/10 text-white">
              <item.Icon className="h-6 w-6" />
            </span>
            <span className="text-xs font-medium text-white/90">{item.label}</span>
            {!ready && <span className="text-[9px] text-white/50">準備中</span>}
          </button>
        );
      })}
    </div>
  );
}
