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
echo "🔍 Checking system type for yq installation..."

if [[ -d "/ec/res4/scratch" ]]; then
    echo "➡ ECMWF HPC detected — installing MikeFarah yq v4 via direct download..."

    YQ_VERSION=v4.48.1
    BINARY=yq_linux_amd64
    INSTALL_DIR="$HOME/.local/bin"

    mkdir -p "$INSTALL_DIR"
    curl -L "https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/${BINARY}" \
        -o "${INSTALL_DIR}/yq"
    chmod +x "${INSTALL_DIR}/yq"

    echo "✅ yq v4 installed at: $INSTALL_DIR/yq"
else
    echo "➡ Not ECMWF — installing yq from conda-forge"
    conda install -c conda-forge yq -y
fi

# Refresh PATH for current script execution
export PATH="$HOME/.local/bin:$PATH"

# 5. Install Python packages from requirements.txt
REQ_FILE="../../requirements.txt"
if [[ -f "$REQ_FILE" ]]; then
    echo "Installing Python packages from $REQ_FILE..."
    pip install --upgrade pip
    pip install -r "$REQ_FILE"
else
    echo "⚠️ Requirements file not found at $REQ_FILE. Skipping pip install."
fi

# 6. If on ATOS system, install HARP libraries & dependencies in an isolated Renv
if [[ -d "/ec/res4/scratch" ]]; then
   module reset
   cd ../../renv_atos/
   #./atos_renv_setup.sh
   CURRENT_WDIR="$(pwd)"
   SETENV_FILE="$(pwd)/Setenv"
   # Update R_PROFILE_USER line
   sed -i "s|^export R_PROFILE_USER=.*|export R_PROFILE_USER=$CURRENT_WDIR/.Rprofile|" "$SETENV_FILE"

   # Update RENV_PROJECT line
   sed -i "s|^export RENV_PROJECT=.*|export RENV_PROJECT=$CURRENT_WDIR/|" "$SETENV_FILE"
   echo "Finished HARP installation in Renv; to test it in this terminal, do: "
   echo " module reset "
   echo " source $CURRENT_WDIR/Setenv "
   echo " Rscript -e "library(harp)" "
fi

# 7. Final activation message
echo "✅ Conda environment '$CONDAENV' is ready. Activate it with conda activate $CONDAENV"


