#!/usr/bin/env bash
# Installs the tools of script/check into <directory> and, in a GitHub Actions job, adds the directory to the PATH
# of the later steps (GITHUB_PATH):
# - the release binaries of tools/releases.txt (linux x86_64), each verified against its pinned SHA-256;
# - the Python tools of tools/requirements.txt, into a virtual environment, every package pinned by its hashes.
# Usage: script/install_tools.sh <directory> [tool...]   (a tool of tools/releases.txt, or `python` for the Python
#                                                       tools; no tool: all of them)
#        script/install_tools.sh --list   (prints "<tool> <version> <GitHub repository>" for every release binary)
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly root

# The GitHub repository whose releases publish the tool.
repository() {
  case "${1}" in
    actionlint) echo rhysd/actionlint ;;
    editorconfig-checker) echo editorconfig-checker/editorconfig-checker ;;
    gitleaks) echo gitleaks/gitleaks ;;
    shfmt) echo mvdan/sh ;;
    *)
      echo "Unknown tool: ${1}" >&2
      return 1
      ;;
  esac
}

# The release asset of a tool, relative to the release downloads of its repository.
asset() {
  case "${1}" in
    actionlint) echo "v${2}/actionlint_${2}_linux_amd64.tar.gz" ;;
    editorconfig-checker) echo "v${2}/editorconfig-checker-linux-amd64.tar.gz" ;;
    gitleaks) echo "v${2}/gitleaks_${2}_linux_x64.tar.gz" ;;
    shfmt) echo "v${2}/shfmt_v${2}_linux_amd64" ;;
    *) return 1 ;;
  esac
}

# "<tool> <version> <sha256>" of every pinned release binary.
pins=$(grep -v '^#' "${root}/tools/releases.txt")
readonly pins

install_release() {
  local tool=${1} version=${2} sha256=${3} directory=${4}
  local repo path download
  repo=$(repository "${tool}")
  path=$(asset "${tool}" "${version}")
  download="$(mktemp -d)/${path##*/}"
  curl --fail --silent --show-error --location --output "${download}" \
    "https://github.com/${repo}/releases/download/${path}"
  echo "${sha256}  ${download}" | sha256sum --check --strict
  case "${tool}" in
    shfmt) install -m 0755 "${download}" "${directory}/shfmt" ;;
    *) tar -xzf "${download}" -C "${directory}" "${tool}" ;;
  esac
}

install_python_tools() {
  local directory=${1} environment="${1}/python" tool
  python3 -m venv "${environment}"
  "${environment}/bin/python" -m pip install --quiet --disable-pip-version-check --require-hashes \
    --only-binary :all: --requirement "${root}/tools/requirements.txt"
  for tool in rumdl shellcheck typos yamllint zizmor; do
    ln -sf "${environment}/bin/${tool}" "${directory}/${tool}"
  done
}

main() {
  local tool version sha256 repo
  if [[ ${1:-} == --list ]]; then
    while read -r tool version _; do
      repo=$(repository "${tool}")
      echo "${tool} ${version} ${repo}"
    done <<< "${pins}"
    return
  fi
  local directory=${1:?Usage: script/install_tools.sh <directory> [tool...]}
  shift
  local wanted=" ${*} "
  mkdir -p "${directory}"
  directory=$(cd "${directory}" && pwd)
  while read -r tool version sha256; do
    if [[ $# -eq 0 || ${wanted} == *" ${tool} "* ]]; then
      install_release "${tool}" "${version}" "${sha256}" "${directory}"
    fi
  done <<< "${pins}"
  if [[ $# -eq 0 || ${wanted} == *" python "* ]]; then
    install_python_tools "${directory}"
  fi
  if [[ -n ${GITHUB_PATH:-} ]]; then
    echo "${directory}" >> "${GITHUB_PATH}"
  fi
}

main "$@"
