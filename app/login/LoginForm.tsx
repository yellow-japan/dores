"use client";

import { useState } from "react";
import { createClient } from "@/lib/supabase/client";

export default function LoginForm() {
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
      window.location.href = "/";
    } catch {
      setErr("通信に失敗しました。電波の良い場所で、もう一度お試しください。");
      setBusy(false);
    }
  }

  return (
    <form onSubmit={onSubmit} className="space-y-4">
      <label className="block">
        <span className="mb-1 block text-xs font-bold text-white/80">メールアドレス</span>
        <input
          type="email"
          autoComplete="email"
          value={email}
          onChange={(e) => setEmail(e.target.value)}
          required
          className="min-h-[48px] w-full rounded-xl border border-white/20 bg-white/10 px-4 text-base text-white placeholder-white/40 outline-none backdrop-blur-md focus:border-white/50"
          placeholder="you@example.com"
        />
      </label>
      <label className="block">
        <span className="mb-1 block text-xs font-bold text-white/80">パスワード</span>
        <input
          type="password"
          autoComplete="current-password"
          value={password}
          onChange={(e) => setPassword(e.target.value)}
          required
          className="min-h-[48px] w-full rounded-xl border border-white/20 bg-white/10 px-4 text-base text-white placeholder-white/40 outline-none backdrop-blur-md focus:border-white/50"
          placeholder="••••••••"
        />
      </label>

      {err && <p className="text-sm text-rose-300">{err}</p>}

      <button
        type="submit"
        disabled={busy}
        className="min-h-[48px] w-full rounded-xl bg-amber-400 text-base font-black text-black transition hover:bg-amber-300 disabled:opacity-60"
      >
        {busy ? "ログイン中…" : "ログイン"}
      </button>
    </form>
  );
}
