import AppShell from "@/components/AppShell";
import NoticeForm from "@/components/notices/NoticeForm";

const options = {
  stores: [
    { id: "a", name: "テスト店舗A" },
    { id: "b", name: "テスト店舗B" },
    { id: "c", name: "テスト店舗C" },
  ],
  areas: [
    { id: "e", name: "テスト関東エリア" },
    { id: "w", name: "テスト西エリア" },
  ],
  ranks: [
    { id: "r1", name: "テストランナー" },
    { id: "r2", name: "テストエール" },
    { id: "r3", name: "テストサンメンバー" },
  ],
  people: [
    { id: "p1", name: "テスト店長A" },
    { id: "p2", name: "テスト社員" },
    { id: "p3", name: "テストアルバイト1" },
  ],
};

export default function PreviewNoticeNew() {
  return (
    <AppShell companyName="yellow.inc" storeName="テスト店舗A" backgroundUrl="/default-bg.jpg">
      <NoticeForm mode="create" meId="demo" options={options} />
    </AppShell>
  );
}
