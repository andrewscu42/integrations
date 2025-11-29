#!/usr/bin/env python3
"""
Generate a human-readable code coverage report from Salesforce test results JSON.

Usage:
    python3 generate-coverage-report.py [test-results.json]

If no file is specified, it will look for test-results.json in the same directory.
"""

import json
import sys
import os

def generate_coverage_report(json_file_path):
    """Generate coverage report from JSON test results."""
    
    # Read the file
    with open(json_file_path, 'r') as f:
        content = f.read()
    
    # Find JSON start (skip any warnings from Salesforce CLI)
    json_start = content.find('{')
    if json_start == -1:
        print("Error: No JSON found in file")
        sys.exit(1)
    
    json_content = content[json_start:]
    
    try:
        data = json.loads(json_content)
    except json.JSONDecodeError as e:
        print(f"Error parsing JSON: {e}")
        sys.exit(1)
    
    # Extract coverage data
    report = []
    report.append("=" * 80)
    report.append("APEX CODE COVERAGE REPORT")
    report.append("=" * 80)
    report.append("")
    
    if 'result' in data and 'coverage' in data['result']:
        coverage_list = data['result']['coverage'].get('coverage', [])
        
        # Sort by class name
        coverage_list.sort(key=lambda x: x.get('name', ''))
        
        for item in coverage_list:
            class_name = item.get('name', 'Unknown')
            total_lines = item.get('totalLines', 0)
            total_covered = item.get('totalCovered', 0)
            covered_percent = item.get('coveredPercent', 0)
            lines = item.get('lines', {})
            
            # Get uncovered lines
            uncovered_lines = [int(line) for line, covered in lines.items() if covered == 0]
            uncovered_lines.sort()
            
            report.append(f"Class: {class_name}")
            report.append(f"  Coverage: {covered_percent}% ({total_covered}/{total_lines} lines)")
            
            if uncovered_lines:
                if len(uncovered_lines) <= 20:
                    report.append(f"  Uncovered Lines: {uncovered_lines}")
                else:
                    report.append(f"  Uncovered Lines: {uncovered_lines[:20]} ... and {len(uncovered_lines) - 20} more")
            
            report.append("")
    
    # Add summary
    if 'result' in data and 'summary' in data['result']:
        summary = data['result']['summary']
        report.append("=" * 80)
        report.append("SUMMARY")
        report.append("=" * 80)
        report.append(f"Tests Ran: {summary.get('testsRan', 0)}")
        report.append(f"Pass Rate: {summary.get('passRate', '0%')}")
        report.append(f"Org Wide Coverage: {summary.get('orgWideCoverage', '0%')}")
        report.append(f"Test Run Coverage: {summary.get('testRunCoverage', '0%')}")
    
    # Write report
    report_file = os.path.join(os.path.dirname(json_file_path), 'coverage-report.txt')
    with open(report_file, 'w') as f:
        f.write('\n'.join(report))
    
    # Print to console
    print('\n'.join(report))
    print(f"\nReport saved to: {report_file}")

if __name__ == '__main__':
    # Get JSON file path from command line or use default
    if len(sys.argv) > 1:
        json_file = sys.argv[1]
    else:
        # Default to test-results.json in the same directory as the script
        script_dir = os.path.dirname(os.path.abspath(__file__))
        json_file = os.path.join(script_dir, 'test-results.json')
    
    if not os.path.exists(json_file):
        print(f"Error: File not found: {json_file}")
        sys.exit(1)
    
    generate_coverage_report(json_file)

