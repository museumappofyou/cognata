"use client";

import { useMemo, useState } from "react";
import { TREES } from "@/lib/cognata";

const GROUPS: { name: string; color: string; langs: string[] }[] = [
  { name: "Germanic", color: "#8c2f22", langs: ["English", "German", "Dutch", "Swedish"] },
  { name: "Italic", color: "#2f5d8c", langs: ["Latin", "Spanish", "French", "Italian"] },
  { name: "Greek", color: "#6b4b8c", langs: ["Greek"] },
  { name: "Indo-Iranian", color: "#8c6b2f", langs: ["Sanskrit"] },
  { name: "Slavic", color: "#4a7c59", langs: ["Russian"] },
  { name: "Celtic", color: "#b08d3e", langs: ["Irish"] },
];

const LEAF_W = 168;
const LEAF_GAP = 12;
const ROW_H = 96;
const GROUP_GAP = 48;
const GROUP_Y = 150;
const ROOT_Y = 30;
const LEAVES_Y = 220;

function groupOf(lang: string) {
  return GROUPS.find((g) => g.langs.includes(lang));
}

function TreeSVG({ word }: { word: string }) {
  const tree = TREES.find((t) => t.word === word)!;
  const root = tree.branches.find((b) => b.lang === "Proto-Indo-European");
  const leaves = tree.branches.filter(
    (b) => b.lang !== "Proto-Indo-European" && groupOf(b.lang)
  );
  // unknown-language leaves (safety) are dropped from the drawing
  const used = GROUPS.map((g) => ({
    ...g,
    items: leaves.filter((l) => g.langs.includes(l.lang)),
  })).filter((g) => g.items.length > 0);

  const groupW = (n: number) => n * LEAF_W + (n - 1) * LEAF_GAP;
  const totalW =
    used.reduce((s, g) => s + groupW(g.items.length), 0) + GROUP_GAP * (used.length - 1);
  const maxLeaves = Math.max(...used.map((g) => g.items.length));
  const H = LEAVES_Y + maxLeaves * ROW_H + 24;

  let x = 0;
  const layout = used.map((g) => {
    const gx = x;
    const cx = gx + groupW(g.items.length) / 2;
    const items = g.items.map((item, i) => ({
      item,
      x: gx + i * (LEAF_W + LEAF_GAP),
      y: LEAVES_Y + i * ROW_H,
    }));
    x += groupW(g.items.length) + GROUP_GAP;
    return { ...g, cx, items };
  });

  const rootX = totalW / 2;

  return (
    <div className="w-full">
      <svg
        width="100%"
        viewBox={`0 0 ${totalW} ${H}`}
        preserveAspectRatio="xMidYMin meet"
        className="mx-auto block h-auto w-full max-w-[1100px]"
      >
        {/* root */}
        <g>
          <rect
            x={rootX - 130}
            y={ROOT_Y}
            width={260}
            height={58}
            rx={10}
            fill="#1f1a14"
          />
          <text x={rootX} y={ROOT_Y + 24} textAnchor="middle" fill="#faf6ee" fontSize={13} fontWeight={700} fontFamily="var(--font-merriweather), Georgia, serif">
            {root?.form ?? "Proto-Indo-European"}
          </text>
          <text x={rootX} y={ROOT_Y + 44} textAnchor="middle" fill="#d8cdb4" fontSize={11} fontStyle="italic" fontFamily="var(--font-merriweather), Georgia, serif">
            {word} · {tree.gloss}
          </text>
        </g>

        {layout.map((g) => (
          <g key={g.name}>
            {/* root → group */}
            <path
              d={`M ${rootX} ${ROOT_Y + 58} C ${rootX} ${GROUP_Y - 30}, ${g.cx} ${GROUP_Y - 60}, ${g.cx} ${GROUP_Y}`}
              stroke="#d8cdb4"
              fill="none"
              strokeWidth={2}
            />
            {/* group node */}
            <rect
              x={g.cx - 62}
              y={GROUP_Y}
              width={124}
              height={34}
              rx={17}
              fill="#f3ecdd"
              stroke={g.color}
              strokeWidth={2}
            />
            <text x={g.cx} y={GROUP_Y + 22} textAnchor="middle" fill={g.color} fontSize={13} fontWeight={700}>
              {g.name}
            </text>
            {/* group → leaves */}
            {g.items.map(({ item, x, y }) => (
              <g key={item.lang}>
                <path
                  d={`M ${g.cx} ${GROUP_Y + 34} C ${g.cx} ${y - 40}, ${x + LEAF_W / 2} ${y - 60}, ${x + LEAF_W / 2} ${y}`}
                  stroke="#d8cdb4"
                  fill="none"
                  strokeWidth={2}
                />
                <foreignObject x={x} y={y} width={LEAF_W} height={ROW_H - 12}>
                  <div className="card flex h-full flex-col justify-center rounded-lg px-3 py-2">
                    <div className="text-[10px] uppercase tracking-widest text-faded">
                      {item.lang}
                    </div>
                    <div className="font-display text-lg font-bold leading-tight" style={{ color: g.color }}>
                      {item.form}
                    </div>
                    <div className="text-[10px] leading-snug text-faded">{item.note}</div>
                  </div>
                </foreignObject>
              </g>
            ))}
          </g>
        ))}
      </svg>
    </div>
  );
}

export default function TreePage() {
  const [q, setQ] = useState("");
  const [word, setWord] = useState("heart");

  const matches = useMemo(() => {
    const needle = q.trim().toLowerCase();
    if (!needle) return TREES.map((t) => t.word);
    return TREES.filter(
      (t) =>
        t.word.includes(needle) ||
        t.branches.some(
          (b) =>
            b.form.toLowerCase().includes(needle) ||
            b.lang.toLowerCase().includes(needle)
        )
    ).map((t) => t.word);
  }, [q]);

  return (
    <div className="flex flex-col gap-8">
      <header className="text-center">
        <h1 className="font-display mb-2 text-4xl font-bold">The Kinship Tree</h1>
        <p className="text-faded">
          Pick a word and watch its cousins bloom across the Indo-European family.
        </p>
      </header>

      <div className="mx-auto flex w-full max-w-xl flex-col gap-3">
        <input
          value={q}
          onChange={(e) => setQ(e.target.value)}
          placeholder="Try: heart, night, milk, tooth, ghost…"
          className="card w-full rounded-lg px-4 py-3 outline-none focus:border-gold"
        />
        <div className="flex flex-wrap justify-center gap-2">
          {matches.map((w) => (
            <button
              key={w}
              onClick={() => setWord(w)}
              className={`rounded-full px-4 py-1.5 text-sm font-semibold transition-colors ${
                word === w ? "bg-ink text-cream" : "bg-paper text-faded hover:text-ink"
              }`}
            >
              {w}
            </button>
          ))}
          {matches.length === 0 && (
            <p className="text-sm text-faded">
              No tree for that yet — {TREES.length} words are mapped so far.
            </p>
          )}
        </div>
      </div>

      {matches.includes(word) ? (
        <TreeSVG word={word} />
      ) : matches.length > 0 ? (
        <TreeSVG word={matches[0]} />
      ) : null}
    </div>
  );
}
