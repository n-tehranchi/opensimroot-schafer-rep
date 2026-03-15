# Quick Start Guide

## Prerequisites

- Docker installed and running
- (For cluster submission) `runai` CLI installed and authenticated
- (For cluster submission) Access to the `busch-lab` Run:ai project

## 1. Build the Docker image

```bash
docker build -t opensimroot-drought .
```

This clones OpenSimRoot, compiles it from source, and creates a slim runtime image.

## 2. Prepare input files

Place your XML simulation configs in an `input/` directory following one of these naming patterns:

```
input/run_<phenotype>_<location>_<regime>.xml
input/<phenotype>/<location>_<regime>.xml
input/<phenotype>/run_<regime>.xml
```

Example:

```
input/
  run_deep-root_rocksprings_drought.xml
  run_shallow-root_cka_irrigated.xml
```

If you don't provide custom inputs, the entrypoint falls back to the default InputFiles bundled in the image.

## 3. Run a single simulation locally

```bash
docker run --rm \
  -e PHENOTYPE=deep-root \
  -e LOCATION=rocksprings \
  -e WATER_REGIME=drought \
  -v $(pwd)/input:/sim/input \
  -v $(pwd)/output:/sim/output \
  opensimroot-drought
```

Results appear in `output/deep-root_rocksprings_drought/`.

## 4. Submit all jobs to Run:ai

```bash
# Copy and edit the config
cp .env.example .env
# Edit .env with your cluster settings

# Preview what will be submitted (dry run)
DRY_RUN=true bash scripts/submit-all-sims-runai.sh

# Submit for real
bash scripts/submit-all-sims-runai.sh
```

This submits 96 jobs (16 phenotypes x 3 locations x 2 water regimes).

## 5. Monitor jobs

```bash
# List all running jobs
runai list jobs --project busch-lab

# Check a specific job
runai describe job osr-deep-root-rocksprings-drought --project busch-lab

# View logs
runai logs osr-deep-root-rocksprings-drought --project busch-lab
```

## 6. Collect results

Results are written to the PVC at `/sim/output/<phenotype>_<location>_<regime>/`. Retrieve them from the persistent volume or copy from a running pod:

```bash
kubectl cp <pod-name>:/sim/output ./results -n runai-busch-lab
```

## Troubleshooting

| Problem | Fix |
|---------|-----|
| "PHENOTYPE env var is not set" | Set all three env vars: `PHENOTYPE`, `LOCATION`, `WATER_REGIME` |
| "No XML input file found" | Check your file naming matches the expected patterns (see step 2) |
| Job OOMKilled | Increase `MEMORY_LIMIT` in `.env` |
| `runai` command not found | Install the Run:ai CLI and authenticate with your cluster |
