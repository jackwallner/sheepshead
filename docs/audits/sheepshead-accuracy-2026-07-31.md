# Sheepshead content audit

This audit records the domain conversion from the source training app.

## Verified model

- Common five-player Sheepshead uses a 32-card deck: 7 through ace in four
  suits, with six cards dealt to each player and a two-card blind.
- Every queen, every jack, and every diamond is trump. Point values are ace 11,
  10 worth 10, king 4, queen 3, jack 2, and 7 through 9 worth 0, for 120
  points total.
- The beginner model teaches picking, called-ace partnership, burying two
  cards, following suit, trump order, trick control, and the 61-point target.
- Authored hand-match questions show distinct cards from the Sheepshead deck.
- Authored bury scenarios show eight-card holdings and recommend two cards from
  that holding.
- No authored scenario uses a joker.

## Verified product split

The unit tests cover unique IDs, valid choice indices, free room access, plus
sets, Master Tables locking, Quick Session filtering, and generated hand
ambiguity. The public App Store ID is `6796911073`, and the review funnel uses
the App Store write-review URL after the enjoyment gate.

## Remaining release checks

- Confirm house-rule wording with the rules source used for the release.
- Capture every room on `agent-sheepshead` at the final Dynamic Type sizes.
- Run the Cardport parity gate against the reference card app after every product-surface change.
