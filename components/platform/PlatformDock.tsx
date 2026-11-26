"use client";

import { useRouter } from "next/navigation";
import { PLATFORM_NAV } from "@/components/platform/platform-nav";

// DO'reS運営の下部ドック（黒い画面・白い線のアイコン）
export default function PlatformDock({ active }: { active: string }) {
  const router = useRouter();
  return (
    <nav className="fixed inset-x-0 bottom-0 z-20 flex justify-center pb-[max(14px,env(safe-area-inset-bottom))] pt-2">
      <div className="flex items-end gap-1 rounded-2xl border border-white/10 bg-white/[0.04] px-2 py-1.5 backdrop-blur-xl sm:gap-2 sm:px-3">
        {PLATFORM_NAV.map((item) => {
          const on = item.key === active;
          return (
            <button
              key={item.key}
              type="button"
              onClick={() => router.push(item.href)}
              aria-label={item.label}
              className={[
                "group flex min-h-[44px] min-w-[52px] flex-col items-center justify-center gap-1 rounded-xl px-2 py-1 transition",
                on ? "bg-white/10" : "hover:bg-white/[0.06]",
              ].join(" ")}
            >
              <span
                className={[
                  "grid h-9 w-9 place-items-center rounded-lg border border-white/10",
                  on ? "bg-white/15 text-white" : "bg-white/[0.03] text-white/70",
                ].join(" ")}
              >
                <item.Icon className="h-5 w-5" />
              </span>
              <span className={on ? "text-[10px] text-white/90" : "text-[10px] text-white/55"}>
                {item.label}
              </span>
            </button>
          );
        })}
      </div>
    </nav>
  );
}
