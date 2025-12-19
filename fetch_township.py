import requests
import json
import sys
import io

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

url = "https://opendata.cwa.gov.tw/api/v1/rest/datastore/F-D0047-039"
params = {
    "Authorization": "CWA-25948A02-C4DE-4AA8-9BAC-0AB177BA9854",
    "locationName": "池上鄉",
    "elementName": "MinT,MaxT,PoP12h,Wx"
}

try:
    response = requests.get(url, params=params, verify=False)
    data = response.json()
    with open('township_utf8.json', 'w', encoding='utf-8') as f:
        json.dump(data, f, indent=2, ensure_ascii=False)
    print("Done")
except Exception as e:
    print(f"Error: {e}")
