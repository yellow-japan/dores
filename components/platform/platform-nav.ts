import { IconHome, IconBuildings, IconRocket, IconHistory, IconGear } from "@/components/icons";

export type PNav = {
  key: string;
  label: string;
  href: string;
  Icon: (p: { className?: string }) => React.ReactElement;
};

// DO'reS運営のドック（白い線のアイコン）
export const PLATFORM_NAV: PNav[] = [
  { key: "home", label: "ホーム", href: "/platform", Icon: IconHome },
  { key: "companies", label: "会社", href: "/platform/companies", Icon: IconBuildings },
  { key: "deploy", label: "開発と反映", href: "/platform/deploy", Icon: IconRocket },
  { key: "records", label: "記録", href: "/platform/records", Icon: IconHistory },
  { key: "settings", label: "設定", href: "/platform/settings", Icon: IconGear },
];
