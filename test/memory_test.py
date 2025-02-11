#!/usr/bin/python3
import subprocess
import re
from datetime import datetime
import json
import psutil
import time
import os

class SolanaMemoryAnalyzer:
    def __init__(self, log_file="memory_stats.json"):
        script_dir = os.path.dirname(os.path.abspath(__file__)) # абсолютный путь к директории скрипта
        self.log_file = os.path.join(script_dir, log_file) # Объединяем путь к директории с именем файла лога
        print(f"Log file path: {self.log_file}")
        
    def get_solana_process_info(self):
        solana_processes = []
        for proc in psutil.process_iter(['pid', 'name', 'memory_info']):
            if 'solana' in proc.info['name']:
                mem_info = proc.info['memory_info']
                solana_processes.append({
                    'pid': proc.info['pid'],
                    'name': proc.info['name'],
                    'rss': mem_info.rss,
                    'vms': mem_info.vms,
                    'shared': mem_info.shared,
                    'text': mem_info.text,
                    'lib': mem_info.lib,
                    'data': mem_info.data,
                    'dirty': mem_info.dirty
                })
        return solana_processes

    def read_buddyinfo(self):
        with open('/proc/buddyinfo', 'r') as f:
            lines = f.readlines()
        
        zones_stats = {}
        for line in lines:
            if 'Normal' in line:  # Фокус только на Normal зоне
                parts = line.split()
                node = parts[1].rstrip(',')
                zone = parts[3].rstrip(',')
                orders = [int(x) for x in parts[4:]]
                zones_stats[f"{node}_{zone}"] = {
                    'orders': orders,
                    'fragmentation_index': self.calculate_fragmentation_index(orders),
                    'large_blocks_available': sum(orders[8:])  # Сумма блоков размером 2^8 страниц и больше
                }
        return zones_stats
    
    def calculate_fragmentation_index(self, orders):
        total_pages = sum(orders)
        if total_pages == 0:
            return 0
        weighted_sum = sum(order * (2**i) for i, order in enumerate(orders))
        max_order = len(orders) - 1
        ideal_weighted_sum = total_pages * (2**max_order)
        return (weighted_sum / ideal_weighted_sum) * 100

    def get_memory_pressure(self):
        try:
            with open('/proc/pressure/memory', 'r') as f:
                pressure_data = f.read().strip().split('\n')
            pressure_stats = {}
            for line in pressure_data:
                kind, stats = line.split(' ', 1)
                pressure_stats[kind] = {
                    k: float(v) for k, v in 
                    [pair.split('=') for pair in stats.split(' ')]
                }
            return pressure_stats
        except FileNotFoundError:
            return None

    def collect_stats(self):
        timestamp = datetime.now().isoformat()
        stats = {
            'timestamp': timestamp,
            'solana_processes': self.get_solana_process_info(),
            'buddyinfo': self.read_buddyinfo(),
            'memory_pressure': self.get_memory_pressure(),
            'system_memory': dict(psutil.virtual_memory()._asdict())
        }
        
        try:
            with open(self.log_file, 'r') as f:
                log_data = json.load(f)
        except (FileNotFoundError, json.JSONDecodeError):
            log_data = []
            
        log_data.append(stats)
        with open(self.log_file, 'w') as f:
            json.dump(log_data, f, indent=2)
            
        return stats

    def analyze_trends(self):
        try:
            with open(self.log_file, 'r') as f:
                log_data = json.load(f)
        except (FileNotFoundError, json.JSONDecodeError):
            return "No historical data available"
            
        if len(log_data) < 2:
            return "Need more data points for trend analysis"
        
        analysis = {
            'memory_usage': self.analyze_memory_usage(log_data),
            'fragmentation': self.analyze_fragmentation(log_data),
            'pressure': self.analyze_pressure(log_data)
        }
        
        return analysis

    def analyze_memory_usage(self, log_data):
        solana_memory = []
        for entry in log_data:
            if 'solana_processes' in entry:
                total_rss = sum(p['rss'] for p in entry['solana_processes'])
                solana_memory.append(total_rss)
        
        if not solana_memory:
            return None
            
        return {
            'current': solana_memory[-1],
            'min': min(solana_memory),
            'max': max(solana_memory),
            'avg': sum(solana_memory) / len(solana_memory)
        }

if __name__ == "__main__":
    analyzer = SolanaMemoryAnalyzer()
    stats = analyzer.collect_stats()
    print("\nSolana Memory Statistics:")
    print(json.dumps(stats, indent=2))
    
    trends = analyzer.analyze_trends()
    print("\nMemory Usage Trends:")
    print(json.dumps(trends, indent=2))
