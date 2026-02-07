#!/bin/bash
###############################################################################
# AI Test Analysis Script
# Analyzes Robot Framework test results using Claude API and posts to PR
###############################################################################

set -e

echo "🤖 Starting AI Test Analysis..."

# Create virtual environment
echo "Setting up virtual environment..."
python3 -m venv test-analysis-venv
source test-analysis-venv/bin/activate

# Install dependencies
echo "Installing dependencies..."
pip install -q -r requirements.txt

# Find Robot Framework XML output files in packages/*/tests/
echo "Looking for test results..."
XML_FILES=$(find packages/*/tests -name "output.xml" -type f 2>/dev/null || true)

if [ -z "$XML_FILES" ]; then
  echo "⚠️ No Robot Framework output.xml files found in packages/*/tests/"
  exit 0
fi

# Analyze each XML file and combine results
echo "### 🤖 Test Analysis" > combined_analysis.md
echo "" >> combined_analysis.md

for xml_file in $XML_FILES; do
  echo "Analyzing $xml_file..."
  
  # Get the service name from the path (e.g., packages/acl-rfs/tests/output.xml -> acl-rfs)
  service_name=$(echo "$xml_file" | sed 's|packages/\([^/]*\)/tests/output.xml|\1|')
  
  echo "**$service_name**" >> combined_analysis.md
  echo "" >> combined_analysis.md
  python setup/ai_test_analysis.py "$xml_file" >> combined_analysis.md 2>&1 || echo "⚠️ Analysis failed" >> combined_analysis.md
  echo "" >> combined_analysis.md
done

# Post to PR if this is a pull request
if [ -n "$PR_NUMBER" ]; then
  echo "Posting analysis to PR #$PR_NUMBER..."
  
  COMMENT_BODY=$(cat combined_analysis.md | jq -Rs .)
  
  curl -s -X POST \
    -H "Authorization: token $GITHUB_TOKEN" \
    -H "Accept: application/vnd.github.v3+json" \
    "https://api.github.com/repos/${GITHUB_REPOSITORY}/issues/${PR_NUMBER}/comments" \
    -d "{\"body\": $COMMENT_BODY}"
  
  echo "✅ Posted AI analysis to PR #$PR_NUMBER"
else
  echo "ℹ️ Not a PR event - displaying analysis:"
  cat combined_analysis.md
fi

# Cleanup
deactivate
rm -rf test-analysis-venv

echo "✅ AI Test Analysis completed"
