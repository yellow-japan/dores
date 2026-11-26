import Link from "next/link";
import PlatformDock from "@/components/platform/PlatformDock";
import LogoutButton from "@/components/LogoutButton";

type Props = {
  userName: string;
  dateStr: string;
  active: string;
  children: React.ReactNode;
};

// DO'reS運営の共通枠：黒いMac風。上＝細いメニューバー／下＝ドック。
export default function PlatformShell({ userName, dateStr, active, children }: Props) {
  return (
    <div className="relative min-h-dvh bg-black text-white">
      {/* 細いメニューバー */}
      <header className="sticky top-0 z-20 flex items-center gap-4 border-b border-white/10 bg-black/80 px-4 py-2 text-sm backdrop-blur-xl pt-[max(8px,env(safe-area-inset-top))]">
        <Link href="/platform" className="font-black tracking-wide text-white">
          DO&rsquo;reS
        </Link>
        <span className="text-white/25">運営</span>
        <nav className="hidden items-center gap-4 sm:flex">
          <Link href="/platform/companies" className="text-white/60 hover:text-white">会社</Link>
          <Link href="/platform/deploy" className="text-white/60 hover:text-white">開発と反映</Link>
          <Link href="/platform/records" className="text-white/60 hover:text-white">記録</Link>
        </nav>
        <div className="ml-auto flex items-center gap-3">
          <span className="hidden text-white/50 sm:inline">{dateStr}</span>
          <span className="text-white/80">{userName}</span>
          <LogoutButton />
        </div>
      </header>

      <main className="mx-auto w-full max-w-4xl px-4 pb-[calc(120px+env(safe-area-inset-bottom))] pt-4">
        {children}
      </main>

      <PlatformDock active={active} />
    </div>
  );
}
