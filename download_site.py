import urllib.request
import urllib.parse
import re
import os
import sys

BASE_URL = "https://www.neon-free.ch/en/"
ASSETS_DIR = os.path.abspath("assets")

os.makedirs(ASSETS_DIR, exist_ok=True)

print("Fetching main page HTML...")
req = urllib.request.Request(BASE_URL, headers={'User-Agent': 'Mozilla/5.0'})
html = urllib.request.urlopen(req).read().decode('utf-8')

downloaded_urls = {} # url -> local relative path

def get_local_filename(url):
    parsed = urllib.parse.urlparse(url)
    path = parsed.path
    ext = os.path.splitext(path)[1]
    filename = os.path.basename(path)
    if not filename or len(filename) > 80:
        import hashlib
        filename = hashlib.md5(url.encode('utf-8')).hexdigest() + (ext if ext else '.bin')
    else:
        filename = re.sub(r'[^\w\.-]', '_', filename)
        if not ext and '?' in url:
            filename += '.bin'
    return filename

def download_file(url):
    clean_url = url.replace("&amp;", "&")
    if clean_url in downloaded_urls:
        return downloaded_urls[clean_url]
    
    filename = get_local_filename(clean_url)
    local_file_path = os.path.join(ASSETS_DIR, filename)
    counter = 1
    base_name, extension = os.path.splitext(filename)
    while os.path.exists(local_file_path) and downloaded_urls.get(clean_url) != f"assets/{filename}":
        if downloaded_urls.get(clean_url):
            return downloaded_urls[clean_url]
        filename = f"{base_name}_{counter}{extension}"
        local_file_path = os.path.join(ASSETS_DIR, filename)
        counter += 1

    relative_path = f"assets/{filename}"
    try:
        req = urllib.request.Request(clean_url, headers={'User-Agent': 'Mozilla/5.0'})
        data = urllib.request.urlopen(req).read()
        with open(local_file_path, "wb") as f:
            f.write(data)
        downloaded_urls[clean_url] = relative_path
        print(f"Downloaded: {clean_url} -> {relative_path}")
        return relative_path
    except Exception as e:
        print(f"Failed to download {clean_url}: {e}")
        return clean_url

# 1. Collect JavaScript modules recursively from Framer sites directory
site_js_base = "https://framerusercontent.com/sites/2sqy0TvpLKmUTWPQb4R6c/"

visited_js = set()
js_queue = []

# Find initial scripts in HTML
initial_scripts = re.findall(r'https://framerusercontent\.com/sites/2sqy0TvpLKmUTWPQb4R6c/[^\s\"\'\>\)\(\,]+', html)
for js in initial_scripts:
    js_clean = js.replace("&amp;", "&")
    if js_clean not in visited_js:
        visited_js.add(js_clean)
        js_queue.append(js_clean)

all_script_srcs = re.findall(r'src=[\"\'](https://[^\"]+)[\"\']', html)
for src in all_script_srcs:
    src_clean = src.replace("&amp;", "&")
    if src_clean not in visited_js:
        visited_js.add(src_clean)
        js_queue.append(src_clean)

print(f"Initial JS files found: {len(js_queue)}")

while js_queue:
    current_js = js_queue.pop(0)
    local_path = download_file(current_js)
    
    if "framerusercontent.com" in current_js and (current_js.endswith(".mjs") or current_js.endswith(".js")):
        try:
            with open(os.path.join(ASSETS_DIR, os.path.basename(local_path)), "r", encoding="utf-8") as f:
                content = f.read()
            
            # Find relative imports like import ... from "./rolldown-runtime.Dh6celcD.mjs";
            rel_imports = re.findall(r'from\s*["\'](\./[^"\']+)["\']', content)
            rel_imports += re.findall(r'import\s*["\'](\./[^"\']+)["\']', content)
            rel_imports += re.findall(r'import\s*\(\s*["\'](\./[^"\']+)["\']\s*\)', content)
            
            for rel in rel_imports:
                full_url = urllib.parse.urljoin(site_js_base, rel)
                if full_url not in visited_js:
                    visited_js.add(full_url)
                    js_queue.append(full_url)
                    
            # Find any asset URLs inside JS (fonts, images, etc.)
            asset_urls = re.findall(r'https://framerusercontent\.com/assets/[a-zA-Z0-9\._\-]+', content)
            asset_urls += re.findall(r'https://framerusercontent\.com/images/[a-zA-Z0-9\._\-]+', content)
            for a_url in asset_urls:
                if a_url not in downloaded_urls:
                    download_file(a_url)
        except Exception as e:
            print(f"Error parsing JS {current_js}: {e}")

# 2. Extract and download all images, fonts, media, and styles from HTML
all_urls = set(re.findall(r'https://[^\s\"\'\>\)\(\,\;]+', html))
for url in all_urls:
    clean_url = url.replace("&amp;", "&")
    if any(domain in clean_url for domain in ["framerusercontent.com", "fonts.gstatic.com", "events.framer.com", "fw-cdn.com", "widgets.veritree.com"]):
        download_file(clean_url)

print("Downloaded total files:", len(downloaded_urls))

# Process downloaded JS files to update internal relative imports to point to local JS files if needed
for clean_url, relative_path in list(downloaded_urls.items()):
    if relative_path.endswith(".mjs") or relative_path.endswith(".js"):
        local_file_path = os.path.join(ASSETS_DIR, os.path.basename(relative_path))
        if os.path.exists(local_file_path):
            try:
                with open(local_file_path, "r", encoding="utf-8") as f:
                    js_content = f.read()
                
                # Replace external URLs inside JS with assets/ filename if they were downloaded
                modified = False
                for target_url, target_local in downloaded_urls.items():
                    target_filename = os.path.basename(target_local)
                    if target_url in js_content:
                        js_content = js_content.replace(target_url, f"./{target_filename}")
                        modified = True
                if modified:
                    with open(local_file_path, "w", encoding="utf-8") as f:
                        f.write(js_content)
            except Exception as e:
                print(f"Error rewriting JS contents for {relative_path}: {e}")

# 3. Process HTML to rewrite all URLs to local assets directory
new_html = html
for url, local_path in downloaded_urls.items():
    new_html = new_html.replace(url, local_path)
    new_html = new_html.replace(url.replace("&", "&amp;"), local_path)
    base_url = url.split('?')[0]
    if base_url != url:
        new_html = new_html.replace(base_url, local_path)

with open("index.html", "w", encoding="utf-8") as f:
    f.write(new_html)

print("Saved index.html successfully.")
