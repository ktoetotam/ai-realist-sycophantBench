#!/bin/bash

# Clear Notebook Outputs Script
# Removes all execution outputs and execution counts from Jupyter notebooks
# Useful for cleaning notebooks before git commits

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🧹 Clearing Jupyter Notebook Outputs${NC}"
echo "======================================"

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    echo -e "${RED}❌ Error: jq is required but not installed.${NC}"
    echo "Install with: brew install jq (macOS) or apt-get install jq (Ubuntu)"
    exit 1
fi

# Find all .ipynb files
NOTEBOOK_DIR="notebooks"
NOTEBOOKS=$(find "$NOTEBOOK_DIR" -name "*.ipynb" -type f 2>/dev/null)

if [ -z "$NOTEBOOKS" ]; then
    echo -e "${YELLOW}⚠️  No Jupyter notebooks found in $NOTEBOOK_DIR${NC}"
    exit 0
fi

# Count notebooks
NOTEBOOK_COUNT=$(echo "$NOTEBOOKS" | wc -l | tr -d ' ')
echo -e "${BLUE}📁 Found $NOTEBOOK_COUNT notebook(s) to clean${NC}"
echo

# Process each notebook
PROCESSED=0
ERRORS=0

for NOTEBOOK in $NOTEBOOKS; do
    echo -e "${BLUE}🔄 Processing: $NOTEBOOK${NC}"
    
    # Check if file exists and is readable
    if [ ! -r "$NOTEBOOK" ]; then
        echo -e "   ${RED}❌ Cannot read file${NC}"
        ((ERRORS++))
        continue
    fi
    
    # Create backup
    BACKUP="${NOTEBOOK}.backup.$(date +%s)"
    cp "$NOTEBOOK" "$BACKUP"
    
    # Clear outputs using jq
    # This removes:
    # - outputs array
    # - execution_count
    # - metadata.execution
    if jq '
        .cells[] |= (
            if .cell_type == "code" then
                .outputs = [] |
                .execution_count = null |
                if .metadata then
                    .metadata |= del(.execution)
                else . end
            else . end
        )
    ' "$NOTEBOOK" > "${NOTEBOOK}.tmp"; then
        
        # Replace original with cleaned version
        mv "${NOTEBOOK}.tmp" "$NOTEBOOK"
        
        # Remove backup if successful
        rm "$BACKUP"
        
        echo -e "   ${GREEN}✅ Cleared outputs${NC}"
        ((PROCESSED++))
    else
        echo -e "   ${RED}❌ Failed to process (restored from backup)${NC}"
        mv "$BACKUP" "$NOTEBOOK"
        rm -f "${NOTEBOOK}.tmp"
        ((ERRORS++))
    fi
    echo
done

# Summary
echo "======================================"
echo -e "${GREEN}✅ Successfully processed: $PROCESSED notebooks${NC}"
if [ $ERRORS -gt 0 ]; then
    echo -e "${RED}❌ Errors encountered: $ERRORS notebooks${NC}"
fi

echo
echo -e "${BLUE}📝 What was cleared:${NC}"
echo "   • All cell outputs"
echo "   • Execution counts"
echo "   • Execution metadata"
echo
echo -e "${YELLOW}💡 Tip: Add this to your git workflow:${NC}"
echo "   ./clear_notebook_outputs.sh && git add notebooks/ && git commit"

# Exit with error code if there were any errors
exit $ERRORS