import re

with open('fastrand_db copy.sql', 'r', encoding='utf-8', errors='ignore') as f:
    text = f.read()

if '<div class="alert' in text:
    text = text.split('<div class="alert')[0]

lines = text.splitlines(keepends=True)
clean = []
in_insert = False
keep_insert = False

for line in lines:
    m = re.match(r'INSERT INTO `([^`]+)`', line, re.IGNORECASE)
    if m:
        table = m.group(1).lower()
        in_insert = True
        keep_insert = (table == 'ip_whitelist')
        if keep_insert:
            clean.append(line)
        if ';' in line:
            in_insert = False
            keep_insert = False
        continue

    if in_insert:
        if keep_insert:
            clean.append(line)
        if ';' in line:
            in_insert = False
            keep_insert = False
        continue

    clean.append(line)

with open('db_schema_ready.sql', 'w', encoding='utf-8') as f:
    f.writelines(clean)

print("Generated db_schema_ready.sql successfully. Total lines:", len(clean))
