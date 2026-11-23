"use client";

import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";
import { NAV } from "@/components/nav";

// 下部のドック（マックのドック風）。スマホは dock:true の4つ、パソコンは全部。
export default function Dock() {
  const pathname = usePathname();
  const router = useRouter();

  function go(item: (typeof NAV)[number]) {
    if (item.href) router.push(item.href);
    else alert(`「${item.label}」は準備中です`);
  }

  return (
    <nav className="pointer-events-auto fixed inset-x-0 bottom-0 z-20 flex justify-center pb-[max(12px,env(safe-area-inset-bottom))] pt-2">
      <div className="flex items-end gap-1 rounded-2xl border border-white/15 bg-black/35 px-2 py-1.5 backdrop-blur-xl sm:gap-2 sm:px-3">
        {NAV.map((item) => {
          const active = item.href === pathname;
          const onDock = item.dock;
          return (
            <button
              key={item.key}
              type="button"
              onClick={() => go(item)}
              aria-label={item.label}
              className={[
                "group flex min-h-[44px] min-w-[44px] flex-col items-center justify-center gap-0.5 rounded-xl px-2 py-1 transition",
                onDock ? "flex" : "hidden sm:flex",
                active ? "bg-white/15" : "hover:bg-white/10",
              ].join(" ")}
            >
              <span
                className={[
                  "grid h-9 w-9 place-items-center rounded-lg border border-white/15 bg-white/10",
                  active ? "text-white" : "text-white/85",
                ].join(" ")}
              >
                <item.Icon className="h-5 w-5" />
              </span>
              <span className="text-[10px] font-medium text-white/80">{item.label}</span>
            </button>
          );
        })}
      </div>
    </nav>
  );
}
