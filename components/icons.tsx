// 白い線だけのシンプルなアイコン（絵文字は使わない / design-guidelines 4）
// stroke=currentColor・fillなし。size は親の font-size に追従。
type P = { className?: string };
const base = {
  width: 24,
  height: 24,
  viewBox: "0 0 24 24",
  fill: "none",
  stroke: "currentColor",
  strokeWidth: 1.6,
  strokeLinecap: "round" as const,
  strokeLinejoin: "round" as const,
};

export const IconHome = (p: P) => (
  <svg {...base} className={p.className}><path d="M3 10.5 12 3l9 7.5" /><path d="M5 9.5V21h14V9.5" /><path d="M9.5 21v-6h5v6" /></svg>
);
export const IconBell = (p: P) => (
  <svg {...base} className={p.className}><path d="M6 9a6 6 0 1 1 12 0c0 5 2 6 2 6H4s2-1 2-6Z" /><path d="M10 20a2 2 0 0 0 4 0" /></svg>
);
export const IconStore = (p: P) => (
  <svg {...base} className={p.className}><path d="M4 9.5 5.5 4h13L20 9.5" /><path d="M4 9.5a2.5 2.5 0 0 0 5 0 2.5 2.5 0 0 0 5 0 2.5 2.5 0 0 0 5 0" /><path d="M5 11v9h14v-9" /><path d="M9.5 20v-5h5v5" /></svg>
);
export const IconPeople = (p: P) => (
  <svg {...base} className={p.className}><circle cx="9" cy="8" r="3" /><path d="M3.5 19a5.5 5.5 0 0 1 11 0" /><path d="M16 6.2a3 3 0 0 1 0 5.6" /><path d="M16.5 14.2A5.5 5.5 0 0 1 20.5 19" /></svg>
);
export const IconReport = (p: P) => (
  <svg {...base} className={p.className}><path d="M6 3h9l4 4v14H6Z" /><path d="M15 3v4h4" /><path d="M9 12h7M9 15.5h7M9 8.5h3" /></svg>
);
export const IconChart = (p: P) => (
  <svg {...base} className={p.className}><path d="M4 4v16h16" /><path d="M8 16v-4M12 16v-7M16 16v-3" /></svg>
);
export const IconYen = (p: P) => (
  <svg {...base} className={p.className}><circle cx="12" cy="12" r="9" /><path d="M8.5 8 12 12l3.5-4M12 12v5M9.5 13.5h5M9.5 15.5h5" /></svg>
);
export const IconRecruit = (p: P) => (
  <svg {...base} className={p.className}><circle cx="10" cy="8" r="3" /><path d="M4.5 19a5.5 5.5 0 0 1 11 0" /><path d="M18 8v6M15 11h6" /></svg>
);
export const IconGear = (p: P) => (
  <svg {...base} className={p.className}><circle cx="12" cy="12" r="3" /><path d="M12 2.5v2.2M12 19.3v2.2M4.6 7l1.9 1.1M17.5 15.9l1.9 1.1M4.6 17l1.9-1.1M17.5 8.1l1.9-1.1" /></svg>
);
export const IconLogout = (p: P) => (
  <svg {...base} className={p.className}><path d="M15 4h3a1 1 0 0 1 1 1v14a1 1 0 0 1-1 1h-3" /><path d="M10 12H3M6 8l-3 4 3 4" /></svg>
);
export const IconBuildings = (p: P) => (
  <svg {...base} className={p.className}><path d="M3 21h18" /><path d="M5 21V7l6-3v17" /><path d="M11 21V9l8 3v9" /><path d="M8 9v0M8 13v0M8 17v0M15 14v0M15 18v0" /></svg>
);
export const IconRocket = (p: P) => (
  <svg {...base} className={p.className}><path d="M5 15c-1.5 1.5-2 5-2 5s3.5-.5 5-2" /><path d="M9 11a9 9 0 0 1 9-9c.5 2.5-.5 6-4 9-2 1.7-4 2.5-5 3l-2-2c.5-1 1.3-3 2-4Z" /><circle cx="15" cy="8" r="1.3" /></svg>
);
export const IconHistory = (p: P) => (
  <svg {...base} className={p.className}><path d="M3.5 12a8.5 8.5 0 1 0 2.6-6.1" /><path d="M5 3v4h4" /><path d="M12 8v4l3 2" /></svg>
);
export const IconDoor = (p: P) => (
  <svg {...base} className={p.className}><path d="M14 3H6v18h8" /><path d="M14 3l4 2v14l-4 2V3Z" /><path d="M11 12v0" /></svg>
);
