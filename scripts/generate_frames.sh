#!/bin/sh

# Exit on error or undefined variable. This is POSIX-compliant.
set -eu

# --- Configuration ---
# Get the absolute path of the script's directory, POSIX-compliant.
SCRIPT_DIR=$(cd "$(dirname "$0")" >/dev/null 2>&1 && pwd)
SCRIPT_NAME=$(basename "$0")
PYTHON_SCRIPT="${SCRIPT_DIR}/zoom_in_frames_generator.py"
LOG_DIR="${SCRIPT_DIR}/logs"
LOG_FILE="${LOG_DIR}/$(basename "$SCRIPT_NAME" .sh).log"
VENV_DIR="" # Will be set later

# --- Functions ---

# Log messages to the log file
log() {
    # Appends a timestamp to each log message
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >>"${LOG_FILE}"
}

# Log an error and exit
die() {
    log "ERROR: $1"
    # Also print to stderr for immediate feedback if not redirected by a caller
    echo "ERROR: $1. See ${LOG_FILE} for details." >&2
    exit 1
}

# Cleanup function to be called on script exit
cleanup() {
    # Only try to clean up if VENV_DIR was set and the directory exists
    if [ -n "${VENV_DIR}" ] && [ -d "${VENV_DIR}" ]; then
        log "Cleaning up temporary virtual environment at ${VENV_DIR}..."
        # Deactivate if the function exists, ignoring errors.
        # This prevents errors if the script fails before venv activation.
        if command -v deactivate >/dev/null 2>&1; then
            deactivate >/dev/null 2>&1 || true
        fi
        rm -rf "${VENV_DIR}"
        log "Cleanup complete."
    fi
}

# --- Main Script ---

# Trap exit signals to run the cleanup function automatically
trap cleanup EXIT

# Create log directory if it doesn't exist
mkdir -p "${LOG_DIR}"

# --- Validation ---
if [ $# -ne 2 ]; then
    die "Usage: $SCRIPT_NAME <input_image_file> <output_parent_directory>"
fi

# Log after argument validation
log "--- Starting script execution for input: $1 ---"

INPUT_FILE="$1"
OUTPUT_PARENT_DIR="$2"

if [ ! -f "${INPUT_FILE}" ]; then
    die "Input file not found: ${INPUT_FILE}"
fi

if [ ! -f "${PYTHON_SCRIPT}" ]; then
    die "Python script not found: ${PYTHON_SCRIPT}"
fi

if ! command -v python3 >/dev/null 2>&1; then
    die "python3 is not installed or not in PATH."
fi

if ! command -v mktemp >/dev/null 2>&1; then
    die "'mktemp' command is not available. It is required for secure temporary directory creation."
fi

# --- Setup ---

# Create a unique temporary directory for the virtual environment
# Using a portable mktemp syntax that creates the directory in /tmp
VENV_DIR=$(mktemp -d /tmp/n8n-venv.XXXXXXXXXX)
log "Created temporary virtual environment directory: ${VENV_DIR}"

# Define a unique output directory for the generated frames
INPUT_BASENAME=$(basename "${INPUT_FILE}")
# Use sed for a POSIX-compliant way to remove the file extension
INPUT_FILENAME=$(echo "$INPUT_BASENAME" | sed -e 's/\.[^.]*$//')
mkdir -p "${OUTPUT_PARENT_DIR}"
OUTPUT_DIR="${OUTPUT_PARENT_DIR}/${INPUT_FILENAME}_frames_$(date +%Y%m%d_%H%M%S)"
# OUTPUT_DIR="${OUTPUT_PARENT_DIR}/${INPUT_FILENAME}_frames"
mkdir -p "${OUTPUT_DIR}"
log "Output directory for frames: ${OUTPUT_DIR}"

log "Setting up Python virtual environment and installing dependencies..."

# All setup commands' output (stdout & stderr) is redirected to the log file
# Using '.' which is the POSIX-compliant equivalent of 'source'
{
    python3 -m venv "${VENV_DIR}"
    # shellcheck source=/dev/null
    . "${VENV_DIR}/bin/activate"
    pip install --upgrade pip setuptools
    pip install pillow
} >>"${LOG_FILE}" 2>&1

log "Setup complete. Running frame generator..."

# --- Execution ---
# Run the python script.
# Its stdout (the JSON) will pass through to this script's stdout (for n8n).
# Its stderr (Python's logging messages) will be appended to our log file.
if ! python "${PYTHON_SCRIPT}" --input_frame "${INPUT_FILE}" --output_frames_dir "${OUTPUT_DIR}" 2>>"${LOG_FILE}"; then
    die "Python script failed. Check log for details."
fi

log "--- Script execution finished successfully ---"

# The 'trap' will handle cleanup automatically on exit.
# The JSON from the python script has been printed to stdout.