# OpenSimRoot Drought Pipeline

Containerized pipeline for running [OpenSimRoot](https://github.com/n-tehranchi/OpenSimRoot) drought simulations at scale on a Run:ai (Kubernetes) cluster.

## What this does

- Builds OpenSimRoot from source inside a Docker container
- Runs root-architecture simulations parameterized by **phenotype**, **location**, and **water regime**
- Submits batch jobs (16 phenotypes x 6 environments = 96 simulations) to Run:ai under the `busch-lab` project

## Quick start

```bash
# 1. Build the Docker image
docker build -t opensimroot-drought .

# 2. Run a single simulation locally
docker run --rm \
  -e PHENOTYPE=deep-root \
  -e LOCATION=rocksprings \
  -e WATER_REGIME=drought \
  -v $(pwd)/input:/sim/input \
  -v $(pwd)/output:/sim/output \
  opensimroot-drought

# 3. Submit all jobs to Run:ai
cp .env.example .env   # edit with your cluster settings
bash scripts/submit-all-sims-runai.sh
```

See [QUICKSTART.md](QUICKSTART.md) for detailed setup instructions.

## Phenotypes (16)

| # | Phenotype | Description |
|---|-----------|-------------|
| 1 | `shallow-root` | Shallow root system angle |
| 2 | `deep-root` | Deep root system angle |
| 3 | `wide-root` | Wide lateral spread |
| 4 | `narrow-root` | Narrow lateral spread |
| 5 | `dense-root` | High root density |
| 6 | `sparse-root` | Low root density |
| 7 | `thick-root` | Thick root diameter |
| 8 | `thin-root` | Thin root diameter |
| 9 | `high-branching` | High lateral branching frequency |
| 10 | `low-branching` | Low lateral branching frequency |
| 11 | `long-lateral` | Long lateral roots |
| 12 | `short-lateral` | Short lateral roots |
| 13 | `steep-angle` | Steep gravitropic angle |
| 14 | `shallow-angle` | Shallow gravitropic angle |
| 15 | `aerenchyma-high` | High aerenchyma formation |
| 16 | `aerenchyma-low` | Low aerenchyma formation |

## Environments (6)

3 locations x 2 water regimes:

| Location | Irrigated | Drought |
|----------|-----------|---------|
| Rocksprings | `rocksprings_irrigated` | `rocksprings_drought` |
| CKA | `cka_irrigated` | `cka_drought` |
| Wageningen | `wageningen_irrigated` | `wageningen_drought` |

## Project structure

```
Dockerfile                      # Multi-stage build for OpenSimRoot
scripts/
  entrypoint.sh                 # Container entrypoint
  submit-all-sims-runai.sh      # Batch job submission to Run:ai
.env.example                    # Configuration template
input/                          # Mount point for XML input files
output/                         # Mount point for simulation results
```

## Configuration

Copy `.env.example` to `.env` and edit:

| Variable | Default | Description |
|----------|---------|-------------|
| `DOCKER_IMAGE` | `ghcr.io/n-tehranchi/opensimroot-drought:latest` | Container image |
| `RUNAI_PROJECT` | `busch-lab` | Run:ai project name |
| `CPU_COUNT` | `2` | CPUs per job |
| `MEMORY_LIMIT` | `4Gi` | Memory per job |
| `GPU_COUNT` | `0` | GPUs per job |
| `PVC_NAME` | `opensimroot-data` | Persistent volume claim name |
| `DRY_RUN` | `false` | Preview commands without submitting |

## XML input files

The entrypoint searches for XML files matching these patterns (first match wins):

1. `/sim/input/run_<phenotype>_<location>_<regime>.xml`
2. `/sim/input/<phenotype>/<location>_<regime>.xml`
3. `/sim/input/<phenotype>/run_<regime>.xml`

If no match is found in mounted input, it falls back to the bundled InputFiles shipped with the image.

## License

See the [OpenSimRoot repository](https://github.com/n-tehranchi/OpenSimRoot) for license details.
