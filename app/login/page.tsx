import LoginForm from "./LoginForm";
import { createClient } from "@/lib/supabase/server";

// ログインは認証前なので背景は同梱の初期画像。会社名は設定(app_settings)から（anonで読み取り可）。
export default async function LoginPage() {
  const supabase = await createClient();
  const { data } = await supabase
    .from("app_settings")
    .select("company_display_name")
    .eq("id", 1)
    .maybeSingle();
  const companyName = data?.company_display_name ?? "yellow.inc";

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
