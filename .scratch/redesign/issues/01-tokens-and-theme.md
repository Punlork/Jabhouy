# Step 1: Design tokens and light/dark theme

Status: open
Blocked by: none

- Replace `AppColorTheme` with the §1 tokens (Light and Dark columns) in `jabhouy_ui`; build `AppTheme.lightTheme` / `darkTheme` from them. No hard-coded colors in screens.
- Shape and size constants: radii, input 50, button 54, chip 38–40, spacing.
- Dark mode toggle in Settings keeps working.

**Done when:** both themes build from tokens only (`grep -r "Color(0x" lib packages` finds only the tokens file), and the app runs in both.
