import {
  IconHome, IconBell, IconStore, IconPeople, IconReport,
  IconChart, IconYen, IconRecruit, IconGear,
} from "@/components/icons";

export type NavItem = {
  key: string;
  label: string;
  href?: string;      // ある＝使える機能 / ない＝準備中
  Icon: (p: { className?: string }) => React.ReactElement;
  dock?: boolean;     // スマホのドックに出す（よく使う4つ）
};

// お知らせ以外は href なし＝「準備中」
export const NAV: NavItem[] = [
  { key: "home",     label: "ホーム",   href: "/",        Icon: IconHome,    dock: true },
  { key: "notices",  label: "お知らせ", href: "/notices", Icon: IconBell,    dock: true },
  { key: "store",    label: "店舗",     Icon: IconStore,   dock: true },
  { key: "people",   label: "人材",     Icon: IconPeople },
  { key: "report",   label: "日報",     Icon: IconReport },
  { key: "pl",       label: "店舗PL",   Icon: IconChart },
  { key: "labor",    label: "人件費",   Icon: IconYen },
  { key: "recruit",  label: "採用",     Icon: IconRecruit },
  { key: "settings", label: "設定",     Icon: IconGear,    dock: true },
];
