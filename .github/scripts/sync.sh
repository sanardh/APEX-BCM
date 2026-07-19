#!/bin/bash
# APX Sync Script
# Generates and commits APX sync reports

set -euo pipefail

# Configuration
DDR_DIR="DDR"
GENERATED_DIR="generated"
SYNC_REPORT="${GENERATED_DIR}/SYNC_REPORT.md"
BASELINE_REPORT="${GENERATED_DIR}/CURRENT_BASELINE.md"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Functions
log_info() {
  echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
  echo -e "${YELLOW}[WARN]${NC} $1" >&2
}

log_error() {
  echo -e "${RED}[ERROR]${NC} $1" >&2
}

# Validate DDR directory exists
if [ ! -d "$DDR_DIR" ]; then
  log_error "$DDR_DIR directory not found"
  exit 1
fi

log_info "Starting APX sync process..."

# Create generated directory
mkdir -p "$GENERATED_DIR"
log_info "Created directory: $GENERATED_DIR"

# Generate SYNC_REPORT.md
log_info "Generating SYNC_REPORT.md..."
cat > "$SYNC_REPORT" <<EOF
# APX Sync Report

**Generated:** $(date -u '+%Y-%m-%d %H:%M:%S UTC')

## DDR Files

EOF

# Add DDR markdown files to report
if find "$DDR_DIR" -type f -name "*.md" -print0 | sort -z | while IFS= read -r -d '' file; do
  echo "- $file" >> "$SYNC_REPORT"
done; then
  log_info "SYNC_REPORT.md generated successfully"
else
  log_warn "No markdown files found in $DDR_DIR"
fi

# Generate CURRENT_BASELINE.md
log_info "Generating CURRENT_BASELINE.md..."
cat > "$BASELINE_REPORT" <<EOF
# CURRENT BASELINE

**Generated:** $(date -u '+%Y-%m-%d %H:%M:%S UTC')

## Locked DDR

EOF

# Add locked DDR files to baseline report
if grep -ril "STATUS: LOCKED" "$DDR_DIR" 2>/dev/null | sort | sed 's|DDR/||' >> "$BASELINE_REPORT" || true; then
  log_info "CURRENT_BASELINE.md generated successfully"
else
  log_warn "No locked DDR files found"
fi

# Copy reports to repository root
log_info "Copying reports to repository root..."
cp "$BASELINE_REPORT" CURRENT_BASELINE.md
cp "$SYNC_REPORT" SYNC_REPORT.md
log_info "Reports copied successfully"

# Configure git
log_info "Configuring git..."
git config user.name "github-actions[bot]"
git config user.email "41898282+github-actions[bot]@users.noreply.github.com"

# Stage changes
git add CURRENT_BASELINE.md SYNC_REPORT.md

# Check for changes
if git diff --cached --quiet; then
  log_info "No changes to commit"
  exit 0
fi

# Commit and push
CHANGES_COUNT=$(git diff --cached --name-only | wc -l)
log_info "Found $CHANGES_COUNT file(s) to commit"

git commit -m "chore: sync APX reports

- Updated SYNC_REPORT.md
- Updated CURRENT_BASELINE.md

Generated at $(date -u '+%Y-%m-%d %H:%M:%S UTC')"

log_info "Pushing changes to remote..."
git push

log_info "APX sync completed successfully!"
