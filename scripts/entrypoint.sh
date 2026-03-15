#!/usr/bin/env bash
set -euo pipefail

# ---------------------------------------------------------------------------
# entrypoint.sh
# Finds the matching XML input file for a given phenotype, location, and
# water regime, then runs the OpenSimRoot binary.
# ---------------------------------------------------------------------------

# Required environment variables
: "${PHENOTYPE:?Error: PHENOTYPE env var is not set}"
: "${LOCATION:?Error: LOCATION env var is not set}"
: "${WATER_REGIME:?Error: WATER_REGIME env var is not set}"

# Optional
OUTPUT_PATH="${OUTPUT_PATH:-/sim/output}"
INPUT_DIR="${INPUT_DIR:-/sim/input}"
BUNDLED_DIR="${BUNDLED_DIR:-/opt/opensimroot/InputFiles}"

echo "============================================"
echo "OpenSimRoot Drought Simulation"
echo "  Phenotype:    ${PHENOTYPE}"
echo "  Location:     ${LOCATION}"
echo "  Water regime: ${WATER_REGIME}"
echo "  Output path:  ${OUTPUT_PATH}"
echo "============================================"

# --- Locate the XML input file ---
# Search order:
#   1. Mounted input directory (user-provided overrides)
#   2. Bundled InputFiles shipped with the image
#
# Naming convention tried (first match wins):
#   run_<PHENOTYPE>_<LOCATION>_<WATER_REGIME>.xml
#   <PHENOTYPE>/<LOCATION>_<WATER_REGIME>.xml
#   <PHENOTYPE>/run_<WATER_REGIME>.xml

XML_FILE=""
CANDIDATES=(
    "${INPUT_DIR}/run_${PHENOTYPE}_${LOCATION}_${WATER_REGIME}.xml"
    "${INPUT_DIR}/${PHENOTYPE}/${LOCATION}_${WATER_REGIME}.xml"
    "${INPUT_DIR}/${PHENOTYPE}/run_${WATER_REGIME}.xml"
    "${BUNDLED_DIR}/run_${PHENOTYPE}_${LOCATION}_${WATER_REGIME}.xml"
    "${BUNDLED_DIR}/${PHENOTYPE}/${LOCATION}_${WATER_REGIME}.xml"
    "${BUNDLED_DIR}/${PHENOTYPE}/run_${WATER_REGIME}.xml"
)

for candidate in "${CANDIDATES[@]}"; do
    if [[ -f "${candidate}" ]]; then
        XML_FILE="${candidate}"
        break
    fi
done

if [[ -z "${XML_FILE}" ]]; then
    echo "ERROR: No XML input file found for combination:"
    echo "  PHENOTYPE=${PHENOTYPE}  LOCATION=${LOCATION}  WATER_REGIME=${WATER_REGIME}"
    echo ""
    echo "Searched:"
    for c in "${CANDIDATES[@]}"; do
        echo "  - ${c}"
    done
    echo ""
    echo "Available files in ${INPUT_DIR}:"
    find "${INPUT_DIR}" -name '*.xml' 2>/dev/null | head -30 || echo "  (none)"
    echo "Available files in ${BUNDLED_DIR}:"
    find "${BUNDLED_DIR}" -name '*.xml' 2>/dev/null | head -30 || echo "  (none)"
    exit 1
fi

echo "Using input file: ${XML_FILE}"

# --- Prepare output directory ---
SIM_OUTPUT="${OUTPUT_PATH}/${PHENOTYPE}_${LOCATION}_${WATER_REGIME}"
mkdir -p "${SIM_OUTPUT}"

# Run from the output directory so OpenSimRoot writes results there
cd "${SIM_OUTPUT}"

echo "Running OpenSimRoot..."
OpenSimRoot "${XML_FILE}"
EXIT_CODE=$?

if [[ ${EXIT_CODE} -eq 0 ]]; then
    echo "Simulation completed successfully."
    echo "Results saved to: ${SIM_OUTPUT}"
else
    echo "Simulation FAILED with exit code ${EXIT_CODE}"
fi

exit ${EXIT_CODE}
