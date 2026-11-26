"use client";

import { useState } from "react";
import { createClient } from "@/lib/supabase/client";

// DO'reS運営用のログインフォーム（黒に合う白・灰色。黄色ボタンは使わない）
export default function PlatformLoginForm() {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [err, setErr] = useState("");
  const [busy, setBusy] = useState(false);

  async function onSubmit(e: React.FormEvent) {
    e.preventDefault();
    setErr("");
    setBusy(true);
    try {
      const supabase = createClient();
      const { error } = await supabase.auth.signInWithPassword({ email, password });
      if (error) {
        setErr("メールアドレスかパスワードが正しくありません。");
        setBusy(false);
        return;
      }
      window.location.href = "/platform";
    } catch {
      setErr("通信に失敗しました。もう一度お試しください。");
      setBusy(false);
    }
  }

  return (
    <form onSubmit={onSubmit} className="space-y-4">
      <label className="block">
        <span className="mb-1 block text-xs font-medium text-white/60">メールアドレス</span>
        <input
          type="email"
          autoComplete="email"
          value={email}
          onChange={(e) => setEmail(e.target.value)}
          required
          className="min-h-[48px] w-full rounded-xl border border-white/15 bg-white/[0.05] px-4 text-base text-white placeholder-white/30 outline-none focus:border-white/40"
          placeholder="you@example.com"
        />
      </label>
      <label className="block">
        <span className="mb-1 block text-xs font-medium text-white/60">パスワード</span>
        <input
          type="password"
          autoComplete="current-password"
          value={password}
          onChange={(e) => setPassword(e.target.value)}
          required
          className="min-h-[48px] w-full rounded-xl border border-white/15 bg-white/[0.05] px-4 text-base text-white placeholder-white/30 outline-none focus:border-white/40"
          placeholder="••••••••"
        />
      </label>

      {err && <p className="text-sm text-rose-300">{err}</p>}

      <button
        type="submit"
        disabled={busy}
        className="min-h-[48px] w-full rounded-xl bg-white text-base font-bold text-black transition hover:bg-white/90 disabled:opacity-60"
      >
        {busy ? "ログイン中…" : "ログイン"}
      </button>
    </form>
  );
}
