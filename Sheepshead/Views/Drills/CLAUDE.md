# Swipe deck invariants

`FlashcardDrillView` is a swipe deck. Tap flips a card. A flipped card can be
swiped right for "got it" or left for "again". A pre-flip drag rubber-bands
instead of grading. Undo returns the most recent card to the front.

Cards with a `CardChoice` show two answer buttons on the front. Selecting an
answer grades the choice, flips to the explanation, and keeps the result on
screen until the player taps Next. A swipe must not override a selected
answer.

The deck uses one `DragGesture(minimumDistance: 0)`. A release under 10 points
is the flip action. Do not replace it with a separate tap gesture because
SwiftUI gesture arbitration can prevent the flip from firing.

The whole card rotates as one unit. `FlipRotation` swaps the face at 90
degrees while the card is edge-on. Keep both faces inside `SheepsheadCardFace`
so the border, watermark, and text never detach from the card during rotation.

Keep the model and content domain-neutral where possible. Card rendering belongs
in `PlayingCardView`; this screen owns gesture state, grading, and deck state.
