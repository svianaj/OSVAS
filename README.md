🚀 OSVAS — Offline Surfex Validation System

OSVAS is a workflow developed within the ACCORD community to:

Generate SURFEX forcing data from ICOS atmospheric datasets

Download and process ICOS flux data for validation

Run SURFEX OFFLINE simulations (PGD, PREP, OFFLINE)

Convert SURFEX outputs to sqlite FCTABLES (via nc2sqlite)

Validate results using HARP

Visualize outputs with interactive Shiny apps

OSVAS automates the full cycle: forcing → model run → extraction → validation → visualization.

📚 Documentation

All documentation is now organized in the docs/ folder:

🔧 Setup & Configuration

👉 Installation & Requirements

👉 Station Configuration (YAML)

🧪 OSVAS Workflow Steps

Step 0 — Paths & Global Configuration

Step 1 — Forcing Data Generation

Step 2 — Validation Data Download

Step 3 — SURFEX Simulation Runs

Step 4 — Extract Model Outputs (nc2sqlite)

Step 5 — HARP Verification

Step 6 — Visualization Apps

⚡ Quick Start

Clone the repository:

git clone https://github.com/svianaj/OSVAS.git
cd OSVAS


Create the conda environment:

cd scripts/bash_scripts
./create_conda_environment.sh
conda activate OSVASENV


Edit your run script:

export STATION_NAME=Majadas_del_tietar
export OSVAS=$HOME/OSVAS
export HARP=$HOME/operharpverif


Run OSVAS:

./surfex_OSVAS_run_linux.sh
