import re

with open('fastrand_db copy.sql', 'r', encoding='utf-8', errors='ignore') as f:
    text = f.read()

if '<div class="alert' in text:
    text = text.split('<div class="alert')[0]

lines = text.splitlines(keepends=True)
clean_lines = []
in_insert = False
is_ip_whitelist = False

for line in lines:
    m = re.match(r'INSERT INTO `([^`]+)`', line, re.IGNORECASE)
    if m:
        table = m.group(1)
        in_insert = True
        is_ip_whitelist = (table == 'ip_whitelist')
        if is_ip_whitelist:
            clean_lines.append(line)
        if ';' in line:
            in_insert = False
        continue

    if in_insert:
        if is_ip_whitelist:
            clean_lines.append(line)
        if ';' in line:
            in_insert = False
        continue

    clean_lines.append(line)

with open('schema_clean.sql', 'w', encoding='utf-8') as f:
    f.writelines(clean_lines)

print("Finished: schema_clean.sql created successfully.")
