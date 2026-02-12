#!/bin/bash

if [[ ! -f ./updated ]]; then
  new_version_file=$(cat version.json | jq '.patch= .patch + 1')
  echo $new_version_file >version.json
  version=$(cat ./version.json | jq -r '. | "\(.major).\(.minor).\(.patch)"')
  echo $version >version
  sed -i "s/LABEL version=.*/LABEL version=\"$version\"/" Dockerfile
  touch updated
fi

version=$(cat ./version.json | jq -r '. | "\(.major).\(.minor).\(.patch)"')
echo "Renovating for version $version, dependency $1 from $2 to $3"

if ! grep -q "## $version" ./CHANGELOG.md; then
  echo "Version $version not found, adding to CHANGELOG.md"
  sed -i "/# Changelog/a ## $version" ./CHANGELOG.md
fi

if ! grep -q "* Updated dependency $1 from $2 to $3" ./CHANGELOG.md; then
  echo "adding '* Updated dependency $1 from $2 to $3' to changelog on version $version"
  sed -i "/## $version/a - Updated dependency $1 from $2 to $3" ./CHANGELOG.md
fi
