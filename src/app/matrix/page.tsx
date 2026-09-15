"use client";

import { useState } from "react";
import { LAWS, PAIRS, buildAnkiExport, downloadText } from "@/lib/cognata";

export default function MatrixPage() {
  const [pair, setPair] = useState<"en-de" | "en-es">("en-de");
  const [open, setOpen] = useState<string | null>(LAWS[0].id);

  const laws = LAWS.filter((l) => l.pair === pair);
  const totalUnlocked = laws.reduce((s, l) => s + l.unlocks, 0);
  const pairExamples = laws.flatMap((l) => l.examples);

  return (
    <div className="flex flex-col gap-8">
      <header className="text-center">
        <h1 className="font-display mb-2 text-4xl font-bold">The Decryption Matrix</h1>
        <p className="text-faded">
          Learn {laws.length} rules, unlock ~{totalUnlocked.toLocaleString()} words overnight.
        </p>
      </header>

      <div className="flex justify-center gap-2">
        {PAIRS.map((p) => (
          <button
            key={p.id}
            onClick={() => setPair(p.id)}
            className={`rounded-full px-5 py-2 text-sm font-semibold transition-colors ${
              pair === p.id
                ? "bg-ink text-cream"
                : "bg-paper text-faded hover:text-ink"
            }`}
          >
            {p.label}
          </button>
        ))}
      </div>

      <div className="flex flex-col gap-4">
        {laws.map((law, idx) => {
          const expanded = open === law.id;
          return (
            <div key={law.id} className="card overflow-hidden rounded-xl">
              <button
                onClick={() => setOpen(expanded ? null : law.id)}
                className="flex w-full items-center gap-4 p-5 text-left"
              >
                <span className="font-display w-8 shrink-0 text-2xl font-bold text-gold">
                  {String(idx + 1).padStart(2, "0")}
                </span>
                <span className="flex-1">
                  <span className="font-display block text-lg font-bold">
                    {law.title}
                  </span>
                  <span className="text-sm text-faded">
                    {law.rule} · {law.ipa}
                  </span>
                </span>
                <span className="shrink-0 rounded-full bg-paper px-3 py-1 text-xs font-semibold text-faded">
                  🔓 ~{law.unlocks.toLocaleString()} words
                </span>
                <span className={`shrink-0 text-faded transition-transform ${expanded ? "rotate-90" : ""}`}>
                  ▸
                </span>
              </button>

              {expanded && (
                <div className="border-t border-[#eee5d2] px-5 pb-5 pt-4">
                  <p className="mb-4 text-sm leading-relaxed text-faded">{law.explanation}</p>
                  <div className="grid gap-2 sm:grid-cols-2">
                    {law.examples.map((ex, i) => (
                      <div
                        key={i}
                        className="flex items-baseline justify-between rounded-lg bg-paper px-4 py-2"
                      >
                        <span className="font-semibold">{ex.other}</span>
                        <span className="mx-2 text-gold">↔</span>
                        <span className="font-semibold">{ex.en}</span>
                      </div>
                    ))}
                  </div>
                </div>
              )}
            </div>
          );
        })}
      </div>

      <div className="card flex flex-col items-center gap-3 rounded-xl p-6 text-center">
        <p className="text-sm text-faded">
          Export all {pairExamples.length} pairs as an Anki-ready deck — cards grouped by
          sound law, not by topic, because your brain remembers the rule, not the list.
        </p>
        <button
          onClick={() => {
            downloadText(`cognata-${pair}-deck.tsv`, buildAnkiExport(pair));
          }}
          className="rounded-lg bg-ink px-6 py-3 font-semibold text-cream transition-transform hover:scale-105"
        >
          ⬇ Export {pairExamples.length} cards to Anki (TSV)
        </button>
        <p className="text-xs text-faded">
          In Anki: File → Import → choose the file, tab-separated. Done.
        </p>
      </div>
    </div>
  );
}
