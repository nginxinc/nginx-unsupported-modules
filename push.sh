#!/usr/bin/env bash

set -o errexit  # abort on nonzero exit status
set -o nounset  # abort on unbound variable
set -o pipefail # don't hide errors within pipes

if ! command -v docker > /dev/null; then
  echo >&2 "Docker must be installed to run build"
  exit 1
fi

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
image_prefix="$1"

if [ "${image_prefix}" == "" ]; then
  echo >&2 "This script requires a single parameter: image_prefix"
  exit 1
fi

container_images="${script_dir}/container_images.txt"

image_names="$(cat "${container_images}")"

for image in ${image_names}; do
  docker tag "${image}" "${image_prefix}${image}"
  docker push "${image_prefix}${image}"
done
