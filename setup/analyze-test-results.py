#!/usr/bin/env python3
"""
AI-Powered Test Results Analyzer
Analyzes Robot Framework test results and posts interpretations to GitHub PRs
Author: AI Assistant
"""

import os
import sys
import glob
import json
from pathlib import Path
from typing import Optional, Dict, List
import xml.etree.ElementTree as ET


def parse_robot_output_xml(xml_path: str) -> Dict:
    """Parse Robot Framework output.xml and extract test failures."""
    try:
        tree = ET.parse(xml_path)
        root = tree.getroot()
        
        results = {
            "file": xml_path,
            "total_tests": 0,
            "passed": 0,
            "failed": 0,
            "failures": []
        }
        
        # Parse test cases
        for suite in root.findall('.//suite'):
            suite_name = suite.get('name', 'Unknown Suite')
            
            for test in suite.findall('.//test'):
                test_name = test.get('name', 'Unknown Test')
                results["total_tests"] += 1
                
                status = test.find('status')
                if status is not None:
                    if status.get('status') == 'PASS':
                        results["passed"] += 1
                    else:
                        results["failed"] += 1
                        
                        # Extract failure details
                        failure_msg = status.text or "No error message"
                        
                        # Get the last few keywords to understand context
                        keywords = []
                        for kw in test.findall('.//kw')[-3:]:  # Last 3 keywords
                            kw_name = kw.get('name', '')
                            kw_status = kw.find('status')
                            if kw_status is not None and kw_status.get('status') == 'FAIL':
                                kw_msg = kw.find('.//msg')
                                if kw_msg is not None and kw_msg.text:
                                    keywords.append(f"{kw_name}: {kw_msg.text}")
                        
                        results["failures"].append({
                            "suite": suite_name,
                            "test": test_name,
                            "message": failure_msg,
                            "keywords": keywords
                        })
        
        return results
    except Exception as e:
        print(f"Error parsing {xml_path}: {e}")
        return None


def analyze_with_claude(test_results: List[Dict], api_key: str, model: str = "claude-3-5-sonnet-latest") -> str:
    """Send test results to Claude for analysis."""
    try:
        import anthropic
    except ImportError:
        return "Error: anthropic package not installed. Run: pip install anthropic"
    
    client = anthropic.Anthropic(api_key=api_key)
    
    # Prepare the test results summary
    summary = "# Robot Framework Test Results\n\n"
    
    for result in test_results:
        if result and result["failed"] > 0:
            summary += f"## {Path(result['file']).parent}\n"
            summary += f"- Total: {result['total_tests']}, Failed: {result['failed']}, Passed: {result['passed']}\n\n"
            
            for failure in result["failures"]:
                summary += f"### Test: {failure['test']}\n"
                summary += f"Suite: {failure['suite']}\n"
                summary += f"Error: {failure['message']}\n"
                if failure['keywords']:
                    summary += "Context:\n"
                    for kw in failure['keywords']:
                        summary += f"  - {kw}\n"
                summary += "\n"
    
    if not any(r and r["failed"] > 0 for r in test_results if r):
        return "✅ All tests passed successfully!"
    
    # Call Claude API
    try:
        message = client.messages.create(
            model=model,
            max_tokens=1024,
            messages=[
                {
                    "role": "user",
                    "content": f"""Analyze these Robot Framework test failures and provide a SHORT, OBJECTIVE summary (max 300 words):

{summary}

Provide:
1. A brief overview of what failed
2. The most likely root cause(s)
3. Specific, actionable next steps to fix

Be concise and technical. Focus on practical insights."""
                }
            ]
        )
        
        return message.content[0].text
    except Exception as e:
        return f"Error calling Claude API: {e}"


def analyze_with_openai(test_results: List[Dict], api_key: str, model: str = "gpt-4") -> str:
    """Send test results to OpenAI for analysis."""
    try:
        from openai import OpenAI
    except ImportError:
        return "Error: openai package not installed. Run: pip install openai"
    
    client = OpenAI(api_key=api_key)
    
    # Prepare the test results summary (same as Claude)
    summary = "# Robot Framework Test Results\n\n"
    
    for result in test_results:
        if result and result["failed"] > 0:
            summary += f"## {Path(result['file']).parent}\n"
            summary += f"- Total: {result['total_tests']}, Failed: {result['failed']}, Passed: {result['passed']}\n\n"
            
            for failure in result["failures"]:
                summary += f"### Test: {failure['test']}\n"
                summary += f"Suite: {failure['suite']}\n"
                summary += f"Error: {failure['message']}\n"
                if failure['keywords']:
                    summary += "Context:\n"
                    for kw in failure['keywords']:
                        summary += f"  - {kw}\n"
                summary += "\n"
    
    if not any(r and r["failed"] > 0 for r in test_results if r):
        return "✅ All tests passed successfully!"
    
    # Call OpenAI API
    try:
        response = client.chat.completions.create(
            model=model,
            messages=[
                {
                    "role": "system",
                    "content": "You are a test automation expert analyzing Robot Framework test failures. Provide short, objective, actionable summaries."
                },
                {
                    "role": "user",
                    "content": f"""Analyze these test failures and provide a SHORT summary (max 300 words):

{summary}

Provide:
1. Brief overview of what failed
2. Most likely root cause(s)
3. Specific next steps to fix"""
                }
            ],
            max_tokens=500
        )
        
        return response.choices[0].message.content
    except Exception as e:
        return f"Error calling OpenAI API: {e}"


def post_github_comment(comment: str, github_token: str, repo: str, pr_number: int):
    """Post a comment to a GitHub Pull Request."""
    try:
        import requests
    except ImportError:
        print("Error: requests package not installed")
        return False
    
    url = f"https://api.github.com/repos/{repo}/issues/{pr_number}/comments"
    headers = {
        "Authorization": f"Bearer {github_token}",
        "Accept": "application/vnd.github+json",
        "X-GitHub-Api-Version": "2022-11-28"
    }
    
    # Format the comment with markdown
    formatted_comment = f"""## 🤖 AI Test Analysis

{comment}

---
*Generated by AI-powered test analyzer*
"""
    
    data = {"body": formatted_comment}
    
    try:
        response = requests.post(url, headers=headers, json=data)
        response.raise_for_status()
        print(f"✅ Successfully posted comment to PR #{pr_number}")
        return True
    except Exception as e:
        print(f"Error posting GitHub comment: {e}")
        if hasattr(e, 'response') and e.response is not None:
            print(f"Response: {e.response.text}")
        return False


def main():
    # Configuration from environment variables
    llm_provider = os.getenv('LLM_PROVIDER', 'claude').lower()
    llm_api_key = os.getenv('LLM_API_KEY')
    llm_model = os.getenv('LLM_MODEL', '')
    github_token = os.getenv('GITHUB_TOKEN')
    github_repository = os.getenv('GITHUB_REPOSITORY')
    
    # Get PR number from various sources
    pr_number = None
    if os.getenv('GITHUB_EVENT_NAME') == 'pull_request':
        # Direct PR event
        event_path = os.getenv('GITHUB_EVENT_PATH')
        if event_path and os.path.exists(event_path):
            with open(event_path, 'r') as f:
                event_data = json.load(f)
                pr_number = event_data.get('pull_request', {}).get('number')
    
    if not pr_number:
        # Try to get from ref (refs/pull/123/merge)
        github_ref = os.getenv('GITHUB_REF', '')
        if 'pull' in github_ref:
            parts = github_ref.split('/')
            if len(parts) >= 3 and parts[1] == 'pull':
                try:
                    pr_number = int(parts[2])
                except ValueError:
                    pass
    
    # Validate configuration
    if not llm_api_key:
        print("❌ Error: LLM_API_KEY environment variable not set")
        sys.exit(1)
    
    if not github_token:
        print("⚠️  Warning: GITHUB_TOKEN not set, will not post PR comment")
    
    if not github_repository:
        print("⚠️  Warning: GITHUB_REPOSITORY not set")
    
    # Find all output.xml files
    output_files = glob.glob("packages/*/tests/output.xml")
    
    if not output_files:
        print("⚠️  No output.xml files found in packages/*/tests/")
        sys.exit(0)
    
    print(f"📋 Found {len(output_files)} test output files")
    
    # Parse all test results
    all_results = []
    for xml_file in output_files:
        print(f"📖 Parsing {xml_file}...")
        result = parse_robot_output_xml(xml_file)
        if result:
            all_results.append(result)
            print(f"   Tests: {result['total_tests']}, Failed: {result['failed']}, Passed: {result['passed']}")
    
    if not all_results:
        print("❌ Failed to parse any test results")
        sys.exit(1)
    
    # Analyze with AI
    print(f"\n🤖 Analyzing results with {llm_provider.upper()}...")
    
    if llm_provider == 'claude':
        model = llm_model or "claude-3-5-sonnet-latest"
        analysis = analyze_with_claude(all_results, llm_api_key, model)
    elif llm_provider in ['openai', 'gpt']:
        model = llm_model or "gpt-4"
        analysis = analyze_with_openai(all_results, llm_api_key, model)
    else:
        print(f"❌ Unsupported LLM provider: {llm_provider}")
        print("   Supported: claude, openai")
        sys.exit(1)
    
    print("\n" + "="*60)
    print("AI ANALYSIS:")
    print("="*60)
    print(analysis)
    print("="*60 + "\n")
    
    # Post to GitHub PR if configured
    if github_token and github_repository and pr_number:
        print(f"📝 Posting comment to PR #{pr_number}...")
        post_github_comment(analysis, github_token, github_repository, pr_number)
    elif not pr_number:
        print("ℹ️  Not a pull request event, skipping PR comment")
    else:
        print("ℹ️  GitHub integration not fully configured, skipping PR comment")


if __name__ == "__main__":
    main()
