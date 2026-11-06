# Project documentation

Developer notes and historical audits for this repository. The published site remains in the docs directory.

## Audits

- [audit823.md](audits/audit823.md): Sheepshead audit823
- [ios27Sheepshead.md](audits/ios27Sheepshead.md): iOS 27 compatibility audit: Sheepshead Trainer
- [card-app-audit-2026-10-20.md](audits/card-app-audit-2026-10-20.md): card-app audit against Mahj, features added
- [state-machines-2026-11-06.md](audits/state-machines-2026-11-06.md): state machine audit, 2 proved bugs (flashcard Undo, Fix My Mistakes Close), 4 code path; repro in `state-machines-2026-11-06-repro.swift`
- [state-machines-2026-11-06-review.md](audits/state-machines-2026-11-06-review.md): independent review of that audit: 1 confirmed (lapsed game night reminder), 1 minor (Undo), 3 not a bug, 1 unverified
