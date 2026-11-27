"use client";

import { useState } from "react";
import { createClient } from "@/lib/supabase/client";

// 「入る」：理由を書いて入室記録を作り、その会社のホームへ移る。
export default function EnterCompany({
  tenantId,
  tenantName,
}: {
  tenantId: string;
  tenantName: string;
}) {
  const [open, setOpen] = useState(false);
  const [reason, setReason] = useState("");
  const [busy, setBusy] = useState(false);
  const [err, setErr] = useState("");

  async function enter() {
    setBusy(true);
    setErr("");
    try {
      const supabase = createClient();
      const {
        data: { user },
      } = await supabase.auth.getUser();
      if (!user) {
        setErr("ログインが必要です。");
        setBusy(false);
        return;
      }
      const { data: me } = await supabase
        .from("people")
        .select("id")
        .eq("auth_user_id", user.id)
        .maybeSingle();
      if (!me) {
        setErr("本人情報が見つかりません。");
        setBusy(false);
        return;
      }
      const { error } = await supabase.from("company_access_sessions").insert({
        person_id: me.id,
        target_tenant_id: tenantId,
        reason: reason || null,
      });
      if (error) {
        setErr("この会社には入れません（許可がありません）。");
        setBusy(false);
        return;
      }
      // 「入っている」印をブラウザに残し、同じURLの会社アプリ(ルート)へ。
      //   → 中身は今いる会社(acting=入った会社)で表示され、上に運営の帯が出る。
      document.cookie = "dores_enter=1; path=/; max-age=28800; samesite=lax";
      window.location.href = "/";
    } catch {
      setErr("通信に失敗しました。");
      setBusy(false);
    }
  }

  return (
    <>
      <button
        type="button"
        onClick={() => setOpen(true)}
        className="shrink-0 rounded-xl border border-white/15 bg-white/10 px-4 py-2 text-sm font-bold text-white transition hover:bg-white/20"
      >
        入る
      </button>

      {open && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/70 px-4">
          <div className="w-full max-w-sm rounded-2xl border border-white/15 bg-neutral-900 p-5">
            <h3 className="text-base font-bold text-white">{tenantName} に入る</h3>
            <p className="mt-1 text-sm text-white/60">
              運営として入った記録が残ります。入る理由を書いてください。
            </p>
            <textarea
              value={reason}
              onChange={(e) => setReason(e.target.value)}
              rows={3}
              placeholder="例：お知らせ設定の確認"
              className="mt-3 w-full rounded-xl border border-white/15 bg-white/5 px-3 py-2 text-sm text-white placeholder-white/35 outline-none focus:border-white/40"
            />
            {err && <p className="mt-2 text-sm text-rose-300">{err}</p>}
            <div className="mt-4 flex gap-2">
              <button
                type="button"
                onClick={() => setOpen(false)}
                className="flex-1 rounded-xl border border-white/15 px-3 py-2 text-sm text-white/80 hover:bg-white/10"
              >
                やめる
              </button>
              <button
                type="button"
                onClick={enter}
                disabled={busy}
                className="flex-1 rounded-xl bg-amber-400 px-3 py-2 text-sm font-bold text-black hover:bg-amber-300 disabled:opacity-60"
              >
                {busy ? "入室中…" : "入る"}
              </button>
            </div>
          </div>
        </div>
      )}
    </>
  );
}
