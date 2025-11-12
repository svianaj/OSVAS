# 0. Name your condas environment:
export CONDAENV=OSVASENV
# 1. Create a new conda environment (replace `myenv` with your name)
conda create -n $CONDAENV python=3.11 -y

# 2. Activate it
conda activate $CONDAENV

# 3. Install yq (Go version from conda-forge)
conda install -c conda-forge yq -y

# 4. Install packages from requirements.txt using pip
pip install -r ../requirements.txt

# 5. Activate the environment
conda activate $CONDAENV
