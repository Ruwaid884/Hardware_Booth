#!/usr/bin/env python3
import os
import json
import re
from pathlib import Path

def parse_synthesis_report(report_path):
    """Parse synthesis report to extract area, power, and timing information"""
    metrics = {
        'area': 0,
        'power': 0,
        'delay': 0,
    }
    
    if not os.path.exists(report_path):
        print(f"Warning: Synthesis report not found at {report_path}")
        return metrics
    
    try:
        with open(report_path, 'r') as f:
            content = f.read()
            
        # Example patterns - adjust based on your synthesis tool's output format
        area_match = re.search(r'Total cell area:\s*(\d+\.?\d*)', content)
        power_match = re.search(r'Total dynamic power:\s*(\d+\.?\d*)\s*mW', content)
        delay_match = re.search(r'Critical path delay:\s*(\d+\.?\d*)\s*ns', content)
        
        if area_match:
            metrics['area'] = float(area_match.group(1))
        if power_match:
            metrics['power'] = float(power_match.group(1))
        if delay_match:
            metrics['delay'] = float(delay_match.group(1))
            
    except Exception as e:
        print(f"Error parsing synthesis report {report_path}: {str(e)}")
    
    return metrics

def parse_simulation_results(results_path):
    """Parse simulation results to extract throughput information"""
    throughput = 0
    
    if not os.path.exists(results_path):
        print(f"Warning: Simulation results not found at {results_path}")
        return throughput
    
    try:
        with open(results_path, 'r') as f:
            content = f.read()
            
        # Example pattern - adjust based on your simulation output format
        throughput_match = re.search(r'Throughput:\s*(\d+\.?\d*)\s*MHz', content)
        
        if throughput_match:
            throughput = float(throughput_match.group(1))
            
    except Exception as e:
        print(f"Error parsing simulation results {results_path}: {str(e)}")
    
    return throughput

def collect_all_metrics():
    """Collect metrics from all multiplier implementations"""
    base_dir = Path(__file__).parent.parent.parent
    metrics = {}
    
    # Define paths to your multiplier implementations
    implementations = {
        '8-bit Booth Signed': {
            'synthesis_report': base_dir / '8-bit modified booth multiplier with CLA_ripple adder' / 'synthesis_report.txt',
            'simulation_results': base_dir / '8-bit modified booth multiplier with CLA_ripple adder' / 'simulation_results.txt',
            'rtl_code': base_dir / '8-bit modified booth multiplier with CLA_ripple adder' / 'multiplier.v',
        },
        '8-bit Booth Unsigned': {
            'synthesis_report': base_dir / '8-bit unsigned modified booth multiplier with CLA_ripple adder' / 'synthesis_report.txt',
            'simulation_results': base_dir / '8-bit unsigned modified booth multiplier with CLA_ripple adder' / 'simulation_results.txt',
            'rtl_code': base_dir / '8-bit unsigned modified booth multiplier with CLA_ripple adder' / 'multiplier.v',
        },
        '16-bit Wallace Tree Signed': {
            'synthesis_report': base_dir / '16-bit signed multiplier using wallace tree' / 'synthesis_report.txt',
            'simulation_results': base_dir / '16-bit signed multiplier using wallace tree' / 'simulation_results.txt',
            'rtl_code': base_dir / '16-bit signed multiplier using wallace tree' / 'multiplier.v',
        },
        '16-bit Wallace Tree Unsigned': {
            'synthesis_report': base_dir / '16-bit unsigned multiplier using wallace tree' / 'synthesis_report.txt',
            'simulation_results': base_dir / '16-bit unsigned multiplier using wallace tree' / 'simulation_results.txt',
            'rtl_code': base_dir / '16-bit unsigned multiplier using wallace tree' / 'multiplier.v',
        },
        '16-bit Array Signed': {
            'synthesis_report': base_dir / 'Booth algorithm array multiplier' / 'synthesis_report.txt',
            'simulation_results': base_dir / 'Booth algorithm array multiplier' / 'simulation_results.txt',
            'rtl_code': base_dir / 'Booth algorithm array multiplier' / 'multiplier.v',
        },
        '16-bit Array Unsigned': {
            'synthesis_report': base_dir / 'Array multiplier for unsigned nos' / 'synthesis_report.txt',
            'simulation_results': base_dir / 'Array multiplier for unsigned nos' / 'simulation_results.txt',
            'rtl_code': base_dir / 'Array multiplier for unsigned nos' / 'multiplier.v',
        },
    }
    
    for name, paths in implementations.items():
        print(f"\nProcessing {name}...")
        metrics[name] = {
            **parse_synthesis_report(paths['synthesis_report']),
            'throughput': parse_simulation_results(paths['simulation_results']),
            'synthesis_report': str(paths['synthesis_report']),
            'simulation_results': str(paths['simulation_results']),
            'rtl_code': str(paths['rtl_code']),
        }
        print(f"Collected metrics for {name}:")
        print(f"  Area: {metrics[name]['area']} gates")
        print(f"  Power: {metrics[name]['power']} mW")
        print(f"  Delay: {metrics[name]['delay']} ns")
        print(f"  Throughput: {metrics[name]['throughput']} MHz")
    
    return metrics

if __name__ == '__main__':
    print("Starting metrics collection...")
    metrics = collect_all_metrics()
    
    # Save metrics to a JSON file
    output_path = Path(__file__).parent.parent / 'src' / 'data' / 'metrics.json'
    output_path.parent.mkdir(parents=True, exist_ok=True)
    
    with open(output_path, 'w') as f:
        json.dump(metrics, f, indent=2)
    
    print(f"\nMetrics collected and saved to {output_path}") 