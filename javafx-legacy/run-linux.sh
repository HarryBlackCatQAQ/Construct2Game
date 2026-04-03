#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"
chmod +x mvnw
./mvnw -DskipTests javafx:run
