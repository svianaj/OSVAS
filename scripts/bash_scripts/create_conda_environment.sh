#!/bin/bash
set -euo pipefail

# -----------------------------
# OSVAS Conda Environment Setup
# -----------------------------

# 0. Name your Conda environment
CONDAENV=OSVASENV
PYTHON_VERSION=3.11

echo "🚀 Setting up Conda environment: $CONDAENV with Python $PYTHON_VERSION"

# 1. Check if conda is available
if ! command -v conda &> /dev/null; then
    echo "❌ Conda is not installed. Please install Conda first."
    exit 1
fi

# 2. Create environment if it doesn't exist
if conda env list | grep -q "^$CONDAENV"; then
    echo "⚠️ Environment '$CONDAENV' already exists. Skipping creation."
else
    echo "Creating Conda environment '$CONDAENV'..."
    conda create -n "$CONDAENV" python="$PYTHON_VERSION" -y
fi

# 3. Activate the environment
echo "Activating environment '$CONDAENV'..."
# Use `conda run` if script is non-interactive, otherwise activate normally
eval "$(conda shell.bash hook)"
conda activate "$CONDAENV"

# 4. Install yq (Go version) from conda-forge
echo "Installing yq (Go version)..."
conda install -c conda-forge yq -y

# 5. Install Python packages from requirements.txt
REQ_FILE="../../requirements.txt"
if [[ -f "$REQ_FILE" ]]; then
    echo "Installing Python packages from $REQ_FILE..."
    pip install --upgrade pip
    pip install -r "$REQ_FILE"
else
    echo "⚠️ Requirements file not found at $REQ_FILE. Skipping pip install."
fi

# 6. Final activation message
echo "✅ Conda environment '$CONDAENV' is ready and active."

