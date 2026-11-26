import PlatformShell from "@/components/platform/PlatformShell";
import PlatformHome from "@/components/platform/PlatformHome";

// 開発中プレビュー（見本データ・Supabase不要）
export default function Preview() {
  return (
    <PlatformShell userName="小林" dateStr="11月26日(水)" active="home">
      <PlatformHome userName="小林" stats={{ companies: 2, developing: 1, pending: 1 }} />
    </PlatformShell>
  );
}
