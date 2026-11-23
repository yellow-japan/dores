import { notFound } from "next/navigation";

// /preview 以下は開発中だけ。本番(Vercel)では 404。
export default function PreviewLayout({ children }: { children: React.ReactNode }) {
  if (process.env.NODE_ENV === "production") notFound();
  return <>{children}</>;
}
