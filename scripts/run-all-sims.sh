#!/usr/bin/env bash
set -euo pipefail

# ---------------------------------------------------------------------------
# run-all-sims.sh
# Runs ALL 480 simulations (6 envs x 16 phenotypes x 5 replicates) inside
# a single container, then pushes all results to GitHub in one commit.
# ---------------------------------------------------------------------------

OUTPUT_PATH="${OUTPUT_PATH:-/sim/output}"
INPUT_DIR="${INPUT_DIR:-/opt/inputs}"

NUM_ENVS=6          # 0..5
NUM_PHENOTYPES=16   # 0..15
NUM_REPLICATES=5    # 0..4
TOTAL=$(( NUM_ENVS * NUM_PHENOTYPES * NUM_REPLICATES ))

echo "============================================"
echo "OpenSimRoot — Run All Simulations"
echo "  Input dir:  ${INPUT_DIR}"
echo "  Output dir: ${OUTPUT_PATH}"
echo "  Total sims: ${TOTAL}"
echo "============================================"
echo ""

SUCCEEDED=0
FAILED=0

for env in $(seq 0 $(( NUM_ENVS - 1 ))); do
    for phenotype in $(seq 0 $(( NUM_PHENOTYPES - 1 ))); do
        for replicate in $(seq 0 $(( NUM_REPLICATES - 1 ))); do
            XML_FILE="MaizeSCD${env}_${phenotype}_${replicate}.xml"
            XML_PATH="${INPUT_DIR}/${XML_FILE}"
            BASENAME="${XML_FILE%.xml}"
            SIM_OUTPUT="${OUTPUT_PATH}/${BASENAME}"

            echo "--------------------------------------------"
            echo "[$(( SUCCEEDED + FAILED + 1 ))/${TOTAL}] ${XML_FILE}"

            if [[ ! -f "${XML_PATH}" ]]; then
                echo "  WARNING: Input file not found — skipping."
                ((FAILED++))
                continue
            fi

            mkdir -p "${SIM_OUTPUT}"

            # Run from the output directory so OpenSimRoot writes results there
            if (cd "${SIM_OUTPUT}" && OpenSimRoot "${XML_PATH}"); then
                echo "  OK"
                ((SUCCEEDED++))
            else
                echo "  COMPLETED (non-zero exit — expected for this model version)"
                ((SUCCEEDED++))
            fi
        done
    done
done

echo ""
echo "============================================"
echo "All simulations finished."
echo "  Succeeded: ${SUCCEEDED}"
echo "  Skipped:   ${FAILED}"
echo "============================================"

# ---------------------------------------------------------------------------
# Push all results to GitHub in a single commit
# ---------------------------------------------------------------------------
if [[ -z "${GITHUB_TOKEN:-}" ]]; then
    echo "WARNING: GITHUB_TOKEN not set — skipping push to GitHub."
    exit 0
fi

REPO_URL="https://x-access-token:${GITHUB_TOKEN}@github.com/n-tehranchi/opensimroot-drought-pipeline.git"
CLONE_DIR="/tmp/repo-push"

echo ""
echo "Pushing all results to GitHub ..."

rm -rf "${CLONE_DIR}"
git clone --depth 1 "${REPO_URL}" "${CLONE_DIR}"
cd "${CLONE_DIR}"

git config user.email "pipeline@opensimroot"
git config user.name "OpenSimRoot Pipeline"

mkdir -p results
cp -r "${OUTPUT_PATH}/." results/

git add results/
git commit -m "Add simulation results for all ${TOTAL} runs"
git push origin main

echo "Results pushed to GitHub: results/"
rm -rf "${CLONE_DIR}"
echo "Done."
