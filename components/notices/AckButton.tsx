"use client";

import { useState } from "react";
import { createClient } from "@/lib/supabase/client";

function fmt(ts: string) {
  const d = new Date(ts);
  return new Intl.DateTimeFormat("ja-JP", {
    year: "numeric",
    month: "long",
    day: "numeric",
    hour: "2-digit",
    minute: "2-digit",
  }).format(d);
}

export default function AckButton({
  noticeId,
  personId,
  initialAckedAt,
}: {
  noticeId: string;
  personId: string;
  initialAckedAt: string | null;
}) {
  const [ackedAt, setAckedAt] = useState<string | null>(initialAckedAt);
  const [busy, setBusy] = useState(false);
  const [err, setErr] = useState("");

  async function confirm() {
    setBusy(true);
    setErr("");
    const supabase = createClient();
    const { data, error } = await supabase
      .from("notice_acks")
      .insert({ notice_id: noticeId, person_id: personId })
      .select("acked_at")
      .single();
    if (error) {
      setErr("確認を記録できませんでした。");
      setBusy(false);
      return;
    }
    setAckedAt(data.acked_at);
    setBusy(false);
  }

  if (ackedAt) {
    return (
      <div className="rounded-2xl border border-emerald-400/30 bg-emerald-500/15 px-4 py-4 text-center">
        <p className="text-sm font-bold text-emerald-200">確認済み</p>
        <p className="mt-0.5 text-xs text-white/70">{fmt(ackedAt)}</p>
      </div>
    );
  }

  return (
    <div>
      <button
        type="button"
        onClick={confirm}
        disabled={busy}
        className="min-h-[52px] w-full rounded-2xl bg-amber-400 text-base font-black text-black transition hover:bg-amber-300 disabled:opacity-60"
      >
        {busy ? "記録中…" : "確認しました"}
      </button>
      {err && <p className="mt-2 text-center text-sm text-rose-300">{err}</p>}
    </div>
  );
}
