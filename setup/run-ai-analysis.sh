#!/bin/bash
# Title: AI-powered test results analysis
# Description: This script analyzes Robot Framework test results using AI (Claude/OpenAI)
#              and posts interpretations as GitHub PR comments
# Author: AI Assistant
#
# Usage:
#   ./run-ai-analysis.sh
#
# Environment variables:
#   LLM_PROVIDER    - AI provider: 'claude' (default) or 'openai'
#   LLM_API_KEY     - API key for the LLM provider (required)
#   LLM_MODEL       - Specific model to use (optional)
#   GITHUB_TOKEN    - GitHub token for posting PR comments (optional)
#   GITHUB_REPOSITORY - Repository in format 'owner/repo' (optional)

set -e

VENV_DIR="venv-ai-analysis"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "🤖 Starting AI test analysis..."

# Check if output.xml files exist
output_files=$(find "$PROJECT_ROOT/packages" -name "output.xml" -path "*/tests/output.xml" 2>/dev/null || true)

if [ -z "$output_files" ]; then
    echo "⚠️  No test output files found. Skipping AI analysis."
    exit 0
fi

echo "📋 Found test output files"

# Check for API key
if [ -z "$LLM_API_KEY" ]; then
    echo "❌ Error: LLM_API_KEY environment variable is not set"
    echo "   Please set your API key before running this script"
    exit 1
fi

# Create virtual environment if it doesn't exist
if [ ! -d "$PROJECT_ROOT/$VENV_DIR" ]; then
    echo "🔧 Creating Python virtual environment..."
    python3 -m venv "$PROJECT_ROOT/$VENV_DIR"
fi

# Activate virtual environment
echo "🔌 Activating virtual environment..."
source "$PROJECT_ROOT/$VENV_DIR/bin/activate"

# Install required packages
echo "📦 Installing AI analysis dependencies..."
pip install --quiet --upgrade pip
pip install --quiet anthropic openai requests

# Run the analysis script
echo "🧠 Running AI analysis..."
python3 "$SCRIPT_DIR/analyze-test-results.py"

# Deactivate virtual environment
deactivate

echo "✅ AI analysis complete"
