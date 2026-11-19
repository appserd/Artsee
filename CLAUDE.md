# CLAUDE.md

## Artsee
iOS-only native SwiftUI + ARKit/RealityKit app. Free, no account, no backend — everything on-device. See `README.md` for the feature spec and build steps.

## How I work: two Macs + cloud, synced through GitHub
I switch between a Mac mini, a MacBook Air and cloud sessions. GitHub is the single source of truth for every project. I'm not a git expert: handle git for me and explain in plain words.

- **Start of every session:** if this is a git repo with a remote, run `git pull --ff-only` before anything else. If it fails (uncommitted changes or the branches diverged), stop and explain in plain words what to do.
- **Project not on GitHub yet:** offer to make it a private GitHub repo (`gh repo create --private --source=. --push`). First add a .gitignore covering: DerivedData, build, .build, Pods, xcuserdata, node_modules, .expo, .env*, *.p8, *.p12, *.mobileprovision, and any keys/ or secrets folder. Never commit API keys or certificates.
- **"save my work":** update PROGRESS.md (what we did, where we stopped, next steps), commit everything with a clear message, and push.
- **"get my latest work":** pull, then read PROGRESS.md and tell me where we left off.
- **Before a session ends with unpushed changes:** remind me to say "save my work".
- **After a meaningful chunk of work** (a feature or fix finished, or several files changed) **that isn't saved to GitHub yet:** remind me in one short line to say "save my work".
- Ask me before anything destructive: force push, reset, deleting branches or files.
