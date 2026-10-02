import re

with open('fastrand_db copy.sql', 'r', encoding='utf-8', errors='ignore') as f:
    text = f.read()

if '<div class="alert' in text:
    text = text.split('<div class="alert')[0]

# Split by lines
lines = text.splitlines(keepends=True)
clean_lines = []
in_insert = False
table_name = ""

for line in lines:
    m = re.match(r'INSERT\s+INTO\s+`([^`]+)`', line, re.IGNORECASE)
    if m:
        table_name = m.group(1).lower()
        in_insert = True
        if table_name == 'ip_whitelist':
            clean_lines.append(line)
        if ';' in line:
            in_insert = False
        continue

    if in_insert:
        if table_name == 'ip_whitelist':
            clean_lines.append(line)
        if ';' in line:
            in_insert = False
        continue

    # Skip lines that are stray insert data or error dumps
    if line.strip().startswith('(') and not any(k in line for k in ['KEY', 'CONSTRAINT', 'PRIMARY', 'UNIQUE']):
        # If we are not inside a CREATE TABLE, skip
        continue

    clean_lines.append(line)

with open('phpmyadmin_tables_only.sql', 'w', encoding='utf-8') as f:
    f.writelines(clean_lines)

print("phpmyadmin_tables_only.sql created successfully!")
