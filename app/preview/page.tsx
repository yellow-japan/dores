import { notFound } from "next/navigation";
import AppShell from "@/components/AppShell";
import HomeView from "@/components/HomeView";

// レイアウト確認・画面写真用（認証なし・サンプルデータ）。本番データは使わない。
// 本番(Vercel)では開けないように 404 にする（開発中だけ表示）。
export default function PreviewPage() {
  if (process.env.NODE_ENV === "production") notFound();
  return (
    <AppShell companyName="yellow.inc" storeName="テスト店舗A" backgroundUrl="/default-bg.jpg">
      <HomeView
        userName="テスト太郎"
        dateStr="11月23日(月)"
        greetingStr="おつかれさまです"
        unreadCount={2}
        latest={[
          { id: "1", title: "【重要】テスト全社お知らせ", is_important: true, published_at: "2026-11-23" },
          { id: "2", title: "テスト：店舗A向け", is_important: false, published_at: "2026-11-23" },
          { id: "3", title: "テスト：関東エリア向け", is_important: false, published_at: "2026-11-23" },
        ]}
      />
    </AppShell>
  );
}
