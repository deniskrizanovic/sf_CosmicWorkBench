#!/usr/bin/env bash
# Import HomesNSW - Maintenance App data into home-denispoc.
# Wrapper for scripts/import-by-context.sh
exec "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/import-by-context.sh" HomesNSW_-_Maintenance_App "$@"
