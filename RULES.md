# Phalanx Twin — working rules

**Smart India Hackathon 2026** entry by **Team Circuit_breakers_SE**, for **PS 26249** **"Air Power – Predictive Maintenance & Fleet Availability"**
(Ministry of Defence / Defence Services Staff College).
GitHub: https://github.com/Abishai95141/Phalanx-Solution · live prototype: https://148.100.99.205/ (hosted in IBM Cloud)

This repo builds the **downstream PdM + fleet-availability solution, "Phalanx Twin"**, and runs it end to end on
one cloud server. It sits on top of the team's separate **Phalanx data layer** — a deterministic,
forkable simulator of a virtual Tejas Mk1A-class / F404-IN20 fleet.

## Read first

- `docs/architecture/README.md` — the solution architecture (what we build, why, and how it fits together);
  `docs/architecture/13-decision-register.md` — every decision with alternatives and revisit triggers.
- `docs/data-layer/README.md` — index of our understanding of the data layer;
  `docs/data-layer/11-preview-v0.9.md` — the dataset we build on now.
- **Preview data we build on (v0.9):** the Phalanx data layer preview (`data/v0.9/` consumer trees, contract in
  `code/docs/contract/`).

## Non-negotiable rules when consuming the data layer

1. **Build only against the frozen contract** (`phalanx.ground_decoder_contract` **0.2.0**, hash `a4396f1d…`;
   dictionary tejas 0.1.3). Reject files whose schema metadata carries a different contract hash; read columns
   by name. Treat dictionary version/hash as part of every record.
2. **Information discipline:** any feature, label join, prediction or order at time t uses only records with
   `t_ingest ≤ t`. Never use event time alone. Orders citing un-ingested evidence are rejected.
3. **Never read `_restricted_labels/` or `labels.truth`** (or use oracle forks) in the system under test —
   evaluation harness only.
4. **Dedupe by `record_id`** (keep earliest `t_ingest`); `record_id` differs between fast and full paths.
   **Preview v0.9 exception:** the 8 fleet tails are separate worlds whose serials, job numbers and order ids
   collide — dedupe and key fleet records by (`tail_no`, `record_id`) and serials by (`tail_no`, `serial_no`).
5. **Quality:** no NaN exists — mask `SENTINEL`, treat `validity != NORMAL` as missing, keep `OUT_OF_RANGE`
   as signal; some artefacts (freezes, top-of-scale glitches) are deliberately unflagged.
6. **Serials are opaque and move between tails**; health follows the serial, not the tail.
7. **Decisions act only through `orders.commands`**; impact is shown with CRN-paired forks vs the
   `StatusQuoPolicy` baseline. Mods, software loads, monitoring-config changes and servicing deferrals need a
   HUMAN issuer.
8. Everything (ICD, codes, part numbers) is **synthetic**, and v0.9 behaviour is **not validated**; never
   present values as real Tejas/IAF data or as validated physics.

## Rules for the hosting server

1. **No Parquet on the server** — pyarrow's Parquet reader/writer lost data on nullable and nested columns there.
   Runs are written as Arrow IPC (`proto/runner/ipcstore.py`); the preview is read from its IPC copy
   (`data/v0.9/fleet_ipc`). The contract-hash gate applies to both formats.
2. **One conda environment** (`~/envs/phx`, `$PHX_PY`). The simulator runs with the pure-Python numba stand-in
   (`PHX_NUMBA_SHIM=1`); zen-engine is built from source.
3. **Run heavy work on the server, not the laptop** — at most 2 worker processes (3 vCPUs, 7.8 GB). Use
   `proto/deploy/sync.sh --restart` after Python changes and `proto/deploy/services.sh reset` before a demo.
4. **Keep results reproducible** — any change that alters simulated records must still pass
   `proto/runner/gonogo.py` (row-for-row equality with the reference) on the server.
