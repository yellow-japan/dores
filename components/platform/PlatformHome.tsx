import Image from "next/image";
import Link from "next/link";

type Props = {
  userName: string;
  stats: { companies: number; developing: number; pending: number };
};

// DO'reSホーム（黒いMac風）：中央にロゴ大、下に「おかえりなさい」、数字3つ。
export default function PlatformHome({ userName, stats }: Props) {
  const nums = [
    { label: "会社", value: stats.companies, href: "/platform/companies" },
    { label: "開発中の機能", value: stats.developing, href: "/platform/deploy" },
    { label: "反映待ち", value: stats.pending, href: "/platform/deploy" },
  ];
  return (
    <div className="flex min-h-[70dvh] flex-col items-center justify-center text-center">
      <Image
        src="/dores-logo.png"
        alt="DO'reS"
        width={360}
        height={160}
        priority
        className="dores-logo-in h-auto w-[min(70vw,340px)] select-none"
      />
      <p className="dores-tagline mt-7 text-[11px] font-light uppercase tracking-[0.3em] text-white/55">
        The future starts with action.
      </p>
      <p className="mt-6 text-sm text-white/70">
        おかえりなさい、<span className="font-medium text-white">{userName}</span>さん
      </p>

      <div className="mt-10 grid w-full max-w-md grid-cols-3 gap-3">
        {nums.map((n) => (
          <Link
            key={n.label}
            href={n.href}
            className="rounded-2xl border border-white/10 bg-white/[0.03] px-3 py-4 transition hover:bg-white/[0.07]"
          >
            <div className="text-3xl font-black tabular-nums text-white">{n.value}</div>
            <div className="mt-1 text-[11px] text-white/55">{n.label}</div>
          </Link>
        ))}
      </div>
    </div>
  );
}
