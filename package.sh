#!/usr/bin/env bash

set -eEuo pipefail

trap 'printf "\n\e[31mError: Exit Status %s (%s)\e[m\n" $? "$(basename "$0")"' ERR

cd "$(dirname "$0")"

echo
echo "Start ($(basename "$0"))"

echo
echo "Packaging"
echo "= = ="

git_remote_name="${GIT_REMOTE_NAME:-origin}"
git_default_branch="${GIT_DEFAULT_BRANCH:-master}"

echo
echo "Remote Name: $git_remote_name"
echo "Default Branch: $git_default_branch"

for gemspec in $(find . -maxdepth 2 -name '*.gemspec'); do
  echo
  path="$(dirname "$gemspec")"
  gem -C "$path" build --force "$(basename "$gemspec")"
done

warning=0

if ! git diff --quiet; then
  echo
  printf "\e[31mWarning: There are local changes\e[m\n"

  warning=1
fi

unpushed_commit_count=$(git rev-list $git_remote_name/$git_default_branch.. --count)
if [ "$unpushed_commit_count" -ne 0 ]; then
  echo
  printf "\e[31mWarning: There are %d unpushed commits\e[m\n" "$unpushed_commit_count"

  warning=1
fi

if [ "$warning" = 1 ] && [ "${PERMIT_WARNINGS:-}" != "on" ]; then
  false
fi

echo
echo "Done ($(basename "$0"))"
