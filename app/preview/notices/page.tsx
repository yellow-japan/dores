import AppShell from "@/components/AppShell";
import NoticeList, { type NoticeItem } from "@/components/notices/NoticeList";

const items: NoticeItem[] = [
  { id: "1", title: "【重要】テスト全社お知らせ", is_important: true, published_at: "2026-11-23", status: "published", isRead: false },
  { id: "2", title: "テスト：店舗A向け", is_important: false, published_at: "2026-11-23", status: "published", isRead: false },
  { id: "3", title: "テスト：関東エリア向け", is_important: false, published_at: "2026-11-22", status: "published", isRead: true },
  { id: "4", title: "テスト：下書き", is_important: false, published_at: null, status: "draft", isRead: false },
];

export default function PreviewNoticesList() {
  return (
    <AppShell companyName="yellow.inc" storeName="テスト店舗A" backgroundUrl="/default-bg.jpg">
      <NoticeList items={items} isMas={true} />
    </AppShell>
  );
}
