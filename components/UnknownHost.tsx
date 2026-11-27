// 登録のないURL（tenant_hostnames に無い）で開いたとき。入口を出さない。
export default function UnknownHost() {
  return (
    <div className="grid min-h-dvh place-items-center bg-black px-4 text-center">
      <div className="max-w-sm">
        <p className="text-xs font-bold tracking-[0.3em] text-white/40">DO&rsquo;reS</p>
        <h1 className="mt-3 text-lg font-bold text-white">このURLは登録されていません</h1>
        <p className="mt-2 text-sm text-white/55">
          正しいURLからアクセスしてください。心当たりがなければ、DO&rsquo;reS運営にお問い合わせください。
        </p>
      </div>
    </div>
  );
}
