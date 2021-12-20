#!/usr/bin/env bash

set -o errexit  # abort on nonzero exit status
set -o nounset  # abort on unbound variable
set -o pipefail # don't hide errors within pipes

if ! command -v docker > /dev/null; then
  echo >&2 "Docker must be installed to run build"
  exit 1
fi

version="$1"

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

arch=""
case $(uname -m) in
i386) arch="386" ;;
i686) arch="386" ;;
x86_64) arch="amd64" ;;
aarch64) arch="arm64" ;;
arm) dpkg --print-architecture | grep -q "arm64" && arch="arm64" || arch="arm" ;;
*)
  echo >&2 "Unable to determine system architecture."
  exit 1
  ;;
esac
os="$(uname -s | tr '[:upper:]' '[:lower:]')"
dockerfiles="$(find "${script_dir}" -type f -name 'Dockerfile.*')"

function lib_name() {
   distro_name="$(echo "$1" | cut -d'.' -f2)"
   if [ "${distro_name}" == "alpine" ]; then
     echo 'musl'
   else
     echo 'libc'
   fi
}

# Download NGINX source code
download_dir="${script_dir}/downloads"

if [ ! -d "${download_dir}" ]; then
  mkdir --parents "${download_dir}"
fi

if [ ! -f "${script_dir}/downloads/nginx-${version}.tar.gz" ]; then
  curl --retry 6 --fail --show-error --silent --location --output "${script_dir}/downloads/nginx-${version}.tar.gz" "http://nginx.org/download/nginx-${version}.tar.gz"
fi
sha256sum --check --quiet < "${script_dir}/nginx_source_checksums.txt"

container_images="${script_dir}/container_images.txt"

# Build container images
if [ -f "${container_images}" ]; then
  rm "${container_images}"
fi

for dockerfile in ${dockerfiles}; do
  dirname="$(dirname "${dockerfile}")"
  tag_name="$(basename "${dirname}")"
  lib_name="$(lib_name "$dockerfile")"

  for version in ${versions}; do
    docker build --file "${dockerfile}" --build-arg ARCH="${arch}" --build-arg NGX_VERSION="${version}" --tag "${tag_name}:${os}-${lib_name}-nginx-${version}" "${script_dir}"
    echo "${tag_name}:${os}-${lib_name}-nginx-${version}" >> "${container_images}"
  done
done

echo "Created the following container images:"
cat "${container_images}"
