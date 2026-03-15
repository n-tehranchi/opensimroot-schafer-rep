# CLAUDE.md — OpenSimRoot Drought Pipeline

## Project overview

This repo containerizes [OpenSimRoot](https://github.com/n-tehranchi/OpenSimRoot) and orchestrates large-scale drought simulations on a Run:ai (Kubernetes) cluster under the **busch-lab** project. Each simulation is defined by a **phenotype** (root architecture variant) and an **environment** (location x water regime).

## Repo structure

```
Dockerfile              # Multi-stage build: compiles OpenSimRoot, produces slim runtime image
scripts/
  entrypoint.sh         # Container entrypoint — resolves XML input, runs simulator, saves output
  submit-all-sims-runai.sh  # Submits 16 phenotypes x 6 environments = 96 jobs to Run:ai
.env.example            # Template for cluster/image configuration
```

## Key conventions

- **Phenotype names** use kebab-case (e.g., `shallow-root`, `high-branching`).
- **Environment** = `<location>_<water-regime>` (e.g., `rocksprings_drought`).
- XML input files follow the naming pattern `run_<phenotype>_<location>_<regime>.xml`.
- Simulation output lands in `$OUTPUT_PATH/<phenotype>_<location>_<regime>/`.

## Build & run

```bash
# Build the image
docker build -t opensimroot-drought .

# Run a single simulation locally
docker run --rm \
  -e PHENOTYPE=deep-root \
  -e LOCATION=rocksprings \
  -e WATER_REGIME=drought \
  -v ./input:/sim/input \
  -v ./output:/sim/output \
  opensimroot-drought

# Submit all jobs to Run:ai
cp .env.example .env   # edit as needed
bash scripts/submit-all-sims-runai.sh
```

## Development notes

- OpenSimRoot compiles with `make release` under `OpenSimRoot/StaticBuild/` (C++14, g++).
- The Dockerfile uses a multi-stage build to keep the runtime image small.
- `entrypoint.sh` searches both mounted `/sim/input` and bundled `/opt/opensimroot/InputFiles` for XML configs.
- Set `DRY_RUN=true` in `.env` to preview Run:ai commands without submitting.
