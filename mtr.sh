#!/bin/bash

source oss_scripts/configure.sh
bazel build --enable_runfiles oss_scripts/pip_package/build_pip_package
./bazel-bin/oss_scripts/pip_package/build_pip_package /artifacts