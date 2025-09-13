# debug_scraper.py
import httpx
import os

# This script is for debugging purposes only.
# It fetches the raw HTML of the target URL and saves it to a file.

url = "https://news.livedoor.com/article/category/504/"
output_path = os.path.join(os.path.dirname(__file__), "soccer.html")
headers = {'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'}

try:
    with httpx.Client() as client:
        print(f"Fetching HTML from {url}...")
        response = client.get(url, headers=headers, timeout=10.0, follow_redirects=True)
        response.raise_for_status()
        
        with open(output_path, "w", encoding="utf-8") as f:
            f.write(response.text)
        print(f"Successfully saved HTML to {output_path}")
        
except Exception as e:
    print(f"An error occurred: {e}")
