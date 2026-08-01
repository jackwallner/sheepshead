# Sheepshead Trainer: Trump Play ASO research brief

Status: FINAL
Name review: final
Final product name: Sheepshead Trainer: Trump Play
Installed display name: Sheepshead Trainer
Game: Sheepshead
Slug: sheepshead
Primary storefront: en-US
Research date: 2026-08-01

Sheepshead Trainer is a focused learning companion, not a complete
multiplayer game. The listing should distinguish short decision practice from
the established apps that simulate full Sheepshead games.

## Product and search intent

- Product type: Sheepshead practice trainer
- Audience: new and returning Sheepshead players who want short practice reps
- Primary outcome: improve trump recognition, picking, burying, and trick decisions
- Product promise: short, focused Sheepshead drills that explain the answer
- Differentiators: room-based practice, generated hands, and mistake review
- Naming decision: use the fleet's Trainer naming pattern and a short skill
  phrase so a player can tell this is a learning product, not another full
  table simulation

## Competitor evidence

Search evidence reviewed 2026-08-01:

| App or source | Storefront | Promise observed | Gap or opportunity |
| --- | --- | --- | --- |
| [Sheepshead](https://apps.apple.com/us/app/sheepshead/id878817235) | en-US | Single-player trick-taking game with computer opponents, variants, tournaments, and statistics | Lead with practice and explanations instead of a full game claim |
| [Sheepshead, the App](https://apps.apple.com/us/app/sheepshead-the-app/id1339318972) | en-US | Full game with computer AI, three to five handed modes, tournaments, and partner variants | Own the between-games learning use case |
| [Granny Hand, Sheepshead](https://apps.apple.com/us/app/granny-hand-sheepshead/id6756193664) | en-US | Four-handed game with CPU opponents, stats, and game history | Avoid competing on simulated opponents; emphasize skill drills |
| [Sheepshead Scorer](https://apps.apple.com/us/app/id434548682) | en-US | Scoring, standings, hand history, and player management | Teach decisions rather than track a live table |

The search results were dominated by generic game and scoring products. No
result reviewed used Sheepshead Trainer: Trump Play as its product name. The name
is descriptive, fits the 30-character limit, and makes the product boundary
clear.

## Keyword map

| Term | Intent | Locale | Evidence | Decision |
| --- | --- | --- | --- | --- |
| sheepshead | game | en-US | Present in every relevant App Store result | Include in name and keywords |
| practice | problem | en-US | Separates this product from full game results | Include in name and keywords |
| trainer | product | en-US | Describes the learning format | Include in name and keywords |
| trump | skill | en-US | Core room and common player vocabulary | Include in subtitle and keywords |
| tricks | skill | en-US | Core room and search language in competitor listings | Include in subtitle and keywords |
| picker | skill | en-US | Core five-player decision | Include in keywords |
| bury | skill | en-US | Core eight-card scenario | Include in subtitle and keywords |
| called ace | rule | en-US | Core partner rule taught in the app | Include in keywords |

Rejected or prohibited terms:

- Competitor names, unsupported multiplayer claims, gambling language, and any
  rule or feature that the binary does not teach.

## Store metadata

Name: Sheepshead Trainer: Trump Play
Subtitle: Learn Trump, Bury, and Tricks
Keywords: sheepshead,practice,trainer,trump,tricks,picker,bury,called ace,partner,blind,learn,quiz,lesson
Description angle: short practice rooms, concrete explanations, free beginner
access, and Sheepshead+ extras.
Promotional text angle: practice the decisions that make the next Sheepshead
deal easier.

## Localization plan

| Locale group | Decision | Reason |
| --- | --- | --- |
| en-US | Final reviewed copy | Primary launch storefront and source of truth |
| Other supported ASC locales | English fallback copy uploaded | The product is not yet natively reviewed in those locales; English fallback is explicit and must be replaced before localized marketing |

The repository contains complete fallback folders for all 50 supported ASC
locales. The fallback copy uses the final name, final URLs, and the same
subscription disclosures in every locale.

## Screenshot and experiment plan

- Screenshot 1 proves: a beginner can start a short practice session.
- Screenshot 2 proves: the app explains a trump or card-reading decision.
- Screenshot 3 proves: the app teaches the picker and bury tradeoff.
- Screenshot 4 proves: the app teaches trick play.
- Screenshot 5 proves: the four-room practice structure.
- Screenshot 6 proves: the beginner card primer.
- Test hypothesis: a skill-specific name and first screenshot convert better
  than a generic claim that this is another Sheepshead game.

## Release gate

- [x] Final name selected from current App Store search evidence.
- [x] Final name fits the App Store 30-character limit.
- [x] Competitor names and trademarks are absent from metadata.
- [x] Every selected term describes a real feature or player intent.
- [x] Non-English locales have an explicit English fallback decision.
- [x] `validate_aso_brief.py` passes without `--allow-draft`.
- [x] `validate_metadata.py` passes for every supported locale.
