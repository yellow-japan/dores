"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { createClient } from "@/lib/supabase/client";

type Opt = { id: string; name: string };
export type NoticeFormOptions = {
  stores: Opt[];
  areas: Opt[];
  ranks: Opt[];
  people: Opt[];
};
export type NoticeTargets = {
  all: boolean;
  storeIds: string[];
  areaIds: string[];
  rankIds: string[];
  personIds: string[];
};
type Props = {
  mode: "create" | "edit";
  meId: string;
  options: NoticeFormOptions;
  initial?: {
    id: string;
    title: string;
    body: string;
    is_important: boolean;
    status: "draft" | "published" | "closed";
    targets: NoticeTargets;
  };
};

function CheckList({
  title,
  opts,
  selected,
  onToggle,
}: {
  title: string;
  opts: Opt[];
  selected: string[];
  onToggle: (id: string) => void;
}) {
  if (opts.length === 0) return null;
  return (
    <div>
      <p className="mb-1 text-xs font-bold text-white/70">{title}</p>
      <div className="flex flex-wrap gap-1.5">
        {opts.map((o) => {
          const on = selected.includes(o.id);
          return (
            <button
              key={o.id}
              type="button"
              onClick={() => onToggle(o.id)}
              className={[
                "min-h-[36px] rounded-full border px-3 text-xs font-medium transition",
                on
                  ? "border-amber-300 bg-amber-400 text-black"
                  : "border-white/20 bg-white/10 text-white/85 hover:bg-white/20",
              ].join(" ")}
            >
              {o.name}
            </button>
          );
        })}
      </div>
    </div>
  );
}

export default function NoticeForm({ mode, meId, options, initial }: Props) {
  const router = useRouter();
  const [title, setTitle] = useState(initial?.title ?? "");
  const [body, setBody] = useState(initial?.body ?? "");
  const [important, setImportant] = useState(initial?.is_important ?? false);
  const [t, setT] = useState<NoticeTargets>(
    initial?.targets ?? { all: false, storeIds: [], areaIds: [], rankIds: [], personIds: [] },
  );
  const [busy, setBusy] = useState(false);
  const [err, setErr] = useState("");

  const toggle = (key: keyof NoticeTargets) => (id: string) =>
    setT((prev) => {
      const arr = prev[key] as string[];
      return { ...prev, [key]: arr.includes(id) ? arr.filter((x) => x !== id) : [...arr, id] };
    });

  function hasTarget() {
    return (
      t.all ||
      t.storeIds.length + t.areaIds.length + t.rankIds.length + t.personIds.length > 0
    );
  }

  async function save(nextStatus: "draft" | "published" | "closed") {
    setErr("");
    if (!title.trim() || !body.trim()) return setErr("タイトルと本文を入力してください。");
    if (nextStatus !== "closed" && !hasTarget()) return setErr("対象を1つ以上選んでください。");
    setBusy(true);
    const supabase = createClient();

    const noticeFields: Record<string, unknown> = {
      title: title.trim(),
      body: body.trim(),
      is_important: important,
      status: nextStatus,
    };
    if (nextStatus === "published") noticeFields.published_at = new Date().toISOString();

    let noticeId = initial?.id;
    if (mode === "create") {
      noticeFields.created_by = meId;
      const { data, error } = await supabase
        .from("notices")
        .insert(noticeFields)
        .select("id")
        .single();
      if (error || !data) {
        setErr("保存できませんでした（権限またはネットワーク）。");
        setBusy(false);
        return;
      }
      noticeId = data.id;
    } else {
      const { error } = await supabase.from("notices").update(noticeFields).eq("id", noticeId!);
      if (error) {
        setErr("保存できませんでした。");
        setBusy(false);
        return;
      }
      // 既存の対象を無効化してから入れ直す（削除はしない＝active=false）
      await supabase.from("notice_targets").update({ active: false }).eq("notice_id", noticeId!);
    }

    // 対象を入れる
    const rows: { notice_id: string; target_type: string; target_id: string | null }[] = [];
    if (t.all) rows.push({ notice_id: noticeId!, target_type: "all", target_id: null });
    t.storeIds.forEach((id) => rows.push({ notice_id: noticeId!, target_type: "store", target_id: id }));
    t.areaIds.forEach((id) => rows.push({ notice_id: noticeId!, target_type: "area", target_id: id }));
    t.rankIds.forEach((id) => rows.push({ notice_id: noticeId!, target_type: "rank", target_id: id }));
    t.personIds.forEach((id) => rows.push({ notice_id: noticeId!, target_type: "person", target_id: id }));
    if (rows.length) await supabase.from("notice_targets").insert(rows);

    router.push(`/notices/${noticeId}`);
    router.refresh();
  }

  const field =
    "min-h-[48px] w-full rounded-xl border border-white/20 bg-white/10 px-4 text-base text-white placeholder-white/40 outline-none backdrop-blur-md focus:border-white/50";

  return (
    <div className="space-y-4 pt-2">
      <h1 className="text-xl font-bold text-white drop-shadow">
        {mode === "create" ? "お知らせを作成" : "お知らせを編集"}
      </h1>

      <div className="space-y-4 rounded-3xl border border-white/15 bg-black/35 p-4 backdrop-blur-xl">
        <label className="block">
          <span className="mb-1 block text-xs font-bold text-white/80">タイトル</span>
          <input value={title} onChange={(e) => setTitle(e.target.value)} className={field} />
        </label>
        <label className="block">
          <span className="mb-1 block text-xs font-bold text-white/80">本文</span>
          <textarea
            value={body}
            onChange={(e) => setBody(e.target.value)}
            rows={6}
            className={`${field} min-h-[140px] py-3 leading-relaxed`}
          />
        </label>
        <label className="flex min-h-[44px] w-fit cursor-pointer items-center gap-2">
          <input
            type="checkbox"
            checked={important}
            onChange={(e) => setImportant(e.target.checked)}
            className="h-5 w-5 accent-rose-500"
          />
          <span className="text-sm font-medium text-white/90">重要なお知らせにする</span>
        </label>
      </div>

      <div className="space-y-3 rounded-3xl border border-white/15 bg-black/35 p-4 backdrop-blur-xl">
        <p className="text-sm font-bold text-white">対象（組み合わせ可）</p>
        <label className="flex min-h-[44px] w-fit cursor-pointer items-center gap-2">
          <input
            type="checkbox"
            checked={t.all}
            onChange={(e) => setT((p) => ({ ...p, all: e.target.checked }))}
            className="h-5 w-5 accent-amber-400"
          />
          <span className="text-sm font-bold text-white/90">全員</span>
        </label>
        <CheckList title="ランク" opts={options.ranks} selected={t.rankIds} onToggle={toggle("rankIds")} />
        <CheckList title="店舗" opts={options.stores} selected={t.storeIds} onToggle={toggle("storeIds")} />
        <CheckList title="エリア" opts={options.areas} selected={t.areaIds} onToggle={toggle("areaIds")} />
        <CheckList title="個人" opts={options.people} selected={t.personIds} onToggle={toggle("personIds")} />
      </div>

      {err && <p className="text-sm text-rose-300">{err}</p>}

      <div className="flex flex-wrap gap-2 pb-2">
        <button
          type="button"
          disabled={busy}
          onClick={() => save("draft")}
          className="min-h-[48px] flex-1 rounded-xl border border-white/20 bg-white/10 text-sm font-bold text-white transition hover:bg-white/20 disabled:opacity-60"
        >
          下書き保存
        </button>
        <button
          type="button"
          disabled={busy}
          onClick={() => save("published")}
          className="min-h-[48px] flex-1 rounded-xl bg-amber-400 text-sm font-black text-black transition hover:bg-amber-300 disabled:opacity-60"
        >
          公開する
        </button>
        {mode === "edit" && initial?.status !== "closed" && (
          <button
            type="button"
            disabled={busy}
            onClick={() => save("closed")}
            className="min-h-[48px] rounded-xl border border-white/20 bg-white/5 px-4 text-sm font-bold text-white/80 transition hover:bg-white/15 disabled:opacity-60"
          >
            終了にする
          </button>
        )}
      </div>
    </div>
  );
}
