import os
import re

ASSETS_DIR = 'assets'
js_files = [os.path.join(ASSETS_DIR, f) for f in os.listdir(ASSETS_DIR) if f.endswith('.mjs') or f.endswith('.js')]

missing = set()
for js_path in js_files:
    with open(js_path, 'r', encoding='utf-8', errors='ignore') as f:
        content = f.read()
    rel = re.findall(r'from\s*["\'](\./[^"\']+)["\']', content)
    rel += re.findall(r'import\s*["\'](\./[^"\']+)["\']', content)
    for r_import in rel:
        target = r_import.replace('./', '')
        if not os.path.exists(os.path.join(ASSETS_DIR, target)):
            missing.add(target)

print('Missing JS files count:', len(missing))
if missing:
    print('Missing JS files:', list(missing))
