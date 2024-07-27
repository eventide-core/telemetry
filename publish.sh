#!/usr/bin/env bash

set -eEuo pipefail

trap 'printf "\n\e[31mError: Exit Status %s (%s)\e[m\n" $? "$(basename "$0")"' ERR

cd "$(dirname "$0")"

echo
echo "Start ($(basename "$0"))"

rm -f {.,*}/*.gem

./package.sh

echo
echo "Publishing"
echo "= = ="

if [ -z "${RUBYGEMS_AUTHORITY_PATH:-}" ]; then
  printf "\n\e[31mError: RUBYGEMS_AUTHORITY_PATH is not set\e[39m\n"
  false
fi
rubygems_authority_path=$RUBYGEMS_AUTHORITY_PATH
rubygems_authority_access_key=${RUBYGEMS_AUTHORITY_ACCESS_KEY:-}

echo
echo "Rubygems Authority: $rubygems_authority_path"
echo "Rubygems Access Key: ${rubygems_authority_access_key:-(none)}"

for gem in $(find . -maxdepth 2 -name '*.gem'); do
  echo

  cmd="gem push"
  if [ -n "$rubygems_authority_access_key" ]; then
    cmd="$cmd --key $rubygems_authority_access_key"
  fi
  cmd="$cmd --host $rubygems_authority_path \"$gem\""

  echo "$cmd"
  eval "$cmd || true"
done

echo
echo "Done ($(basename "$0"))"
