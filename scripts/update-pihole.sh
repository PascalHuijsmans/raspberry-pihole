#!/usr/bin/env bash

set -euo pipefail

PIHOLE_SKIP_OS_CHECK=true pihole -up
pihole -g