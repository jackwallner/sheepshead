# Sheepshead screenshots

The checked-in `01_onboarding.png` is a headless simulator proof capture from
the dedicated `agent-sheepshead` device. The six numbered product captures are
the release flow: Quick Session, Trump Room, Bury, Trick, Home, and Card Room.
The old source screenshots were removed because they showed the template app's
previous card domain.

For release screenshots, capture each final screen from the headless simulator
and place the 1320 x 2868 raw files in `scripts/screenshot_raw/`. Then run:

```sh
python3 scripts/appstore_screenshot_compositor.py
```

The compositor writes the App Store-ready images to
`fastlane/screenshots/en-US/`. Use the names and room labels in the compositor
as the capture order. Copying a source app's screenshots is a parity failure.
