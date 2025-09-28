#!/bin/bash

# Git Pre-commit Hook: Clear Notebook Outputs
# Automatically clears Jupyter notebook outputs before each commit
# 
# To install this hook:
# cp scripts/git-pre-commit-hook.sh .git/hooks/pre-commit
# chmod +x .git/hooks/pre-commit

# Check if this is a commit (not a merge, rebase, etc.)
if [ -n "$GIT_AUTHOR_DATE" ]; then
    exit 0
fi

# Check if any .ipynb files are being committed
NOTEBOOKS=$(git diff --cached --name-only --diff-filter=ACM | grep '\.ipynb$')

if [ -z "$NOTEBOOKS" ]; then
    # No notebooks in this commit
    exit 0
fi

echo "🧹 Pre-commit: Clearing notebook outputs..."

# Check if jq is available
if ! command -v jq &> /dev/null; then
    echo "❌ Error: jq is required for notebook cleaning"
    echo "Install with: brew install jq (macOS) or apt-get install jq (Ubuntu)"
    exit 1
fi

# Clear outputs from notebooks being committed
for NOTEBOOK in $NOTEBOOKS; do
    if [ -f "$NOTEBOOK" ]; then
        echo "   Cleaning: $NOTEBOOK"
        
        # Clear outputs
        jq '
            .cells[] |= (
                if .cell_type == "code" then
                    .outputs = [] |
                    .execution_count = null |
                    if .metadata then
                        .metadata |= del(.execution)
                    else . end
                else . end
            )
        ' "$NOTEBOOK" > "${NOTEBOOK}.tmp"
        
        if [ $? -eq 0 ]; then
            mv "${NOTEBOOK}.tmp" "$NOTEBOOK"
            # Re-stage the cleaned notebook
            git add "$NOTEBOOK"
        else
            echo "❌ Failed to clean $NOTEBOOK"
            rm -f "${NOTEBOOK}.tmp"
            exit 1
        fi
    fi
done

echo "✅ All notebook outputs cleared"
exit 0