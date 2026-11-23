"use client";

import { useState } from "react";
import { createClient } from "@/lib/supabase/client";
import { IconLogout } from "@/components/icons";

export default function LogoutButton() {
  const [busy, setBusy] = useState(false);
  async function signOut() {
    setBusy(true);
    try {
      await createClient().auth.signOut();
    } catch {
      /* 失敗してもログイン画面へ送る */
    }
    window.location.href = "/login";
  }
  return (
    <button
      type="button"
      onClick={signOut}
      disabled={busy}
      aria-label="ログアウト"
      className="flex min-h-[44px] min-w-[44px] items-center justify-center rounded-xl border border-white/15 bg-white/10 px-3 text-white/85 transition hover:bg-white/20 disabled:opacity-50"
    >
      <IconLogout className="h-5 w-5" />
    </button>
  );
}
