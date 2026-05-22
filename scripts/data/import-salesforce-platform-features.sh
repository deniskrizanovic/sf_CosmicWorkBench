#!/usr/bin/env bash
# Import Salesforce Platform Features data into home-denispoc.
# Wrapper for scripts/import-by-context.sh
#
# Usage:
#   ./scripts/import-salesforce-platform-features.sh           # Import all
#   OBJECT=cfp_System_Context__c ./scripts/import-salesforce-platform-features.sh
#   SLOW=1 ./scripts/import-salesforce-platform-features.sh
exec "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/import-by-context.sh" Salesforce_Platform_Features "$@"
