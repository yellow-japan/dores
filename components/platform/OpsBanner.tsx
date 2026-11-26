"use client";

import { useState } from "react";
import { createClient } from "@/lib/supabase/client";

// 会社に「入っている」間、全画面の上に出る帯（追加2）。「出る」で退出記録を閉じて運営ホームへ。
export default function OpsBanner({
  companyName,
  sessionId,
  platformUrl,
}: {
  companyName: string;
  sessionId: string;
  platformUrl: string;
}) {
  const [busy, setBusy] = useState(false);
  async function exit() {
    setBusy(true);
    const supabase = createClient();
    await supabase
      .from("company_access_sessions")
      .update({ exited_at: new Date().toISOString() })
      .eq("id", sessionId);
    window.location.href = platformUrl;
  }
  return (
    <div className="sticky top-0 z-30 flex items-center gap-2 bg-amber-400 px-4 py-2 text-sm text-black">
      <span className="font-bold">DO&rsquo;reS 運営として閲覧中</span>
      <span className="opacity-80">（{companyName}）</span>
      <button
        type="button"
        onClick={exit}
        disabled={busy}
        className="ml-auto rounded-lg bg-black/85 px-3 py-1 text-xs font-bold text-white hover:bg-black disabled:opacity-60"
      >
        {busy ? "退出中…" : "出る"}
      </button>
    </div>
  );
}
