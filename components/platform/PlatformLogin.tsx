import Image from "next/image";
import PlatformLoginForm from "@/components/platform/PlatformLoginForm";

// DO'reS運営専用のログイン画面（黒・ロゴ・キャッチコピー）
export default function PlatformLogin() {
  return (
    <div className="grid min-h-dvh place-items-center bg-black px-4">
      <div className="w-full max-w-sm">
        <div className="mb-8 flex flex-col items-center text-center">
          <Image
            src="/dores-logo.png"
            alt="DO'reS"
            width={320}
            height={140}
            priority
            className="dores-logo-in h-auto w-[min(62vw,280px)] select-none"
          />
          <p className="dores-tagline mt-7 text-[11px] font-light uppercase tracking-[0.3em] text-white/55">
            The future starts with action.
          </p>
        </div>

        <div className="rounded-3xl border border-white/10 bg-white/[0.03] p-6">
          <PlatformLoginForm />
          <p className="mt-4 text-center text-xs text-white/40">
            DO&rsquo;reS運営スタッフだけが入れます
          </p>
        </div>
      </div>
    </div>
  );
}
