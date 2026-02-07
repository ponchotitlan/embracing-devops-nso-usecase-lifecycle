#!/usr/bin/env python3
"""
Robot Framework Test Results Analyzer using Claude API
Parses Robot Framework XML output and analyzes test results using Claude.
"""

import argparse
import xml.etree.ElementTree as ET
from pathlib import Path
import os
from anthropic import Anthropic


def parse_robot_xml(xml_file):
    """Parse Robot Framework XML output file and extract test results."""
    tree = ET.parse(xml_file)
    root = tree.getroot()
    
    results = {
        'total_tests': 0,
        'passed': 0,
        'failed': 0,
        'test_details': []
    }
    
    # Parse test suites and tests
    for suite in root.findall('.//suite'):
        suite_name = suite.get('name', 'Unknown Suite')
        
        for test in suite.findall('.//test'):
            test_name = test.get('name', 'Unknown Test')
            status = test.find('status')
            
            if status is not None:
                test_status = status.get('status', 'UNKNOWN')
                results['total_tests'] += 1
                
                if test_status == 'PASS':
                    results['passed'] += 1
                elif test_status == 'FAIL':
                    results['failed'] += 1
                
                test_info = {
                    'suite': suite_name,
                    'name': test_name,
                    'status': test_status,
                    'message': status.text or ''
                }
                
                # Extract error messages for failed tests
                if test_status == 'FAIL':
                    results['test_details'].append(test_info)
    
    return results


def format_results_for_claude(results):
    """Format test results into a readable string for Claude analysis."""
    summary = f"""Robot Framework Test Results Summary:
    
Total Tests: {results['total_tests']}
Passed: {results['passed']}
Failed: {results['failed']}
Success Rate: {(results['passed'] / results['total_tests'] * 100) if results['total_tests'] > 0 else 0:.2f}%

"""
    
    if results['failed'] > 0:
        summary += "Failed Tests Details:\n"
        summary += "=" * 80 + "\n"
        
        for test in results['test_details']:
            summary += f"\nSuite: {test['suite']}\n"
            summary += f"Test: {test['name']}\n"
            summary += f"Status: {test['status']}\n"
            if test['message']:
                summary += f"Error Message: {test['message']}\n"
            summary += "-" * 80 + "\n"
    
    return summary


def analyze_with_claude(xml_content, summary_text, api_key):
    """Send test results to Claude API for analysis."""
    client = Anthropic(api_key=api_key)
    
    prompt = f"""Analyze this Robot Framework test XML file and provide a concise report.

CONTEXT: These tests are RESTCONF requests run against a Cisco NSO (Network Services Orchestrator) server.

IMPORTANT: Base your analysis ONLY on what is explicitly present in the XML file below. Do not make assumptions or investigate external factors.

Provide:
1. What tests passed and failed
2. Root cause of each failure (based on error messages in the XML)
3. Specific recommendations to fix the failures

Keep the report concise. Skip timing details, metadata, and general observations.

Complete Robot Framework XML Output:
{xml_content}
"""
    
    message = client.messages.create(
        model="claude-sonnet-4-20250514",
        max_tokens=2000,
        messages=[
            {"role": "user", "content": prompt}
        ]
    )
    
    return message.content[0].text


def main():
    parser = argparse.ArgumentParser(
        description='Analyze Robot Framework test results using Claude API'
    )
    parser.add_argument(
        'xml_file',
        type=str,
        help='Path to Robot Framework XML output file'
    )
    parser.add_argument(
        '--api-key',
        type=str,
        default=None,
        help='Claude API key (or set ANTHROPIC_API_KEY environment variable)'
    )
    
    args = parser.parse_args()
    
    # Get API key from argument or environment
    api_key = args.api_key or os.getenv('ANTHROPIC_API_KEY')
    if not api_key:
        print("Error: Claude API key not provided. Use --api-key or set ANTHROPIC_API_KEY environment variable.")
        return 1
    
    # Check if XML file exists
    xml_path = Path(args.xml_file)
    if not xml_path.exists():
        print(f"Error: XML file not found: {args.xml_file}")
        return 1
    
    print(f"Parsing Robot Framework results from: {args.xml_file}")
    
    # Read the complete XML file
    try:
        with open(args.xml_file, 'r', encoding='utf-8') as f:
            xml_content = f.read()
    except Exception as e:
        print(f"Error reading XML file: {e}")
        return 1
    
    # Parse XML file for quick summary
    try:
        results = parse_robot_xml(args.xml_file)
    except Exception as e:
        print(f"Error parsing XML file: {e}")
        return 1
    
    # Format results for summary
    results_text = format_results_for_claude(results)
    print("\n" + results_text)
    
    # Analyze with Claude using complete XML
    print("\nAnalyzing complete test results with Claude API...")
    print("=" * 80)
    
    try:
        analysis = analyze_with_claude(xml_content, results_text, api_key)
        print("\nClaude Analysis:")
        print("=" * 80)
        print(analysis)
        print("=" * 80)
    except Exception as e:
        print(f"Error calling Claude API: {e}")
        return 1
    
    return 0


if __name__ == '__main__':
    exit(main())
