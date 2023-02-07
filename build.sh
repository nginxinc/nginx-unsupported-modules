#!/usr/bin/env bash

set -o errexit  # abort on nonzero exit status
set -o pipefail # don't hide errors within pipes

version="$1"
if [ "${version}" == "" ]; then
  echo >&2 "The first parameter to the build script must be the nginx version"
  exit 1
fi

dockerfile="$2"
if [ "${dockerfile}" == "" ]; then
  echo >&2 "The second parameter to the build script must be the relative dockerfile path"
  exit 1
fi

set -o nounset  # abort on unbound variable

if ! command -v docker > /dev/null; then
  echo >&2 "Docker must be installed to run build"
  exit 1
fi

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

function lib_name() {
   distro_name="${1##*.}"
   if [ "${distro_name}" == "alpine" ]; then
     echo 'musl'
   else
     echo 'libc'
   fi
}

echo "Building images for NGINX ${version}"

# Download NGINX source code
download_dir="${script_dir}/downloads"

if [ ! -d "${download_dir}" ]; then
  mkdir --parents "${download_dir}"
fi

container_images="${script_dir}/container_images-$(basename ${dockerfile})-${version}.txt"

# Build container images
if [ -f "${container_images}" ]; then
  rm "${container_images}"
fi

dirname="$(dirname "${dockerfile}")"
tag_name="$(basename "${dirname}")"
lib_name="$(lib_name "$dockerfile")"

# Enable docker build kit
export DOCKER_BUILDKIT=1

# Base images need to be processed differently because they are squashed and
# they do not require downloading NGINX source code.
if echo "$dockerfile" | grep --quiet "base"; then
  docker build --file "${dockerfile}" --build-arg ARCH="${arch}" --tag "${arch}/${tag_name}-base:${os}-${lib_name}" "${script_dir}"
  docker tag "${arch}/${tag_name}-base:${os}-${lib_name}" "ghcr.io/nginxinc/${arch}/${tag_name}-base:${os}-${lib_name}"
  echo "${arch}/${tag_name}-base:${os}-${lib_name}" >> "${container_images}"
else
  if [ ! -f "${script_dir}/downloads/nginx-${version}.tar.gz.asc" ]; then
    echo "Downloading http://nginx.org/download/nginx-${version}.tar.gz.asc -> ${script_dir}/downloads/nginx-${version}.tar.gz.asc"
    curl --retry 6 --fail --show-error --silent --location --output "${script_dir}/downloads/nginx-${version}.tar.gz.asc" "http://nginx.org/download/nginx-${version}.tar.gz.asc"
  fi
  if [ ! -f "${script_dir}/downloads/nginx-${version}.tar.gz" ]; then
    echo "Downloading http://nginx.org/download/nginx-${version}.tar.gz -> ${script_dir}/downloads/nginx-${version}.tar.gz"
    curl --retry 6 --fail --show-error --silent --location --output "${script_dir}/downloads/nginx-${version}.tar.gz" "http://nginx.org/download/nginx-${version}.tar.gz"
    if ! gpg --homedir "${script_dir}/.gnupg" --verify "${script_dir}/downloads/nginx-${version}.tar.gz.asc" "${script_dir}/downloads/nginx-${version}.tar.gz"; then
      echo >&2 "Could not verify integrity of NGINX archive: ${script_dir}/downloads/nginx-${version}.tar.gz"
      exit 2
    fi
  fi

  docker build --file "${dockerfile}" --build-arg ARCH="${arch}" --build-arg NGX_VERSION="${version}" --tag "${arch}/${tag_name}:${os}-${lib_name}-nginx-${version}" "${script_dir}"
  echo "${arch}/${tag_name}:${os}-${lib_name}-nginx-${version}" >> "${container_images}"
fi

echo "Created the following container images:"
cat "${container_images}"
