import AppShell from "@/components/AppShell";
import HomeView from "@/components/HomeView";
import OpsBanner from "@/components/platform/OpsBanner";

// 画面写真用：DO'reS運営として会社に入っているとき（上に帯）。見本データ。
export default function PreviewOps() {
  return (
    <>
      <OpsBanner companyName="テスト株式会社B" sessionId="preview" platformUrl="/platform" />
      <AppShell companyName="テスト株式会社B" storeName="テストB店舗1" backgroundUrl="/default-bg.jpg">
        <HomeView
          userName="小林"
          dateStr="11月26日(水)"
          greetingStr="おつかれさまです"
          unreadCount={1}
          latest={[
            { id: "1", title: "テストB：全社お知らせ", is_important: true, published_at: "2026-11-26" },
          ]}
        />
      </AppShell>
    </>
  );
}
