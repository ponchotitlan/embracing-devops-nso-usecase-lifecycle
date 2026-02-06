#!/bin/bash
# Post test results as a PR comment

SUMMARY="## 🤖 Test Results\n\n"

for xml in packages/*/tests/output.xml; do
  if [ -f "$xml" ]; then
    pkg=$(echo $xml | cut -d'/' -f2)
    pass=$(grep -o 'pass="[0-9]*"' "$xml" | head -1 | grep -o '[0-9]*' || echo "0")
    fail=$(grep -o 'fail="[0-9]*"' "$xml" | head -1 | grep -o '[0-9]*' || echo "0")
    if [ "$fail" -gt 0 ]; then
      SUMMARY+="- **$pkg**: ❌ $fail failed, ✅ $pass passed\n"
    else
      SUMMARY+="- **$pkg**: ✅ $pass passed\n"
    fi
  fi
done

# Only post comment if PR_NUMBER is set (we're in a PR context)
if [ -n "$PR_NUMBER" ]; then
  echo "Posting test results to PR #$PR_NUMBER..."
  echo -e "$SUMMARY" | jq -Rs '{body: .}' | \
  curl -X POST -H "Authorization: token $GITHUB_TOKEN" \
    -H "Accept: application/vnd.github.v3+json" \
    "https://api.github.com/repos/$GITHUB_REPOSITORY/issues/$PR_NUMBER/comments" \
    -d @-
else
  echo "Not in a PR context, skipping comment."
  echo -e "$SUMMARY"
fi
