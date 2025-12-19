import json
import io
import sys

# Force UTF-8 for stdout
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

try:
    with open('weather_hiking_daynight.json', 'r', encoding='utf-8') as f:
        data = json.load(f)
        locations = data['cwaopendata']['Dataset']['Locations']['Location']
        print(f"Total Locations: {len(locations)}")
        for loc in locations:
            name = loc['LocationName']
            if '三叉' in name or '池上' in name or '向陽' in name:
                print(f"Found: {name}")
except Exception as e:
    print(f"Error: {e}")
