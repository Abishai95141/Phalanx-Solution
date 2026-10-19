# README pictures — how they are made

Every picture on the root README is generated from the running system, so the numbers match what the live app at
https://148.100.99.205 reports. Brand: white, ink `#0B0D10`, accent `#E8743B`, evidence blue `#2563C9`,
Manrope and JetBrains Mono (subset and embedded by `fonts.py`).

| Output (in `..`) | Made by | From |
|---|---|---|
| `logo-*.svg`, `hero.svg`, `problem.svg`, `impact.svg`, `live-metrics.svg` | `build_svgs.py` | `live/*.json` (API responses), `live/latency.json` |
| `tour.gif`, `screens/*.png` | `make_tour.py` | `shots/*.png` captured by `shoot_screens.sh` |
| `triage.gif`, `loop.gif` | `render_anim.py <name> <seconds>` | `anim/<name>.html` — pages that draw any time `?t=` exactly, captured frame by frame with headless Chrome |

Refresh everything (needs `proto/deploy/ssh_config`, Google Chrome, ffmpeg, Pillow and fontTools):

```bash
docs/assets/readme/src/fetch_live.sh
```

```bash
cd docs/assets/readme/src && ./shoot_screens.sh && python3 build_svgs.py && python3 make_tour.py && python3 render_anim.py triage 7 && python3 render_anim.py loop 9
```

`build/` and `shots/` are scratch and are not committed.
