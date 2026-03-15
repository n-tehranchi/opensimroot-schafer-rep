#!/usr/bin/env bash
set -euo pipefail

# ---------------------------------------------------------------------------
# submit-all-sims-runai.sh
# Submits all 6 envs x 16 phenotypes x 5 replicates = 480 simulation jobs
# to Run:ai under the busch-lab project.
#
# XML input files follow the naming pattern:
#   MaizeSCD{env}_{phenotype}_{replicate}.xml
#   where env=0..5, phenotype=0..15, replicate=0..4
# ---------------------------------------------------------------------------

# --- Configuration (override via env or .env file) ---
PROJECT="${RUNAI_PROJECT:-busch-lab}"
IMAGE="${DOCKER_IMAGE:-natalietehranchi/opensimroot-drought:latest}"
GPU="${GPU_COUNT:-0}"
CPU="${CPU_COUNT:-2}"
MEMORY="${MEMORY_LIMIT:-4Gi}"
PVC_NAME="${PVC_NAME:-opensimroot-data}"
PVC_MOUNT="${PVC_MOUNT:-/sim}"
INPUT_DIR="${INPUT_DIR:-/home/jovyan/work/inputs}"
NAMESPACE="${RUNAI_NAMESPACE:-runai-busch-lab}"
DRY_RUN="${DRY_RUN:-false}"

NUM_ENVS=6          # 0..5
NUM_PHENOTYPES=16   # 0..15
NUM_REPLICATES=5    # 0..4
TOTAL_JOBS=$(( NUM_ENVS * NUM_PHENOTYPES * NUM_REPLICATES ))

# --- Load .env if present ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="${SCRIPT_DIR}/../.env"
if [[ -f "${ENV_FILE}" ]]; then
    echo "Loading config from ${ENV_FILE}"
    set -a
    # shellcheck source=/dev/null
    source "${ENV_FILE}"
    set +a
fi

echo "============================================"
echo "OpenSimRoot Drought Pipeline - Batch Submit"
echo "  Project:    ${PROJECT}"
echo "  Image:      ${IMAGE}"
echo "  Resources:  ${CPU} CPU, ${MEMORY} RAM, ${GPU} GPU"
echo "  Input dir:  ${INPUT_DIR}"
echo "  Envs:       ${NUM_ENVS} (0-$(( NUM_ENVS - 1 )))"
echo "  Phenotypes: ${NUM_PHENOTYPES} (0-$(( NUM_PHENOTYPES - 1 )))"
echo "  Replicates: ${NUM_REPLICATES} (0-$(( NUM_REPLICATES - 1 )))"
echo "  Total jobs: ${TOTAL_JOBS}"
echo "  Dry run:    ${DRY_RUN}"
echo "============================================"
echo ""

SUBMITTED=0
FAILED=0

for env in $(seq 0 $(( NUM_ENVS - 1 ))); do
    for phenotype in $(seq 0 $(( NUM_PHENOTYPES - 1 ))); do
        for replicate in $(seq 0 $(( NUM_REPLICATES - 1 ))); do
            XML_FILE="MaizeSCD${env}_${phenotype}_${replicate}.xml"
            JOB_NAME="osr-e${env}-p${phenotype}-r${replicate}"

            echo -n "Submitting ${JOB_NAME} (${XML_FILE}) ... "

            CMD=(
                runai submit "${JOB_NAME}"
                --project "${PROJECT}"
                --image "${IMAGE}"
                --cpu "${CPU}"
                --memory "${MEMORY}"
                --pvc "${PVC_NAME}:${PVC_MOUNT}"
                -e INPUT_FILE="${INPUT_DIR}/${XML_FILE}"
            )

            if [[ "${GPU}" -gt 0 ]]; then
                CMD+=(--gpu "${GPU}")
            fi

            if [[ "${DRY_RUN}" == "true" ]]; then
                echo "[dry-run] ${CMD[*]}"
            else
                if "${CMD[@]}" 2>&1; then
                    echo "OK"
                    ((SUBMITTED++))
                else
                    echo "FAILED"
                    ((FAILED++))
                fi
            fi
        done
    done
done

echo ""
echo "============================================"
echo "Batch submission complete."
echo "  Submitted: ${SUBMITTED}"
echo "  Failed:    ${FAILED}"
echo "  Total:     $(( SUBMITTED + FAILED ))"
echo "============================================"

if [[ ${FAILED} -gt 0 ]]; then
    echo "WARNING: ${FAILED} job(s) failed to submit."
    exit 1
fi
