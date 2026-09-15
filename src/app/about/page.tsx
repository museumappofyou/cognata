import Link from "next/link";

export const metadata = {
  title: "About — Cognata",
};

export default function AboutPage() {
  return (
    <div className="mx-auto flex max-w-2xl flex-col gap-8">
      <header className="text-center">
        <h1 className="font-display text-4xl font-bold">About Cognata</h1>
        <p className="mt-2 font-display text-lg italic text-accent">
          Language learning is cryptography — you just need the key.
        </p>
      </header>

      <section className="card rounded-xl p-6 leading-relaxed">
        <h2 className="font-display mb-3 text-2xl font-bold">The big idea</h2>
        <p className="mb-3">
          English, German, Latin, Greek, Sanskrit and Russian are all daughters of one
          language spoken roughly 5,000 years ago: Proto-Indo-European. As the tribes
          split, each branch mutated the ancestral consonants in its own systematic,
          exceptionless way — not randomly, but by law.
        </p>
        <p className="mb-3">
          In 1822, Jacob Grimm (yes, the fairy-tale Grimm) described the most famous of
          these laws. The Germanic branch shifted <strong>p → f, t → th, k → h, d → t,
          bʰ → b</strong> — every single time. That&apos;s why Latin <em>pater</em> is
          English <em>father</em> and Latin <em>cornu</em> is English <em>horn</em>.
        </p>
        <p>
          Cognata turns those laws into a game, a cheat sheet, and a family album for
          words. No brute-force memorization — just the cipher.
        </p>
      </section>

      <section className="card rounded-xl p-6 leading-relaxed">
        <h2 className="font-display mb-3 text-2xl font-bold">What&apos;s inside</h2>
        <ul className="mb-3 list-disc space-y-2 pl-5">
          <li>
            <Link href="/daily" className="text-accent underline underline-offset-4">
              The Daily Cognate
            </Link>{" "}
            — one mystery word a day, three guesses, escalating hints.
          </li>
          <li>
            <Link href="/matrix" className="text-accent underline underline-offset-4">
              The Decryption Matrix
            </Link>{" "}
            — the ten most productive sound laws for English ↔ German and English ↔
            Spanish/Latin, with Anki export.
          </li>
          <li>
            <Link href="/tree" className="text-accent underline underline-offset-4">
              The Kinship Tree
            </Link>{" "}
            — a word&apos;s cousins across the whole family, sound law by sound law.
          </li>
        </ul>
      </section>

      <section className="card rounded-xl p-6 leading-relaxed">
        <h2 className="font-display mb-3 text-2xl font-bold">Credits & caveats</h2>
        <p className="mb-3">
          The etymologies here are curated from standard historical-linguistics references
          and the wonderful open Wiktionary etymology community. Sound laws are regular,
          but real words wander — every family tree has a borrowing or two hiding in it,
          and the notes say so where we know.
        </p>
        <p>
          Deeper data: the{" "}
          <a
            href="https://github.com/droher/etymology-db"
            className="text-accent underline underline-offset-4"
            target="_blank"
            rel="noreferrer"
          >
            etymology-db project
          </a>{" "}
          parses Wiktionary&apos;s million-plus derivation relations if you want the full
          graph.
        </p>
      </section>
    </div>
  );
}
