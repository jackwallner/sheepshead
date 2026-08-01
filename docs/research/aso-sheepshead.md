# Sheepshead ASO research brief

Status: DRAFT
Working placeholder: Sheepshead Table Trainer
Final product name: Sheepshead Table Trainer
Game: Sheepshead
Slug: sheepshead
Primary storefront: en-US
Research date: 2026-07-31

Sheepshead Table Trainer is a focused practice app, not a complete multiplayer
game. The storefront should be explicit about short reps between table games.

## Product and search intent

- Product type: sheepshead practice trainer, not a complete multiplayer game
- Audience: new and returning sheepshead players who want short practice reps
- Primary outcome: improve trump recognition, picking, burying, and trick decisions
- Product promise: short, focused sheepshead drills that explain the answer
- Differentiators: room-based practice, generated hands, and mistake review

These are product hypotheses from the binary, not completed keyword research.

## Competitor evidence

| App or source | Storefront | Query or URL | Promise observed | Gap or opportunity |
| --- | --- | --- | --- | --- |
| To research | en-US | sheepshead practice | Compare trainer intent with game intent | Separate learning from play |
| To research | en-US | sheepshead trump | Compare rules and trump language | Lead with a concrete skill |
| To research | en-US | sheepshead picker | Compare novice terminology | Explain the table decision |

Before final metadata, replace every `To research` row with dated App Store
search evidence, competitor links, and a documented decision.

## Keyword map

| Term | Intent | Locale | Evidence | Decision |
| --- | --- | --- | --- | --- |
| sheepshead | game | en-US | Product category, verify demand | Candidate |
| practice | problem | en-US | Product mechanic, verify intent | Candidate |
| trump | skill | en-US | Product mechanic, verify query use | Candidate |
| picker | skill | en-US | Product mechanic, verify query use | Candidate |
| bury | skill | en-US | Product mechanic, verify query use | Candidate |

Rejected or prohibited terms:

- Competitor names, unsupported multiplayer claims, gambling language, and
  any rules or feature that the binary does not teach.

## Metadata draft

Name: Sheepshead, provisional
Subtitle: Sheepshead Practice, One Hand, provisional
Keywords: sheepshead,practice,trump,tricks,called ace,picker,partner,blind,bury,beginner,lesson,drill,rule,strategy,quiz
Description angle: short practice rooms, concrete explanations, free beginner
access, and Sheepshead+ extras. The final description needs a researched
positioning pass and native copy review.
Promotional text angle: pending launch message and release timing.

## Localization plan

| Locale | Native reviewer | Query evidence | Translation status | Approved date |
| --- | --- | --- | --- | --- |
| en-US | Jack, pending final review | This brief | provisional fallback | pending |

The current 50 locale folders are a complete fallback package for the port
proof. Each target locale needs local sheepshead vocabulary, query evidence,
native review, and a decision to translate or explicitly retain the fallback.

Fallback locales and why they are acceptable:

- All non-en-US locales are temporary English fallbacks for TestFlight and
  must be reviewed before a public release.

## Screenshot and experiment plan

- Screenshot 1 proves: a beginner can start a short practice session.
- Screenshot 2 proves: the app explains a trump, picker, bury, or trick decision.
- Screenshot 3 proves: room structure and mistake review.
- Test hypothesis: a skill-specific subtitle and first screenshot convert
  better than a generic game claim.

## Release gate

- [ ] Placeholder name and placeholder terms removed.
- [ ] Final name checked against App Store and domain availability.
- [ ] Final keyword set has dated search evidence.
- [ ] Competitor names and trademarks are absent from metadata.
- [ ] Every selected term describes a real feature or user intent.
- [ ] Target locales have native review or an explicit fallback decision.
- [ ] `validate_aso_brief.py` passes without `--allow-draft`.
- [x] `validate_metadata.py` passes for every locale in the port proof.
