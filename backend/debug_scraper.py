# debug_scraper.py
import httpx

# This script is for debugging purposes only.
# It fetches the raw HTML of the target URL and prints it.

url = "https://b.hatena.ne.jp/hotentry/it"
headers = {'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'}

try:
    with httpx.Client() as client:
        response = client.get(url, headers=headers, timeout=10.0)
        response.raise_for_status()
        print(response.text)
except Exception as e:
    print(f"An error occurred: {e}")
