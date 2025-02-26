# About this repo
A demo repository containing test definitions for validating hardware functionality on eLxr Linux, along with instructions for running tests outside the LAVA infrastructure.

## Prerequisites
The following packages are required:
- git
- wget
- python3
- python3-distutils
- python3-pexpect
- python3-yaml
- python3-jinja2

Install prerequisites:
```bash
apt-get update
apt-get install git wget python3 python3-distutils python3-pexpect python3-yaml python3-jinja2 -y
```

## Installation
1. Clone the repository:
```bash
git clone git://lxgit.wrs.com/users/lyang0/test-definition-hardware-validation -b <branch name> test-definitions
cd test-definitions
```

2. Set up the environment:
```bash
source automated/bin/setenv.sh
```

## Usage

### Running Test Suites
The framework supports multiple test suites that can be run independently:

1. Userspace Tests:
```bash
./automated/bin/test-runner -p plans/userspace.yml -o /$USER/output_userspace
```

2. Kernel Selftests:
```bash
./automated/bin/test-runner -p plans/kernel.yml -o /$USER/output_kernel
```

3. BSP Tests:
```bash
./automated/bin/test-runner -p plans/bsp.yml -o /$USER/output_bsp
```

4. Benchmark Tests:
```bash
./automated/bin/test-runner -p plans/benchmark.yml -o /$USER/output_benchmark
```

### Generating Reports
After running the tests, you can generate an HTML report:
```bash
cd tools
python3 generate_report.py \
    --input-dir /$USER/output_bsp,/$USER/output_kernel,/$USER/output_userspace,/$USER/output_benchmark \
    --template template.html \
    --output-html report.html \
    --serve
```
Which provides a URL to access the test results.

## Directory Structure
- automated/bin/ - Contains test runner scripts and environment setup
- tools/ - Report generation and other utilities
- Test definition files:
  - userspace.yaml
  - kernel.yaml
  - bsp.yaml
  - benchmark.yaml

## Output
Test results are stored in separate directories for each test suite:
- /$USER/output_userspace/
- /$USER/output_kernel/
- /$USER/output_bsp/
- /$USER/output_benchmark/

The final HTML report combines results from all test suites into a single viewable report.

## Reference 

Write LAVA test definition:

https://docs.lavasoftware.org/lava/lava_test_shell.html

Test Definition:

https://github.com/Linaro/test-definitions/blob/master/docs/index.md

## License
# WRLavaTests
# WRLavaTests
