"use client";

import { track } from "@vercel/analytics";

const REPO_URL = "https://github.com/rapturt9/committed";
const DOWNLOAD_URL = "https://github.com/rapturt9/committed/releases/latest";

function DownloadButton() {
  return (
    <div className="flex flex-col items-center gap-4">
      <a
        href={DOWNLOAD_URL}
        onClick={() => track("download_dmg")}
        className="inline-flex items-center gap-3 rounded-xl bg-white px-8 py-4 text-lg font-semibold text-black transition-all hover:bg-zinc-200 hover:scale-105"
      >
        <svg className="w-6 h-6" fill="currentColor" viewBox="0 0 24 24">
          <path d="M18.71 19.5c-.83 1.24-1.71 2.45-3.05 2.47-1.34.03-1.77-.79-3.29-.79-1.53 0-2 .77-3.27.82-1.31.05-2.3-1.32-3.14-2.53C4.25 17 2.94 12.45 4.7 9.39c.87-1.52 2.43-2.48 4.12-2.51 1.28-.02 2.5.87 3.29.87.78 0 2.26-1.07 3.8-.91.65.03 2.47.26 3.64 1.98-.09.06-2.17 1.28-2.15 3.81.03 3.02 2.65 4.03 2.68 4.04-.03.07-.42 1.44-1.38 2.83M13 3.5c.73-.83 1.94-1.46 2.94-1.5.13 1.17-.34 2.35-1.04 3.19-.69.85-1.83 1.51-2.95 1.42-.15-1.15.41-2.35 1.05-3.11z"/>
        </svg>
        Download for macOS
      </a>
      <div className="flex items-center gap-4 text-sm text-zinc-500">
        <a
          href={REPO_URL}
          target="_blank"
          rel="noopener noreferrer"
          onClick={() => track("github_click")}
          className="inline-flex items-center gap-2 hover:text-zinc-300 transition-colors"
        >
          <svg className="w-4 h-4" fill="currentColor" viewBox="0 0 24 24">
            <path d="M12 0c-6.626 0-12 5.373-12 12 0 5.302 3.438 9.8 8.207 11.387.599.111.793-.261.793-.577v-2.234c-3.338.726-4.033-1.416-4.033-1.416-.546-1.387-1.333-1.756-1.333-1.756-1.089-.745.083-.729.083-.729 1.205.084 1.839 1.237 1.839 1.237 1.07 1.834 2.807 1.304 3.492.997.107-.775.418-1.305.762-1.604-2.665-.305-5.467-1.334-5.467-5.931 0-1.311.469-2.381 1.236-3.221-.124-.303-.535-1.524.117-3.176 0 0 1.008-.322 3.301 1.23.957-.266 1.983-.399 3.003-.404 1.02.005 2.047.138 3.006.404 2.291-1.552 3.297-1.23 3.297-1.23.653 1.653.242 2.874.118 3.176.77.84 1.235 1.911 1.235 3.221 0 4.609-2.807 5.624-5.479 5.921.43.372.823 1.102.823 2.222v3.293c0 .319.192.694.801.576 4.765-1.589 8.199-6.086 8.199-11.386 0-6.627-5.373-12-12-12z"/>
          </svg>
          View source on GitHub
        </a>
        <span>|</span>
        <a
          href={`${REPO_URL}/releases`}
          target="_blank"
          rel="noopener noreferrer"
          className="hover:text-zinc-300 transition-colors"
        >
          All releases
        </a>
      </div>
    </div>
  );
}

export default function Home() {
  return (
    <div className="flex flex-col min-h-screen bg-[#0a0a0f]">
      {/* Hero */}
      <main className="flex-1 flex flex-col items-center justify-center px-6 py-24">
        <div className="max-w-3xl text-center space-y-8">
          <div className="flex items-center justify-center gap-3 mb-4">
            <div className="w-12 h-12 rounded-xl bg-white/10 flex items-center justify-center">
              <svg className="w-7 h-7 text-white" fill="none" stroke="currentColor" strokeWidth={2.5} viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" d="M9 12.75L11.25 15 15 9.75M21 12c0 1.268-.63 2.39-1.593 3.068a3.745 3.745 0 01-1.043 3.296 3.745 3.745 0 01-3.296 1.043A3.745 3.745 0 0112 21c-1.268 0-2.39-.63-3.068-1.593a3.746 3.746 0 01-3.296-1.043 3.745 3.745 0 01-1.043-3.296A3.745 3.745 0 013 12c0-1.268.63-2.39 1.593-3.068a3.745 3.745 0 011.043-3.296 3.746 3.746 0 013.296-1.043A3.746 3.746 0 0112 3c1.268 0 2.39.63 3.068 1.593a3.746 3.746 0 013.296 1.043 3.745 3.745 0 011.043 3.296A3.745 3.745 0 0121 12z" />
              </svg>
            </div>
            <h1 className="text-5xl font-bold tracking-tight font-mono">committed</h1>
          </div>

          <p className="text-2xl text-zinc-400 leading-relaxed max-w-2xl mx-auto">
            Accountability you can&apos;t escape.
          </p>

          <p className="text-lg text-zinc-500 max-w-xl mx-auto leading-relaxed">
            A macOS menu bar app that blocks your screen until you make commitments,
            forces pre-mortems before you start, and forces post-mortems when you fail.
            Everything tracked with Brier scores.
          </p>

          <div className="pt-4">
            <DownloadButton />
          </div>

          <p className="text-sm text-zinc-600">
            macOS 14+ (Apple Silicon). Free and open source.
          </p>
        </div>
      </main>

      {/* Features */}
      <section className="border-t border-zinc-800 px-6 py-20">
        <div className="max-w-4xl mx-auto">
          <h2 className="text-2xl font-bold text-center mb-16 font-mono">How it works</h2>
          <div className="grid md:grid-cols-3 gap-12">
            <Feature
              title="Screen blocks"
              description="No active commitments in the next 24 hours? Full-screen overlay. You can't dismiss it without creating one, writing 3 risks, and forecasting your probability."
              icon="block"
            />
            <Feature
              title="Forced reflection"
              description="Miss a deadline, skip a habit, or fail a task? Full-screen post-mortem. What happened? What will you do differently? You can't continue until you answer."
              icon="reflect"
            />
            <Feature
              title="Brier scoring"
              description="Every commitment has a probability forecast. Your calibration is tracked over time. Are you overconfident? Underconfident? The score tells you."
              icon="score"
            />
          </div>
          <div className="grid md:grid-cols-3 gap-12 mt-16">
            <Feature
              title="Menu bar countdown"
              description="Always visible. Shows your next task with a live countdown. Second by second when you're under 30 minutes."
              icon="timer"
            />
            <Feature
              title="Unkillable"
              description="launchd keeps the app alive. Kill it, it comes back in 5 seconds. Launches at login. You opted in, now you're committed."
              icon="lock"
            />
            <Feature
              title="Integrations"
              description="Fatebook for forecasting. Apple Reminders for tasks. Streaks for habits. Obsidian for daily notes. Everything in one unified timeline."
              icon="connect"
            />
          </div>
        </div>
      </section>

      {/* The loop */}
      <section className="border-t border-zinc-800 px-6 py-20">
        <div className="max-w-3xl mx-auto">
          <h2 className="text-2xl font-bold text-center mb-12 font-mono">The commitment loop</h2>
          <div className="space-y-6">
            <Step number={1} text='Set a deadline. Forecast your P(complete). "I will ship this feature by Friday. 85%."' />
            <Step number={2} text="Write 3 risks (pre-mortem). What could blow this up? You can't skip this." />
            <Step number={3} text="A Fatebook prediction is created. An Apple Reminder is set. It's written to your Obsidian daily note." />
            <Step number={4} text="Menu bar counts down. Second by second under 30 minutes." />
            <Step number={5} text="Hit the deadline? Check it off. Miss it? Full-screen post-mortem. What happened? What did you learn?" />
            <Step number={6} text="Your Brier score updates. Over time, you learn how well you actually predict your own behavior." />
          </div>
        </div>
      </section>

      {/* Install */}
      <section className="border-t border-zinc-800 px-6 py-20">
        <div className="max-w-2xl mx-auto text-center space-y-8">
          <h2 className="text-2xl font-bold font-mono">Quick install</h2>
          <div className="grid md:grid-cols-2 gap-6">
            <div className="bg-zinc-900 rounded-xl p-6 text-left">
              <h3 className="font-semibold mb-3">Option 1: Download</h3>
              <p className="text-sm text-zinc-500 mb-4">Download the DMG, drag to Applications, done.</p>
              <a
                href={DOWNLOAD_URL}
                onClick={() => track("download_dmg_bottom")}
                className="inline-flex items-center gap-2 rounded-lg bg-white/10 px-4 py-2 text-sm font-medium hover:bg-white/20 transition-colors"
              >
                Download DMG
              </a>
            </div>
            <div className="bg-zinc-900 rounded-xl p-6 text-left">
              <h3 className="font-semibold mb-3">Option 2: Build from source</h3>
              <div className="font-mono text-sm text-zinc-400 space-y-1">
                <p>git clone {REPO_URL}.git</p>
                <p>cd committed</p>
                <p>cp .env.example .env</p>
                <p>./build.sh</p>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* Footer */}
      <footer className="border-t border-zinc-800 px-6 py-8">
        <div className="max-w-4xl mx-auto flex items-center justify-between text-sm text-zinc-600">
          <span className="font-mono">committed</span>
          <div className="flex gap-6">
            <a href={REPO_URL} target="_blank" rel="noopener noreferrer" className="hover:text-zinc-400 transition-colors">GitHub</a>
            <a href={`${REPO_URL}/releases`} target="_blank" rel="noopener noreferrer" className="hover:text-zinc-400 transition-colors">Releases</a>
          </div>
        </div>
      </footer>
    </div>
  );
}

function Feature({ title, description, icon }: { title: string; description: string; icon: string }) {
  const icons: Record<string, React.ReactNode> = {
    block: <svg className="w-6 h-6" fill="none" stroke="currentColor" strokeWidth={2} viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" d="M18.364 18.364A9 9 0 005.636 5.636m12.728 12.728A9 9 0 015.636 5.636m12.728 12.728L5.636 5.636" /></svg>,
    reflect: <svg className="w-6 h-6" fill="none" stroke="currentColor" strokeWidth={2} viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" d="M12 6.042A8.967 8.967 0 006 3.75c-1.052 0-2.062.18-3 .512v14.25A8.987 8.987 0 016 18c2.305 0 4.408.867 6 2.292m0-14.25a8.966 8.966 0 016-2.292c1.052 0 2.062.18 3 .512v14.25A8.987 8.987 0 0018 18a8.967 8.967 0 00-6 2.292m0-14.25v14.25" /></svg>,
    score: <svg className="w-6 h-6" fill="none" stroke="currentColor" strokeWidth={2} viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" d="M3 13.125C3 12.504 3.504 12 4.125 12h2.25c.621 0 1.125.504 1.125 1.125v6.75C7.5 20.496 6.996 21 6.375 21h-2.25A1.125 1.125 0 013 19.875v-6.75zM9.75 8.625c0-.621.504-1.125 1.125-1.125h2.25c.621 0 1.125.504 1.125 1.125v11.25c0 .621-.504 1.125-1.125 1.125h-2.25a1.125 1.125 0 01-1.125-1.125V8.625zM16.5 4.125c0-.621.504-1.125 1.125-1.125h2.25C20.496 3 21 3.504 21 4.125v15.75c0 .621-.504 1.125-1.125 1.125h-2.25a1.125 1.125 0 01-1.125-1.125V4.125z" /></svg>,
    timer: <svg className="w-6 h-6" fill="none" stroke="currentColor" strokeWidth={2} viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" d="M12 6v6h4.5m4.5 0a9 9 0 11-18 0 9 9 0 0118 0z" /></svg>,
    lock: <svg className="w-6 h-6" fill="none" stroke="currentColor" strokeWidth={2} viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" d="M16.5 10.5V6.75a4.5 4.5 0 10-9 0v3.75m-.75 11.25h10.5a2.25 2.25 0 002.25-2.25v-6.75a2.25 2.25 0 00-2.25-2.25H6.75a2.25 2.25 0 00-2.25 2.25v6.75a2.25 2.25 0 002.25 2.25z" /></svg>,
    connect: <svg className="w-6 h-6" fill="none" stroke="currentColor" strokeWidth={2} viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" d="M13.19 8.688a4.5 4.5 0 011.242 7.244l-4.5 4.5a4.5 4.5 0 01-6.364-6.364l1.757-1.757m9.915-3.325a4.5 4.5 0 00-1.242-7.244l-4.5-4.5a4.5 4.5 0 00-6.364 6.364l1.757 1.757" /></svg>,
  };
  return (
    <div className="space-y-3">
      <div className="w-10 h-10 rounded-lg bg-zinc-800 flex items-center justify-center text-zinc-400">{icons[icon]}</div>
      <h3 className="text-lg font-semibold">{title}</h3>
      <p className="text-zinc-500 text-sm leading-relaxed">{description}</p>
    </div>
  );
}

function Step({ number, text }: { number: number; text: string }) {
  return (
    <div className="flex gap-4 items-start">
      <div className="w-8 h-8 rounded-full bg-zinc-800 flex items-center justify-center text-sm font-mono font-bold text-zinc-400 shrink-0">{number}</div>
      <p className="text-zinc-400 leading-relaxed pt-1">{text}</p>
    </div>
  );
}
