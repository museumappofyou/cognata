"use client";

import Link from "next/link";
import { useEffect, useState } from "react";
import {
  checkGuess,
  loadRecord,
  puzzleFor,
  recordResult,
  shareText,
  type DailyRecord,
  type Puzzle,
} from "@/lib/cognata";

type Phase = "playing" | "won" | "lost" | "already";

export default function DailyPage() {
  const [puzzle, setPuzzle] = useState<Puzzle | null>(null);
  const [number, setNumber] = useState(0);
  const [phase, setPhase] = useState<Phase>("playing");
  const [guesses, setGuesses] = useState<string[]>([]);
  const [input, setInput] = useState("");
  const [record, setRecord] = useState<DailyRecord | null>(null);
  const [shared, setShared] = useState(false);
  const [error, setError] = useState("");

  useEffect(() => {
    const { puzzle: p, number: n } = puzzleFor();
    setPuzzle(p);
    setNumber(n);
    const rec = loadRecord();
    setRecord(rec);
    if (rec) {
      const today = new Date().toISOString().slice(0, 10);
      const g = rec.results[today];
      if (g !== undefined) {
        setPhase(g === 0 ? "already" : "won");
        setGuesses(new Array(g === 0 ? 3 : g).fill("•"));
      }
    }
  }, []);

  if (!puzzle) {
    return (
      <div className="flex min-h-[40vh] items-center justify-center text-faded">
        Opening today&apos;s cipher…
      </div>
    );
  }

  const submit = () => {
    const guess = input.trim();
    if (!guess) return;
    if (!/^[A-Za-zÀ-ÿ' -]+$/.test(guess)) {
      setError("Letters only.");
      return;
    }
    setError("");
    const next = [...guesses, guess];
    setGuesses(next);
    setInput("");

    if (checkGuess(puzzle, guess)) {
      setPhase("won");
      setRecord(recordResult(next.length));
    } else if (next.length >= 3) {
      setPhase("lost");
      setRecord(recordResult(0));
    }
  };

  const hintsShown = phase === "playing" ? guesses.length : 3;

  const share = async () => {
    const today = new Date().toISOString().slice(0, 10);
    const stored = record?.results[today];
    const used =
      stored !== undefined ? stored : guesses.length > 0 ? guesses.length : 3;
    const text = shareText(number, phase === "lost" ? 0 : used);
    try {
      await navigator.clipboard.writeText(text);
      setShared(true);
      setTimeout(() => setShared(false), 2000);
    } catch {
      setError("Couldn't reach the clipboard — select and copy manually.");
    }
  };

  return (
    <div className="mx-auto flex max-w-xl flex-col gap-6">
      <header className="text-center">
        <div className="text-xs uppercase tracking-[0.3em] text-faded">
          Cognata #{number}
        </div>
        <h1 className="font-display mt-1 text-4xl font-bold">The Daily Cognate</h1>
      </header>

      <section className="card rounded-xl p-6 text-center">
        <div className="text-sm text-faded">Today&apos;s mystery word, in</div>
        <div className="text-xs uppercase tracking-[0.25em] text-gold">{puzzle.source}</div>
        <div className="font-display my-4 text-5xl font-bold tracking-wide">
          {puzzle.word}
        </div>
        <p className="text-sm text-faded">Guess the modern English cousin — 3 tries.</p>
      </section>

      {/* guesses so far */}
      <section className="flex flex-col gap-2">
        {guesses.map((g, i) => {
          const correct = phase === "won" && i === guesses.length - 1 && g !== "•";
          return (
            <div
              key={i}
              className={`flex items-center justify-center gap-2 rounded-lg border-2 px-4 py-2 ${
                correct
                  ? "border-green-700 bg-green-50"
                  : g === "•"
                    ? "border-[#d8cdb4] bg-paper text-faded"
                    : "border-[#8c2f22]/30 bg-[#8c2f22]/5"
              }`}
            >
              <span className="font-display text-xl font-bold uppercase">{g}</span>
              <span className="text-sm">{correct ? "✓ cognate!" : "✗"}</span>
            </div>
          );
        })}
      </section>

      {/* hints */}
      {hintsShown > 0 && phase !== "won" && (
        <section className="flex flex-col gap-2">
          {puzzle.hints.slice(0, hintsShown).map((h, i) => (
            <div
              key={i}
              className="rounded-lg bg-paper px-4 py-3 text-sm leading-relaxed text-faded"
            >
              <span className="mr-2 font-semibold text-gold">Hint {i + 1}:</span>
              {h}
            </div>
          ))}
        </section>
      )}

      {/* input */}
      {phase === "playing" && (
        <section className="flex gap-2">
          <input
            value={input}
            onChange={(e) => setInput(e.target.value)}
            onKeyDown={(e) => e.key === "Enter" && submit()}
            autoFocus
            placeholder="Your English guess…"
            className="card flex-1 rounded-lg px-4 py-3 uppercase outline-none focus:border-gold"
            maxLength={24}
          />
          <button
            onClick={submit}
            className="rounded-lg bg-accent px-6 py-3 font-semibold text-cream transition-transform hover:scale-105"
          >
            Decrypt
          </button>
        </section>
      )}
      {error && <p className="text-center text-sm text-accent">{error}</p>}

      {/* result */}
      {phase !== "playing" && (
        <section className="card rounded-xl p-6 text-center">
          {phase === "won" && (
            <h2 className="font-display mb-2 text-2xl font-bold text-green-800">
              🎉 Decrypted!
            </h2>
          )}
          {phase === "lost" && (
            <h2 className="font-display mb-2 text-2xl font-bold text-accent">
              The cipher wins today.
            </h2>
          )}
          {phase === "already" && (
            <h2 className="font-display mb-2 text-2xl font-bold text-faded">
              You already played today.
            </h2>
          )}
          <p className="mb-2">
            The answer:{" "}
            <span className="font-display font-bold uppercase">{puzzle.answers[0]}</span>
          </p>
          <p className="mb-4 text-sm leading-relaxed text-faded">{puzzle.fact}</p>
          {record && (
            <p className="mb-4 text-sm">
              🔥 Current streak: <strong>{record.streak}</strong>
            </p>
          )}
          <button
            onClick={share}
            className="rounded-lg bg-ink px-6 py-3 font-semibold text-cream transition-transform hover:scale-105"
          >
            {shared ? "Copied!" : "Share your result"}
          </button>
        </section>
      )}

      <p className="text-center text-sm text-faded">
        Want the full rulebook?{" "}
        <Link href="/matrix" className="text-accent underline underline-offset-4">
          Open the Decryption Matrix
        </Link>
        .
      </p>
    </div>
  );
}
