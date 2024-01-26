#!/bin/sh
# Copyright 2019 the Deno authors. All rights reserved. MIT license.
# TODO(everyone): Keep this script simple and easily auditable.

set -e

# check to see if we've been dot-sourced (should work for most POSIX shells)
sourced=0

if [ -n "$ZSH_EVAL_CONTEXT" ]; then 
  case $ZSH_EVAL_CONTEXT in *:file) sourced=1;; esac
elif [ -n "$KSH_VERSION" ]; then
  [ "$(cd $(dirname -- $0) && pwd -P)/$(basename -- $0)" != "$(cd $(dirname -- ${.sh.file}) && pwd -P)/$(basename -- ${.sh.file})" ] && sourced=1
elif [ -n "$BASH_VERSION" ]; then
  (return 0 2>/dev/null) && sourced=1 
else # All other shells: examine $0 for known shell binary filenames
  # Detects `sh` and `dash`; add additional shell filenames as needed.
  case ${0##*/} in sh|dash) sourced=1;; esac
fi

if command -v deno >/dev/null; then
  # already have deno in path
  echo "Deno is in the PATH already."
  if [ $sourced -eq 0 ]; then exit ; else return ; fi
fi


if ! command -v unzip >/dev/null; then
  echo "Error: unzip is required to install Deno (see: https://github.com/denoland/deno_install#unzip-is-required )." 1>&2
  if [ $sourced -eq 0 ]; then exit 1 ; else return 1 ; fi
fi

if [ "$OS" = "Windows_NT" ]; then
  target="x86_64-pc-windows-msvc"
else
  case $(uname -sm) in
  "Darwin x86_64") target="x86_64-apple-darwin" ;;
  "Darwin arm64") target="aarch64-apple-darwin" ;;
  "Linux aarch64")
    echo "Error: Official Deno builds for Linux aarch64 are not available. (see: https://github.com/denoland/deno/issues/1846 )" 1>&2
      if [ $sourced -eq 0 ]; then exit 1 ; else return 1; fi
    ;;
  *) target="x86_64-unknown-linux-gnu" ;;
  esac
fi

if [ $# -eq 0 ]; then
  deno_uri="https://github.com/denoland/deno/releases/latest/download/deno-${target}.zip"
else
  deno_uri="https://github.com/denoland/deno/releases/download/${1}/deno-${target}.zip"
fi

deno_install="${DENO_INSTALL:-$HOME/.deno}"
bin_dir="$deno_install/bin"
exe="$bin_dir/deno"

# check if it is already on disk
if [ -f "$exe" ]; then
  echo "Deno installed already."
  # add to the environment and get out if it works
  export DENO_INSTALL=$deno_install
  export PATH=$DENO_INSTALL/bin:$PATH	
  if command -v deno >/dev/null; then
    if [ $sourced -ne 0 ]; then return; else 
      echo 
      echo Dot-source this script to add the installed deno to the PATH
      echo or
      echo 
      echo "Manually add the directory to your \$HOME/$shell_profile (or similar)"
      echo "  export DENO_INSTALL=\"$deno_install\""
      echo "  export PATH=\"\$DENO_INSTALL/bin:\$PATH\""
      exit
    fi
  fi 
fi

if [ ! -d "$bin_dir" ]; then
  mkdir -p "$bin_dir"
fi

curl --fail --location -s --output "$exe.zip" "$deno_uri"
unzip -d "$bin_dir" -o "$exe.zip"
chmod +x "$exe"
rm "$exe.zip"

echo "Deno was installed successfully to $exe"

if [ $sourced -ne 0 ]; then
  export DENO_INSTALL=$deno_install
  export PATH=$DENO_INSTALL/bin:$PATH
  if [ $sourced -eq 0 ]; then exit ; else return ; fi
fi

if command -v deno >/dev/null; then
  if [ $sourced -eq 0 ]; then exit ; else return ; fi
else
  case $SHELL in
  /bin/zsh) shell_profile=".zshrc" ;;
  *) shell_profile=".bashrc" ;;
  esac
  echo 
  echo Dot-source this script to add the installed deno to the PATH
  echo or
  echo 
  echo "Manually add the directory to your \$HOME/$shell_profile (or similar)"
  echo "  export DENO_INSTALL=\"$deno_install\""
  echo "  export PATH=\"\$DENO_INSTALL/bin:\$PATH\""
fi
echo
