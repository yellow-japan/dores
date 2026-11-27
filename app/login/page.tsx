import { headers } from "next/headers";
import LoginForm from "./LoginForm";
import PlatformLogin from "@/components/platform/PlatformLogin";
import UnknownHost from "@/components/UnknownHost";
import { createClient } from "@/lib/supabase/server";
import { resolveHost } from "@/lib/host";

// URL（ホスト名）で画面を分ける（追加7・データ化）：
//   dores-home → DO'reS運営ログイン（黒）／会社URL → その会社のログイン／未登録 → 入口なし
export default async function LoginPage() {
  const h = await headers();
  const supabase = await createClient();
  const info = await resolveHost(supabase, h.get("host"));

  if (info.kind === "platform") return <PlatformLogin />;
  if (info.kind === "unknown") return <UnknownHost />;

  // 会社用（背景・会社名）。会社名は対応データ(tenant_hostnames→tenants)から。
  const companyName = info.displayName;

  return (
    <div className="relative grid min-h-dvh place-items-center px-4">
      <div
        className="fixed inset-0 -z-10 bg-cover bg-center"
        style={{ backgroundImage: "url(/default-bg.jpg)" }}
      />
      <div className="fixed inset-0 -z-10 bg-gradient-to-b from-black/50 via-black/45 to-black/70" />

      <div className="w-full max-w-sm rounded-3xl border border-white/15 bg-black/35 p-6 backdrop-blur-xl">
        <div className="mb-5 text-center">
          <p className="text-xs font-bold tracking-[0.2em] text-white/60">DO&rsquo;reS</p>
          <h1 className="mt-0.5 text-3xl font-black tracking-wide text-white drop-shadow">
            {companyName}
          </h1>
          <p className="mt-2 text-sm text-white/70">ログインしてください</p>
        </div>
        <LoginForm />
      </div>
    </div>
  );
}
