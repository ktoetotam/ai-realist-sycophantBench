#!/bin/bash

# Install Git Hooks for Jupyter Notebook Management
# This script sets up automatic notebook output clearing

echo "🔧 Installing Git Hooks for Notebook Management"
echo "=============================================="

# Check if we're in a git repository
if [ ! -d ".git" ]; then
    echo "❌ Error: Not a git repository. Run 'git init' first."
    exit 1
fi

# Create hooks directory if it doesn't exist
mkdir -p .git/hooks

# Install pre-commit hook
if [ -f "scripts/git-pre-commit-hook.sh" ]; then
    cp scripts/git-pre-commit-hook.sh .git/hooks/pre-commit
    chmod +x .git/hooks/pre-commit
    echo "✅ Installed pre-commit hook: automatic notebook cleaning"
else
    echo "⚠️  Pre-commit hook script not found: scripts/git-pre-commit-hook.sh"
fi

echo
echo "📋 Available Scripts:"
echo "   ./clear_notebook_outputs.sh    - Manual notebook cleaning"
echo "   .git/hooks/pre-commit          - Automatic cleaning on commit"
echo
echo "💡 Usage:"
echo "   Manual: ./clear_notebook_outputs.sh"
echo "   Auto:   git commit -m 'message' (hook runs automatically)"
echo
echo "✅ Git hooks installation complete!"