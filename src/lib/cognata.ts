import soundLaws from "@/data/soundLaws.json";
import familyTrees from "@/data/familyTrees.json";
import puzzles from "@/data/puzzles.json";

export type LawExample = { en: string; other: string };
export type SoundLaw = {
  id: string;
  pair: "en-de" | "en-es";
  rule: string;
  ipa: string;
  title: string;
  explanation: string;
  unlocks: number;
  examples: LawExample[];
};
export type TreeBranch = { lang: string; form: string; note: string };
export type FamilyTree = {
  word: string;
  proto: string;
  gloss: string;
  branches: TreeBranch[];
};
export type Puzzle = {
  id: number;
  source: string;
  word: string;
  answers: string[];
  hints: [string, string, string];
  fact: string;
};

export const LAWS = soundLaws as SoundLaw[];
export const TREES = familyTrees as FamilyTree[];
export const PUZZLES = puzzles as Puzzle[];

export const PAIRS = [
  { id: "en-de", label: "English ↔ German" },
  { id: "en-es", label: "English ↔ Spanish/Latin" },
] as const;

/** Lowercase, strip diacritics and anything that isn't a letter. */
export function normalize(s: string): string {
  return s
    .toLowerCase()
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .replace(/[^a-z]/g, "");
}

export function checkGuess(puzzle: Puzzle, guess: string): boolean {
  const g = normalize(guess);
  return puzzle.answers.some((a) => normalize(a) === g);
}

/** Days since the fixed epoch, in UTC — stable per calendar day. */
export function dayNumber(date = new Date()): number {
  const EPOCH = Date.UTC(2026, 0, 1);
  const now = Date.UTC(date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate());
  return Math.round((now - EPOCH) / 86_400_000);
}

export function todayKey(date = new Date()): string {
  return date.toISOString().slice(0, 10);
}

export function puzzleFor(date = new Date()): { puzzle: Puzzle; number: number } {
  const n = dayNumber(date);
  const idx = ((n % PUZZLES.length) + PUZZLES.length) % PUZZLES.length;
  return { puzzle: PUZZLES[idx], number: n + 1 };
}

export type DailyRecord = {
  lastPlayed: string;
  streak: number;
  /** date key -> guesses used (1–3) or 0 for a miss */
  results: Record<string, number>;
};

const STORAGE_KEY = "cognata-record-v1";

export function loadRecord(): DailyRecord | null {
  if (typeof window === "undefined") return null;
  try {
    const raw = window.localStorage.getItem(STORAGE_KEY);
    return raw ? (JSON.parse(raw) as DailyRecord) : null;
  } catch {
    return null;
  }
}

export function saveRecord(r: DailyRecord) {
  try {
    window.localStorage.setItem(STORAGE_KEY, JSON.stringify(r));
  } catch {
    /* private mode etc. */
  }
}

/** Record a finished game and update the streak. */
export function recordResult(guessesUsed: number, date = new Date()): DailyRecord {
  const key = todayKey(date);
  const prev = loadRecord() ?? { lastPlayed: "", streak: 0, results: {} };
  if (prev.results[key] !== undefined) return prev;

  const y = new Date(date);
  y.setUTCDate(y.getUTCDate() - 1);
  const playedYesterday = prev.results[todayKey(y)] !== undefined;
  const streak = playedYesterday ? prev.streak + 1 : 1;

  const rec: DailyRecord = {
    lastPlayed: key,
    streak,
    results: { ...prev.results, [key]: guessesUsed },
  };
  saveRecord(rec);
  return rec;
}

export function shareText(number: number, guessesUsed: number): string {
  const squares = guessesUsed === 0 ? "⬛⬛⬛" : "🟩".repeat(guessesUsed) + "⬛".repeat(3 - guessesUsed);
  const tail = guessesUsed === 0 ? "defeated by a sound law" : `solved in ${guessesUsed} ${guessesUsed === 1 ? "guess" : "guesses"}`;
  return `Cognata #${number} ${squares}\n${tail}. Play the Daily Cognate — cognata.app/daily`;
}

/** Build an Anki-importable TSV (front: foreign word, back: English + rule). */
export function buildAnkiExport(pairId: string): string {
  const laws = LAWS.filter((l) => l.pair === pairId);
  const rows: string[] = [];
  for (const law of laws) {
    for (const ex of law.examples) {
      rows.push(`${ex.other}\t${ex.en} — rule: ${law.rule}`);
    }
  }
  return rows.join("\n");
}

export function downloadText(filename: string, text: string) {
  const blob = new Blob([text], { type: "text/tab-separated-values" });
  const url = URL.createObjectURL(blob);
  const a = document.createElement("a");
  a.href = url;
  a.download = filename;
  a.click();
  URL.revokeObjectURL(url);
}
