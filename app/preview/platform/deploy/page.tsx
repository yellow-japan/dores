import PlatformShell from "@/components/platform/PlatformShell";
import DeployView from "@/components/platform/DeployView";

export default function Preview() {
  const layers = [
    { layer: "THINKING", label: "考える・学ぶ（THINKING）", description: "考え方をそろえる・知る・学ぶ", required: false },
    { layer: "DOING", label: "行動する（DOING）", description: "毎日の現場の行動", required: false },
    { layer: "FUTURE", label: "未来をつくる（FUTURE）", description: "数字で振り返り、次を決める", required: false },
    { layer: "FOUNDATION", label: "土台（共通）", description: "どの会社にも必ず入る共通部分", required: true },
  ];
  const features = [
    { key: "notices", name: "お知らせ", description: "全社・店舗・個人へのお知らせと確認", stage: "done", layer: "THINKING", current_version: "v1.1" },
    { key: "shifts", name: "シフト", description: "シフトの作成と共有（構想）", stage: "planning", layer: "DOING", current_version: "v0.1" },
    { key: "reports", name: "レポート", description: "月次レポート（将来）", stage: "planning", layer: "FUTURE", current_version: "v0.1" },
  ];
  const tenants = [
    { id: "t1", slug: "yellow", display_name: "yellow.inc", status: "active", stores: 4, people: 8 },
    { id: "t2", slug: "test-b", display_name: "テスト株式会社B", status: "preparing", stores: 2, people: 3 },
  ];
  const matrix = [
    { tenant_id: "t1", feature_key: "notices", state: "available", enabled_version: "v1.1" },
    { tenant_id: "t2", feature_key: "notices", state: "available", enabled_version: "v1.0" },
    { tenant_id: "t1", feature_key: "shifts", state: "preparing", enabled_version: null },
    { tenant_id: "t2", feature_key: "shifts", state: "preparing", enabled_version: null },
    { tenant_id: "t1", feature_key: "reports", state: "hidden", enabled_version: null },
    { tenant_id: "t2", feature_key: "reports", state: "hidden", enabled_version: null },
  ];
  return (
    <PlatformShell userName="小林" dateStr="11月26日(水)" active="deploy">
      <DeployView layers={layers} features={features} tenants={tenants} matrix={matrix} />
    </PlatformShell>
  );
}
