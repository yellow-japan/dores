"use client";

import { useState } from "react";
import { createClient } from "@/lib/supabase/client";

// 「入る」：押したらそのまま入室記録を作り、その会社のホームへ（理由の入力は不要）。
export default function EnterCompany({
  tenantId,
  tenantName,
}: {
  tenantId: string;
  tenantName: string;
}) {
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
      });
      if (error) {
        setErr("入れません（許可なし）");
        setBusy(false);
        return;
      }
      // 「入っている」印をブラウザに残し、同じURLの会社アプリ(ルート)へ。
      document.cookie = "dores_enter=1; path=/; max-age=28800; samesite=lax";
      window.location.href = "/";
    } catch {
      setErr("通信に失敗しました。");
      setBusy(false);
    }
  }

  return (
    <div className="flex shrink-0 items-center gap-2">
      {err && <span className="text-xs text-rose-300">{err}</span>}
      <button
        type="button"
        onClick={enter}
        disabled={busy}
        aria-label={`${tenantName} に入る`}
        className="rounded-xl border border-white/15 bg-white/10 px-4 py-2 text-sm font-bold text-white transition hover:bg-white/20 disabled:opacity-60"
      >
        {busy ? "入室中…" : "入る"}
      </button>
    </div>
  );
}
