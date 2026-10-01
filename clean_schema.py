import re

def process_sql():
    with open('fastrand_db copy.sql', 'r', encoding='utf-8', errors='ignore') as f:
        lines = f.readlines()

    clean_lines = []
    in_insert = False
    current_insert = []
    table_name = ""

    for line in lines:
        if '<div class="alert' in line:
            break

        # Check if line starts an INSERT INTO statement
        match = re.match(r'INSERT INTO `([^`]+)`', line, re.IGNORECASE)
        if match:
            in_insert = True
            table_name = match.group(1)
            current_insert = [line]
            if ';' in line:
                in_insert = False
                if table_name == 'ip_whitelist':
                    clean_lines.extend(current_insert)
                current_insert = []
            continue

        if in_insert:
            current_insert.append(line)
            if ';' in line:
                in_insert = False
                if table_name == 'ip_whitelist':
                    clean_lines.extend(current_insert)
                current_insert = []
            continue

        clean_lines.append(line)

    with open('schema.sql', 'w', encoding='utf-8') as f:
        f.writelines(clean_lines)

    print("Clean schema.sql generated successfully!")

if __name__ == '__main__':
    process_sql()
