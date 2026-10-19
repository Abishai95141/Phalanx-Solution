<p align="center">
  <a href="https://148.100.99.205/">
    <picture>
      <source media="(prefers-color-scheme: dark)" srcset="docs/assets/readme/logo-dark.svg">
      <img src="docs/assets/readme/logo-light.svg" alt="Phalanx" width="380">
    </picture>
  </a>
</p>

<h3 align="center">Phalanx Twin — the fleet-availability digital twin that gets more aircraft flying every morning.</h3>

<p align="center">
  <a href="https://148.100.99.205/"><img alt="Live demo" src="https://img.shields.io/badge/live%20demo-148.100.99.205-1F8A4C?style=for-the-badge"></a>
  <img alt="Smart India Hackathon 2026" src="https://img.shields.io/badge/Smart%20India%20Hackathon-2026-0B0D10?style=for-the-badge">
  <img alt="Problem statement 26249" src="https://img.shields.io/badge/PS-26249-E8743B?style=for-the-badge">
  <img alt="74 tests passing" src="https://img.shields.io/badge/tests-74%20passing-1F8A4C?style=for-the-badge">
</p>

<p align="center">
  <b><a href="https://148.100.99.205/">▶ Open the live app — https://148.100.99.205</a></b>
  &nbsp;·&nbsp; <a href="docs/prototype/DEMO.md">8-minute demo guide</a>
  &nbsp;·&nbsp; <a href="docs/architecture/README.md">Architecture</a>
</p>

<p align="center"><b>Team Circuit_breakers_SE</b> · Smart India Hackathon 2026 · PS 26249 · live demo hosted in IBM Cloud</p>

<a href="https://148.100.99.205/"><img src="docs/assets/readme/hero.svg" alt="Phalanx Twin: more aircraft flying, every morning. Six of eight aircraft mission capable on the live readiness board." width="100%"></a>

**Phalanx Twin** is a decision-support digital twin for military aircraft fleet availability, built for Smart India
Hackathon 2026 problem statement **PS 26249** *"Air Power – Predictive Maintenance & Fleet Availability"* (Ministry
of Defence, India). Every morning it
reads what the fleet reported overnight, works out which aircraft can fly and why the others cannot, and puts a short,
ranked list of decisions in front of the engineering officer before 07:45 — each one with its evidence, a simulation
of what it will do against doing nothing, and a place for the right person's signature. The whole system — fleet
simulator, models, rules engine, daily loop, audit log and web app — is live at
**[https://148.100.99.205](https://148.100.99.205/)** (hosted in IBM Cloud).

<p align="center"><img src="docs/assets/readme/tour.gif" alt="A walk through the live app: readiness, decisions, recommendation, why, workbench, aircraft twin, orders and provenance" width="100%"></p>

---

## The problem

<img src="docs/assets/readme/problem.svg" alt="In the last 30 days the squadron was mission capable 54.5 % of the time against a 75 % target; 25.4 % of the time aircraft waited for parts. 1,192 alerts in 168 days; 30 pumps removed from one aircraft for an alarm that never once found a fault." width="100%">

A fighter squadron does not lose availability in the air. It loses it on the ground:

- **Waiting** — for parts, for a repair slot, for someone to decide. In our fleet a quarter of all aircraft-time is
  spent waiting for parts.
- **False alarms** — healthy parts pulled off aircraft because an alarm keeps firing. One aircraft had its hydraulic
  pump replaced 30 times; across the fleet, not one of 118 jobs on that alarm ever confirmed a fault.
- **Too much signal, too little time** — 1,192 fault and caution reports for eight aircraft, and a decision deadline
  every morning, made from logbooks and memory with no way to test an order before it is issued.
- **No trail** — when an order turns out wrong, nobody can show what was known at the time, which rule fired and who
  approved it.

## The solution

Phalanx Twin runs a **daily decision loop** over a live twin of every aircraft and every serialised part.

<p align="center"><img src="docs/assets/readme/triage.gif" alt="Animation: 1,192 alert rows are grouped into 326 issues, 33 are still open, and 9 become ranked decisions before 07:45" width="100%"></p>

| | What it does | How |
|---|---|---|
| **See** | One state per aircraft and per part, as of 06:00, from only the data received by then | contract-checked records, "as-of" reads, a 3D twin per aircraft |
| **Understand** | Separates real faults from false alarms and finds where the fault really is | false-alarm model (champion vs challenger), noisy-OR fault isolation with best next test, removal-risk survival model, engine-health tracking, drift detection |
| **Decide** | Turns 1,192 alerts into 9 ranked decisions, each with an order and an owner | safety gates, consequence × urgency, versioned zen-engine decision tables, HUMAN-only orders for changes that need a signature |
| **Prove** | Shows what each order will do before it is issued | paired what-if simulations of the fleet: the order vs doing nothing |
| **Act and audit** | Issues signed orders at 08:00 and records everything | one hash-chained event log; any decision can be verified and replayed |

<p align="center"><img src="docs/assets/readme/loop.gif" alt="Animation of the daily cycle: 06:00 snapshot sealed, 06:04 models run, 06:05 board open, 07:45 board freezes, 07:52 signatures, 08:00 orders issued, the fleet flies the day, and outcomes come back as records at 06:00" width="100%"></p>

### Fast enough for the morning

Whether an aircraft flies is decided against the clock, so the loop is built for it:

- **Minutes, not days.** The 06:00 snapshot becomes a ranked board by 06:05: 1,192 alerts triaged, each fault scored
  by the models, every proposed order simulated against doing nothing — all before the 07:45 freeze.
- **Instant answers.** On the live server every screen's data comes back in 0.6 ms (median); a whole simulated fleet
  day runs in 3.5 s, so what-if questions are answered while the officer is still looking at the board.
- **No hindsight.** Every model, rule and order sees only what was received by decision time.
- **People decide.** The twin ranks, explains and simulates; critical orders need a named signature, and every step
  is on a hash-chained log that can be replayed.

### How it works

```mermaid
flowchart TB
  A["<b>Fleet</b> · 8 aircraft, simulated day by day<br/>(Phalanx data layer)"]
  subgraph SEE["1 · See — 06:00"]
    direction LR
    G["Release gate<br/>contract hash"] --> S["As-of store<br/>only data received by 06:00"]
  end
  subgraph UND["2 · Understand — 06:04"]
    direction LR
    M1["False alarm"] ~~~ M2["Fault isolation"] ~~~ M3["Removal risk"] ~~~ M4["Engine health"]
  end
  subgraph DEC["3 · Decide and prove — 06:05"]
    direction LR
    T["Triage<br/>consequence × urgency"] --> P["Decision tables<br/>zen-engine"] --> F["What-if forks<br/>order vs doing nothing"]
  end
  subgraph ACT["4 · Act — 07:45 to 08:00"]
    direction LR
    B["Board freezes"] --> O["Officer approves<br/>and signs"] --> X["Orders through the gateway<br/>outcomes return next morning"]
  end
  L[("Hash-chained event log<br/>verify · replay")]
  A -- "records every morning" --> SEE --> UND --> DEC --> ACT
  ACT -.-> L
```

### Every order is tested before it is issued

<img src="docs/assets/readme/impact.svg" alt="Paired simulations: TJ107's order adds 18.0 points of mission-capable rate (95 % interval 7.7 to 28.3) and is approved; TJ102's adds −10.6 points and is rejected as worse than doing nothing" width="100%">

For TJ107 the twin recommends **stopping the pump removals** and troubleshooting the indication path instead. Ten
paired simulations say TJ107 is mission capable **18 points more of the next 30 days** (95 % interval +7.7 to +28.3)
— about five more flyable days for one aircraft, with 136 fewer maintenance man-hours. The similar-looking order for
TJ102 makes things worse (−10.6 points), so the officer rejects it. Nothing is issued on a hunch.

### Inside the app

<table>
  <tr>
    <td width="50%"><a href="https://148.100.99.205/readiness.html"><img src="docs/assets/readme/screens/readiness.png" alt="Readiness"></a><br><b>Readiness</b> — which aircraft can fly today, and why the others cannot</td>
    <td width="50%"><a href="https://148.100.99.205/decisions.html"><img src="docs/assets/readme/screens/decisions.png" alt="Decisions"></a><br><b>Decisions</b> — the morning board: 9 ranked items before 07:45</td>
  </tr>
  <tr>
    <td><a href="https://148.100.99.205/decision.html?issue=TJ107-HYD-101"><img src="docs/assets/readme/screens/decision.png" alt="Recommendation"></a><br><b>Recommendation</b> — the order, its evidence and its simulated impact</td>
    <td><a href="https://148.100.99.205/workbench.html?issue=TJ107-HYD-101"><img src="docs/assets/readme/screens/workbench.png" alt="Workbench"></a><br><b>Workbench</b> — the alarm follows the aircraft, not the pump; the best next test</td>
  </tr>
  <tr>
    <td><a href="https://148.100.99.205/twin.html?issue=TJ107-HYD-101&tail=TJ107"><img src="docs/assets/readme/screens/twin.png" alt="Aircraft twin"></a><br><b>Aircraft twin</b> — every part's status, evidence, life and removal risk in 3D</td>
    <td><a href="https://148.100.99.205/provenance.html"><img src="docs/assets/readme/screens/provenance.png" alt="Provenance"></a><br><b>Provenance</b> — the hash chain behind every order; verify and replay</td>
  </tr>
</table>

### What changes for a squadron

| Today | With Phalanx Twin |
|---|---|
| 1,192 alerts read by hand, or not at all | 9 ranked decisions, each with the rule that put it there |
| Parts replaced because the alarm fired again | A false-alarm forecast and the most likely real cause before anything is removed |
| Orders judged by experience alone | Every order simulated against doing nothing, with a confidence interval |
| "Who decided this, and on what?" | One hash-chained record from snapshot to signature to outcome; replay gives the same answer |
| Availability reviewed after the month ends | Readiness, causes and the day's decisions every morning at 06:05 |

---

## Proved on the live server

<img src="docs/assets/readme/live-metrics.svg" alt="Key live metrics: 6 of 8 aircraft mission capable; 1,192 alerts to 9 decisions; +18.0 points for TJ107; 4 of 4 assurance gates; 11 models registered; 0.6 ms median API response; Brier 0.1008; 8 of 8 planted engine faults found" width="100%">

| Proof point | Result |
|---|---|
| **Same answers, rebuilt** | The 8-aircraft fleet rebuilt on the cloud server matches the reference data **row for row in every topic** (9,202 maintenance records, 1,192 alerts, 19,404 usage counters), and so does the next simulated day |
| Daily cycle | One simulated day for all 8 aircraft in **3.5 s**; full rebuild to the demo day in about 4 minutes |
| Training at scale | 32 training worlds (64 aircraft-years) built on the server in 57 minutes with 2 workers |
| What-if analysis | 10 paired fleet simulations per order in 2–3 minutes |
| Responsiveness | Median API response **0.6 ms** on the server (p95 23 ms) once the morning is computed |
| Quality | 74 automated tests and the end-to-end flow pass on the server and on a laptop |

## From prototype to squadron

```mermaid
flowchart LR
  P0["<b>Now — proved</b><br/>whole system live on one<br/>cloud server<br/>row-for-row reproduction"]
  P1["<b>Squadron pilot</b><br/>one air-gapped station<br/>server per base<br/>real e-MMS / IMMOLS extracts"]
  P2["<b>Command</b><br/>fleet view across squadrons<br/>spares and cannibalisation<br/>work requests into e-MMS"]
  P3["<b>Fleet scale</b><br/>every squadron on one contract<br/>shared model registry<br/>retraining from outcomes"]
  P0 --> P1 --> P2 --> P3
  style P0 fill:#EAF6EF,stroke:#1F8A4C
  style P1 fill:#FDF1EA,stroke:#E8743B
  style P2 fill:#FDF1EA,stroke:#E8743B
  style P3 fill:#FDF1EA,stroke:#E8743B
```

The full design, with every decision and its alternatives: **[docs/architecture/](docs/architecture/README.md)**.

---

## Try it

Open **[https://148.100.99.205](https://148.100.99.205/)** and follow the [demo guide](docs/prototype/DEMO.md)
(about 8 minutes): Readiness → Decisions → Recommendation → Why → Workbench → Aircraft twin → Orders (sign, advance
a day) → Provenance (verify the chain) → Policies → Assurance.

Run it on the server from a checkout (SSH details in `proto/deploy/ssh_config`, copied from `ssh_config.example`):

```bash
proto/deploy/sync.sh --restart
```

```bash
proto/deploy/remote.sh 'proto/deploy/services.sh reset'
```

## Repository

| Path | Contents |
|---|---|
| [`docs/architecture/`](docs/architecture/README.md) | the solution architecture and decision register |
| [`docs/prototype/`](docs/prototype/DEVELOPMENT.md) | the prototype's development document and the demo guide |
| [`docs/data-layer/`](docs/data-layer/README.md) | how we read the data layer: contract, time discipline, quality |
| [`proto/`](proto/README.md) | the system: `runner/` (simulated fleet), `ground/` (twin, models, triage, policies, loop, API), `web/` (screens), `deploy/` (server scripts), `tests/` |
| [`docs/assets/readme/`](docs/assets/readme/src/README.md) | this page's pictures and the scripts that rebuild them from the live system |
| [`RULES.md`](RULES.md) | the rules every line of code follows when reading the data layer |

## The data behind it: a physics-based fleet you can fork

Phalanx Twin is built and tested on the team's **Phalanx data layer**: a deterministic simulator of a Tejas
Mk1A-class / F404-IN20 fleet, engineered to behave like real flight-line data, including its flaws.

| | How the data layer does it |
|---|---|
| **Physics first** | 240 Hz flight physics with hidden per-serial health and injected faults, through sensors, MIL-STD-1553B and ARINC-429 buses and per-sortie IRIG 106 Chapter 10 recordings, decoded on the ground into nine topics: samples, BIT, exceedance and caution events, usage counters, sortie manifests, maintenance records, orders and order status |
| **Real-world mess, on purpose** | late downloads, sentinels and out-of-range values, sensor freezes and top-of-scale glitches (some deliberately unflagged), healthy parts removed on false alarms, serials that move between aircraft, parts that take months to arrive |
| **A frozen contract** | every file carries the contract hash (0.2.0); the twin's release gate rejects anything else, and every read is "as of" its ingest time, so no model ever sees the future |
| **A closed loop** | the twin's orders go back into the simulator through its own order gateway, and their outcomes return as new records the next morning |
| **Forkable futures** | what-if forks with common random numbers give paired, like-for-like comparisons of an order against doing nothing |
| **Truth kept apart** | the hidden ground truth exists only for offline scoring; the system under test never reads it |
| **Reproducible anywhere** | deterministic seeds: rebuilt on the cloud server, the fleet matches the reference row for row |
| **Enough history to learn from** | 64 aircraft-years of training worlds; models are scored on held-out worlds they never saw |

Aircraft codes, part numbers and the ICD are stand-ins, so everything can be shown openly; connecting a real fleet
means implementing the same contract.

<p align="center"><sub><b>Team Circuit_breakers_SE</b> · Smart India Hackathon 2026 · PS 26249</sub></p>
