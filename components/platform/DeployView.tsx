import FeatureCell from "@/components/platform/FeatureCell";
import type { FeatureRow, TenantRow, TenantFeatureRow, LayerRow } from "@/lib/platform";

const stageLabel: Record<string, string> = {
  planning: "計画中",
  developing: "開発中",
  testing: "テスト中",
  done: "完成",
};
const stageCls: Record<string, string> = {
  planning: "text-white/50 bg-white/5 border-white/15",
  developing: "text-sky-300 bg-sky-400/10 border-sky-400/25",
  testing: "text-violet-300 bg-violet-400/10 border-violet-400/25",
  done: "text-emerald-300 bg-emerald-400/10 border-emerald-400/25",
};

export default function DeployView({
  layers,
  features,
  tenants,
  matrix,
}: {
  layers: LayerRow[];
  features: FeatureRow[];
  tenants: TenantRow[];
  matrix: TenantFeatureRow[];
}) {
  const cell = (tid: string, key: string) =>
    matrix.find((m) => m.tenant_id === tid && m.feature_key === key);

  // 層ごとに機能をまとめる（土台は機能を持たない）
  const byLayer = layers
    .filter((l) => l.layer !== "FOUNDATION")
    .map((l) => ({ layer: l, items: features.filter((f) => f.layer === l.layer) }))
    .filter((g) => g.items.length > 0);

  return (
    <div className="space-y-6">
      <div className="flex items-baseline justify-between">
        <h1 className="text-xl font-bold text-white">開発と反映</h1>
        <span className="text-sm text-white/50">機能を会社ごとに順番に届ける</span>
      </div>

      {/* 機能の一覧（層ごと） */}
      {byLayer.map((g) => (
        <section key={g.layer.layer}>
          <div className="mb-2 flex items-center gap-2">
            <h2 className="text-sm font-bold text-white/85">{g.layer.label}</h2>
            <span className="text-xs text-white/40">{g.layer.description}</span>
          </div>
          <div className="overflow-hidden rounded-2xl border border-white/10">
            {g.items.map((f) => (
              <div key={f.key} className="border-b border-white/10 last:border-b-0">
                <div className="flex items-center gap-2 bg-white/[0.03] px-3 py-2.5">
                  <span className="font-bold text-white">{f.name}</span>
                  <span className="text-[11px] text-white/40">{f.current_version}</span>
                  <span className={`rounded-md border px-1.5 py-0.5 text-[10px] ${stageCls[f.stage]}`}>
                    {stageLabel[f.stage]}
                  </span>
                  {f.description && (
                    <span className="ml-auto hidden truncate text-xs text-white/45 sm:inline">
                      {f.description}
                    </span>
                  )}
                </div>
                {/* 会社ごとの状態 */}
                <div className="divide-y divide-white/5">
                  {tenants.map((t) => {
                    const c = cell(t.id, f.key);
                    return (
                      <div key={t.id} className="flex items-center gap-3 px-3 py-2">
                        <span className="w-28 shrink-0 truncate text-xs text-white/60">
                          {t.display_name}
                        </span>
                        {c ? (
                          <FeatureCell
                            tenantId={t.id}
                            featureKey={f.key}
                            state={c.state}
                            version={c.enabled_version}
                            latest={f.current_version}
                          />
                        ) : (
                          <span className="text-[11px] text-white/30">未設定</span>
                        )}
                      </div>
                    );
                  })}
                </div>
              </div>
            ))}
          </div>
        </section>
      ))}

      <p className="text-xs text-white/40">
        状態のボタンを押すと「使える → 準備中 → 出さない」と切り替わります（運営のみ・記録に残ります）。
        古いバージョンの会社には「{"{最新版}"}に反映」ボタンが出ます。
      </p>
    </div>
  );
}
