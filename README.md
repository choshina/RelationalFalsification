This is the repository for the paper "Robustness Assessment of DNN Controllers of AI-Enabled CPS" submitted to AAAI-2025, AI Alignment track

***

## System requirement

- Operating system: Linux or MacOS;

- Matlab (Simulink/Stateflow) version: >= 2020a. (Matlab license needed)

- Python version: >= 3.3

## Installation

- Clone the repository.
  1. `git clone https://github.com/Aiura55/AICPSRobustness.git`
  2. `git submodule init`
  3. `git submodule update`

- Install [Breach](https://github.com/decyphir/breach).
  1. start matlab, set up a C/C++ compiler using the command `mex -setup`. (Refer to [here](https://www.mathworks.com/help/matlab/matlab_external/changing-default-compiler.html) for more details.)
  2. navigate to `breach/` in Matlab commandline, and run `InstallBreach`

## Steps to reproduce the results in the paper

1. Navigate to `test/`, and run `python breach_gen.py [configuration file]`, where `[configuration file]` can be anyone from `test/conf/`
2. Navigate to the project home, and run `make`.
