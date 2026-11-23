import LogoutButton from "@/components/LogoutButton";
import Dock from "@/components/Dock";

type Props = {
  companyName: string;
  storeName?: string | null;
  backgroundUrl: string;
  children: React.ReactNode;
};

// 全画面共通の枠：背景イラスト＋薄い暗い膜／上部「DO'reS｜会社名＋店舗名」／下部ドック
export default function AppShell({ companyName, storeName, backgroundUrl, children }: Props) {
  return (
    <div className="relative min-h-dvh">
      {/* 背景イラスト */}
      <div
        className="fixed inset-0 -z-10 bg-cover bg-center"
        style={{ backgroundImage: `url(${backgroundUrl})` }}
      />
      {/* 文字が読めるよう薄い暗い膜 */}
      <div className="fixed inset-0 -z-10 bg-gradient-to-b from-black/55 via-black/40 to-black/65" />

      {/* 上部バー */}
      <header className="sticky top-0 z-20 flex items-center gap-3 px-4 pt-[max(10px,env(safe-area-inset-top))] pb-2">
        <div className="flex min-h-[44px] flex-1 items-center gap-2 rounded-2xl border border-white/15 bg-black/30 px-3 backdrop-blur-xl">
          <span className="text-base font-black tracking-wide text-white">DO&rsquo;reS</span>
          <span className="text-white/40">｜</span>
          <span className="truncate text-sm font-bold text-white/90">{companyName}</span>
          {storeName && (
            <span className="ml-auto truncate rounded-full border border-white/15 bg-white/10 px-2.5 py-1 text-xs font-medium text-white/85">
              {storeName}
            </span>
          )}
        </div>
        <LogoutButton />
      </header>

      {/* 本体（下はドックに隠れないよう、ドックの高さ＋安全余白ぶん空ける） */}
      <main className="mx-auto w-full max-w-3xl px-4 pt-1 pb-[calc(130px+env(safe-area-inset-bottom))]">
        {children}
      </main>

      <Dock />
    </div>
  );
}
