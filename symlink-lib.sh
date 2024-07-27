#!/usr/bin/env bash

set -eEuo pipefail

trap 'printf "\n\e[31mError: Exit Status %s (%s)\e[m\n" $? "$(basename "$0")"' ERR

cd "$(dirname "$0")"

echo
echo "Start ($(basename "$0"))"

if [ -z "${LIBRARIES_HOME:-}" ]; then
  echo "LIBRARIES_HOME must be set to the libraries directory path... exiting"
  false
fi

if [ ! -d "$LIBRARIES_HOME" ]; then
  echo "$LIBRARIES_HOME does not exist... exiting"
  false
fi

for gemspec in $(find . -maxdepth 2 -name '*.gemspec'); do
  gem_name=$(ruby -rrubygems -e "puts Gem::Specification.load('$gemspec').name")
  gemspec_path=$(dirname "$gemspec")

  echo
  echo "Symlinking $gem_name"
  echo "- - -"

  (
    cd "$gemspec_path"

    source=$(pwd)
    destination="$LIBRARIES_HOME/$gem_name"

    echo "Source: $source"
    echo "Destination: $destination"
    echo

    if ! [ -L "$destination" ]; then
      cmd="ln -s \"$source\" \"$destination\""
      echo "$cmd"
      eval "$cmd"
    else
      echo "Already symlinked"
    fi
  )
done

echo
echo "Done ($(basename "$0"))"
