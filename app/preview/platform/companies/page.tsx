import PlatformShell from "@/components/platform/PlatformShell";
import CompanyList from "@/components/platform/CompanyList";

export default function Preview() {
  const companies = [
    { id: "t1", slug: "yellow", display_name: "yellow.inc", status: "active", stores: 4, people: 8 },
    { id: "t2", slug: "test-b", display_name: "テスト株式会社B", status: "preparing", stores: 2, people: 3 },
  ];
  return (
    <PlatformShell userName="小林" dateStr="11月26日(水)" active="companies">
      <CompanyList
        companies={companies}
        homeTenantId="t1"
        homeHostByTenant={{ t1: "https://yellow-dores.vercel.app" }}
      />
    </PlatformShell>
  );
}
