"use client";

import Link from "next/link";
import { useEffect, useState } from "react";

const DEMO = [
  { en: "brother", other: "Bruder", law: "th → d", lang: "German" },
  { en: "water", other: "Wasser", law: "t → ss", lang: "German" },
  { en: "three", other: "tres", law: "th → t", lang: "Latin" },
  { en: "fish", other: "piscis", law: "f → p", lang: "Latin" },
  { en: "night", other: "nacht", law: "gh → ch", lang: "German" },
];

function CipherDemo() {
  const [i, setI] = useState(0);
  const [revealed, setRevealed] = useState(false);

  useEffect(() => {
    const t1 = setTimeout(() => setRevealed(true), 900);
    const t2 = setTimeout(() => {
      setRevealed(false);
      setI((v) => (v + 1) % DEMO.length);
    }, 3400);
    return () => {
      clearTimeout(t1);
      clearTimeout(t2);
    };
  }, [i]);

  const d = DEMO[i];
  return (
    <div className="card mx-auto flex max-w-md flex-col items-center gap-3 rounded-xl p-6">
      <div className="text-xs uppercase tracking-[0.25em] text-faded">the cipher</div>
      <div className="font-display flex items-center gap-4 text-3xl font-bold sm:text-4xl">
        <span key={d.en} className="flip-in">{d.en}</span>
        <span className="text-gold">→</span>
        <span
          key={d.other + (revealed ? "r" : "x")}
          className={`flip-in ${revealed ? "text-accent" : "text-faded/40 blur-[3px] select-none"}`}
        >
          {revealed ? d.other : "??????"}
        </span>
      </div>
      <div className="text-sm text-faded">
        <span className="rounded bg-paper px-2 py-1 font-mono">{d.law}</span>{" "}
        unlocks this pair in {d.lang}
      </div>
    </div>
  );
}

const PILLARS = [
  {
    href: "/daily",
    title: "The Daily Cognate",
    tag: "Play",
    desc: "A mystery word from an ancient tongue, three guesses, one sound law. New puzzle every midnight.",
  },
  {
    href: "/matrix",
    title: "The Decryption Matrix",
    tag: "Learn",
    desc: "The ten sound shifts that secretly map English onto German and Spanish — each one unlocks hundreds of words.",
  },
  {
    href: "/tree",
    title: "The Kinship Tree",
    tag: "Explore",
    desc: "Type a word — heart, night, milk — and watch its cousins bloom across fifteen languages.",
  },
];

export default function Home() {
  return (
    <div className="flex flex-col gap-16">
      <section className="flex flex-col items-center gap-8 pt-6 text-center">
        <h1 className="font-display max-w-3xl text-4xl font-bold leading-tight sm:text-5xl">
          You already know 3,000 words in German, Spanish, Italian and French.
        </h1>
        <p className="font-display max-w-2xl text-xl italic text-accent sm:text-2xl">
          You just don&apos;t know the cipher yet.
        </p>
        <p className="max-w-xl text-faded">
          Every &ldquo;foreign&rdquo; word is an English word passed through a mathematical
          sound shift. Learn ten rules and watch half a vocabulary decrypt itself.
        </p>
        <CipherDemo />
        <Link
          href="/daily"
          className="rounded-lg bg-accent px-6 py-3 font-semibold text-cream transition-transform hover:scale-105"
        >
          Play today&apos;s puzzle →
        </Link>
      </section>

      <section className="grid gap-5 sm:grid-cols-3">
        {PILLARS.map((p) => (
          <Link
            key={p.href}
            href={p.href}
            className="card group rounded-xl p-6 transition-all hover:-translate-y-1 hover:shadow-md"
          >
            <div className="mb-3 inline-block rounded-full bg-paper px-3 py-1 text-xs uppercase tracking-widest text-faded">
              {p.tag}
            </div>
            <h2 className="font-display mb-2 text-xl font-bold group-hover:text-accent">
              {p.title}
            </h2>
            <p className="text-sm leading-relaxed text-faded">{p.desc}</p>
          </Link>
        ))}
      </section>

      <section className="card rounded-xl p-8">
        <h2 className="font-display mb-4 text-2xl font-bold">How the cipher works</h2>
        <p className="mb-4 leading-relaxed">
          Around 500 BC, one tribe of Indo-European speakers underwent a systematic
          consonant cascade — <strong>Grimm&apos;s Law</strong>. Their <em>p</em>&apos;s became{" "}
          <em>f</em>&apos;s, their <em>t</em>&apos;s became <em>th</em>&apos;s, their{" "}
          <em>k</em>&apos;s became <em>h</em>&apos;s. That tribe became the Germanic peoples,
          and their language became English.
        </p>
        <p className="leading-relaxed">
          The Romans kept the original sounds. So Latin <em>pater</em> is English{" "}
          <em>father</em>, <em>tres</em> is <em>three</em>, <em>cornu</em> is <em>horn</em> —
          every single time. That&apos;s not memorization. That&apos;s cryptography.
        </p>
      </section>
    </div>
  );
}
