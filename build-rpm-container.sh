#!/usr/bin/env bash
set -Eeuo pipefail

if [[ ! -f pubspec.yaml || ! -d apps/simple_cag_frontend ]]; then
  echo "Run this script from the repository root." >&2
  exit 1
fi

podman run --rm \
  --security-opt label=disable \
  -v "$PWD:/workspace:Z" \
  -w /workspace/apps/simple_cag_frontend \
  docker.io/rockylinux:9 \
  bash -lc '
    set -Eeuo pipefail

    dnf -y install dnf-plugins-core
    dnf config-manager --set-enabled crb
    dnf -y makecache

    dnf -y install \
      git unzip xz zip which tar gzip ca-certificates \
      gcc gcc-c++ clang cmake ninja-build pkgconf-pkg-config \
      gtk3-devel mesa-libGL-devel libstdc++-devel \
      rpm-build rpmdevtools

    git clone --depth 1 --branch 3.50.0 \
      https://github.com/flutter/flutter.git /opt/flutter

    export PATH="/opt/flutter/bin:/root/.pub-cache/bin:$PATH"
    export TAR_OPTIONS=--no-same-owner

    flutter config --enable-linux-desktop
    flutter --version

    # Run from the frontend package; Pub resolves its workspace from the root.
    flutter pub get
    dart pub global activate fastforge 0.6.14

    fastforge release --name=dev --jobs=release-dev-linux-rpm
  '
