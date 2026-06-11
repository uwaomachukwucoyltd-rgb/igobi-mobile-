#!/usr/bin/env bash

git clone https://github.com/flutter/flutter.git -b stable
export PATH="$PATH:`pwd`/flutter/bin"

flutter doctor
flutter pub get
flutter build web --release --no-tree-shake-icons

# Render service may be configured with a publish directory named after the build command.
# Mirror the generated build output into that directory so the deploy step can find it.
if [ -d build/web ]; then
  mkdir -p "flutter build web --no-tree-shake-icons"
  cp -a build/web/. "flutter build web --no-tree-shake-icons/"
fi