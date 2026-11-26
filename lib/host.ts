// URL（ホスト名）→ どの画面かの対応（追加7）。
//   dores-home*        → DO'reS運営（黒い画面）
//   それ以外           → 会社アプリ（今は yellow）。将来はサブドメインから会社slugを決める。
export type HostMode =
  | { kind: "platform" }
  | { kind: "tenant"; slug: string };

export function hostMode(host: string | null | undefined): HostMode {
  const h = (host ?? "").toLowerCase();
  if (h.startsWith("dores-home")) return { kind: "platform" };
  // yellow-dores.vercel.app / dores-ruby.vercel.app / localhost など → 会社(yellow)
  return { kind: "tenant", slug: "yellow" };
}
