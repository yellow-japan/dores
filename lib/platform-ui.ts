// 画面用の小さなヘルパー（日付文字列など）
export function todayStr(): string {
  return new Intl.DateTimeFormat("ja-JP", {
    month: "long",
    day: "numeric",
    weekday: "short",
  }).format(new Date());
}
