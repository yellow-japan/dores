"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { createClient } from "@/lib/supabase/client";

const next: Record<string, string> = {
  available: "preparing",
  preparing: "hidden",
  hidden: "available",
};
const look: Record<string, string> = {
  available: "text-emerald-300 bg-emerald-400/10 border-emerald-400/25",
  preparing: "text-amber-300 bg-amber-400/10 border-amber-400/25",
  hidden: "text-white/45 bg-white/5 border-white/15",
};
const label: Record<string, string> = {
  available: "使える",
  preparing: "準備中",
  hidden: "出さない",
};

// 会社×機能のセル：クリックで 使える→準備中→出さない を切り替え（運営のみ・DBで保存）。
export default function FeatureCell({
  tenantId,
  featureKey,
  state,
  version,
  latest,
}: {
  tenantId: string;
  featureKey: string;
  state: string;
  version: string | null;
  latest: string;
}) {
  const router = useRouter();
  const [s, setS] = useState(state);
  const [v, setV] = useState(version);
  const [busy, setBusy] = useState(false);
  const behind = v && v !== latest;

  async function cycle() {
    const to = next[s] ?? "preparing";
    setBusy(true);
    const supabase = createClient();
    const { error } = await supabase
      .from("tenant_features")
      .update({ state: to })
      .eq("tenant_id", tenantId)
      .eq("feature_key", featureKey);
    setBusy(false);
    if (!error) {
      setS(to);
      router.refresh();
    }
  }

  async function reflect() {
    setBusy(true);
    const supabase = createClient();
    const { error } = await supabase
      .from("tenant_features")
      .update({ enabled_version: latest })
      .eq("tenant_id", tenantId)
      .eq("feature_key", featureKey);
    if (!error) {
      await supabase.from("feature_reflections").insert({
        tenant_id: tenantId,
        feature_key: featureKey,
        from_version: v,
        to_version: latest,
      });
      setV(latest);
    }
    setBusy(false);
    router.refresh();
  }

  return (
    <div className="flex items-center gap-1.5">
      <button
        type="button"
        onClick={cycle}
        disabled={busy}
        className={`rounded-lg border px-2 py-1 text-[11px] font-medium transition hover:opacity-80 ${look[s] ?? look.hidden}`}
      >
        {label[s] ?? s}
      </button>
      {v && (
        <span className="text-[10px] text-white/40">{v}</span>
      )}
      {behind && (
        <button
          type="button"
          onClick={reflect}
          disabled={busy}
          className="rounded-md border border-sky-400/30 bg-sky-400/10 px-1.5 py-0.5 text-[10px] font-bold text-sky-300 hover:bg-sky-400/20"
        >
          {latest}に反映
        </button>
      )}
    </div>
  );
}
