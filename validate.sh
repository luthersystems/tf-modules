#!/bin/sh

set -euo pipefail
export AWS_DEFAULT_REGION="eu-west-2"
export dirs="$(find . -name *.tf -exec dirname {} \; | sort -u | grep -v examples)"
for dir in $dirs; do
    echo validating "$dir"
    tests_dir="${dir}/tests"
    if [[ -d "$tests_dir" ]]; then
        echo "module has tests, skipping validate of root..."
        continue
    fi
    cd $dir
    terraform init
    terraform validate
    cd - > /dev/null
done
