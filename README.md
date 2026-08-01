# Sheepshead Trainer

Sheepshead is a five-minute practice app for the common five-player
Sheepshead variant. It teaches trump, point values, picking, partner play,
burying, and trick decisions. It is an independent practice companion, not a
complete multiplayer game.

## Product identity

- Display name: Sheepshead Trainer
- App Store name: Sheepshead Trainer: Trump Play
- Bundle ID: `com.jackwallner.sheepshead`
- App Store ID: `6796913227`
- Marketing version: `1.0`
- Public site: <https://jackwallner.github.io/sheepshead/>
- Support: <https://jackwallner.github.io/sheepshead/support>
- Privacy: <https://jackwallner.github.io/sheepshead/privacy-policy>
- Terms: <https://jackwallner.github.io/sheepshead/terms>
- Membership: Sheepshead+

## Development

```sh
xcodegen generate
python3 scripts/validate_metadata.py
xcodebuild -project Sheepshead.xcodeproj -scheme Sheepshead \
  -destination 'platform=iOS Simulator,id=<agent-sheepshead-udid>' \
  test CODE_SIGNING_ALLOWED=NO
```

Use the dedicated headless simulator `agent-sheepshead`. Never open
Simulator.app. Simulator builds must not configure the production RevenueCat
key.

## Release

Read [docs/asc-submission-checklist.md](docs/asc-submission-checklist.md), then
use the scripts in `scripts/` for the App Store Connect metadata, products,
readiness, screenshots, and TestFlight workflow. Do not submit for App Review
automatically.

The App Privacy answers are stored in
`fastlane/app_privacy_details.json`. Upload them with
`./scripts/upload-app-privacy.sh` when `FASTLANE_SESSION` is available.

Before public metadata changes, complete the ASO brief in
`docs/research/aso-sheepshead.md` and run:

```sh
python3 scripts/validate_aso_brief.py \
  --brief docs/research/aso-sheepshead.md \
  --product-name "Sheepshead Trainer: Trump Play"
```

## Reusable port workflow

The source template and complete end-to-end porting instructions live in
`/Users/jackwallner/cardport`. Start with its README and parity contract. The
`.cardport.json` file records public identity values for this port. The parity
reference is the original tile-practice app, and the port keeps its runtime,
release, website, legal, and screenshot surfaces while replacing tile content
with Sheepshead rules and cards.
