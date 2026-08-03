## x0c

Context and harness engineering for coding agents — what goes into the window, what the agent is allowed to call, and what happens when it gets something wrong.

Most of what I publish started as a fix for something that broke in my own daily agent setup.

**Context** — what the agent knows

- **[doc-skills](https://github.com/x0c/doc-skills)** — bootstrap, compact and maintain project docs an agent can actually read
- **[agentsync](https://github.com/x0c/agentsync)** — one source of truth for agent instructions and skills, synced across tools · Go

**Harness** — what the agent can reach, and what stops it

- **[agent-friendly-cli-skill](https://github.com/x0c/agent-friendly-cli-skill)** — designing CLIs agents call reliably: non-interactive modes, JSON output contracts, layered exit codes, dry-run, idempotency
- **[subswap](https://github.com/x0c/subswap)** — quota-aware account switching for Claude, Codex and ChatGPT · Rust
- **[pickup](https://github.com/x0c/pickup)** — session pickup and handoff across Claude Code and Codex CLI · Python

**Skills** — reusable capability, packaged

- **[image-assets-skill](https://github.com/x0c/image-assets-skill)** — background removal, cutouts, compression, app icons
- **[ui-prototyper-skill](https://github.com/x0c/ui-prototyper-skill)** — product ideas into high-fidelity UI prototypes

**macOS**

- **[NeatEditor](https://github.com/NeatEditor/NeatEditor)** — fast-launching, distraction-free plain text editor · SwiftUI + AppKit
- **[Mirror](https://github.com/x0c/Mirror)** — menu-bar camera mirror with floating preview
- **[OpenInput](https://github.com/x0c/OpenInput)** — floating input panel for awkward single-line fields

Go · Rust · Swift · Python · TypeScript
