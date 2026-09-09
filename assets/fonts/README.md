# Bundled fonts

Downloaded from official Google Fonts sources on 2026-09-09:

- Google Sans Flex: https://fonts.google.com/download/list?family=Google%20Sans%20Flex
  - Variable TTF: https://fonts.gstatic.com/s/googlesansflex/v22/t5t7IQcYNIWbFgDgAAzZ34auoVyXipusfhcat2c.ttf
  - OFL.txt is the unmodified license from that download manifest.
- Outfit: https://github.com/google/fonts/tree/main/ofl/outfit
- Roboto Flex: https://github.com/google/fonts/tree/main/ofl/robotoflex

`axes.json` records SHA-256 hashes and all axes read directly from each SFNT
`fvar` table (big-endian 16.16 min/default/max). Outfit only has `wght`.
Google Sans Flex has opsz 6..144, Roboto Flex opsz 8..144; only these supported
optical-size axes are currently set explicitly, through AppTypography.
Weight uses Flutter FontWeight; no explicit wght axis overrides component weights.
All fifteen text roles use the selected family. The Default hierarchy emphasizes
display/headline weights while keeping the Material 3 body scale.

`legacy/` preserves the remaining direct GoogleFonts call sites during this
sequential migration. The 48 static Outfit, Inter, JetBrains Mono and Fira Code
variants come from Google's fonts.gstatic.com CDN; every binary was verified
against google_fonts 8.2.1's SHA-256 descriptor. `legacy/sources.json` records
URLs and hashes. The legacy OFLs come from google/fonts; Outfit shares its OFL
with the variable family. Runtime fetching is disabled globally at startup.
Future screen migrations can remove these assets once no call sites need them.
Licenses are bundled and registered with Flutter's LicenseRegistry.
