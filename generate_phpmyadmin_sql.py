import re

with open('fastrand_db copy.sql', 'r', encoding='utf-8', errors='ignore') as f:
    text = f.read()

# Stop at html error
if '<div class="alert' in text:
    text = text.split('<div class="alert')[0]

# Split by SQL statement delimiter (semicolon followed by newline)
# Or match statements
# Pattern to find all INSERT INTO statements
# We want to remove all INSERT INTO `table` EXCEPT `ip_whitelist`

def clean_sql(sql):
    # Regex to match INSERT INTO statements
    # INSERT INTO `table` ... ;
    pattern = re.compile(r'INSERT\s+INTO\s+`([^`]+)`.*?;', re.DOTALL | re.IGNORECASE)
    
    def replacer(match):
        table = match.group(1).lower()
        if table == 'ip_whitelist':
            return match.group(0) # Keep ip_whitelist
        return '' # Remove all other inserts

    result = pattern.sub(replacer, sql)
    return result

cleaned = clean_sql(text)

with open('phpmyadmin_import.sql', 'w', encoding='utf-8') as f:
    f.write(cleaned)

print("phpmyadmin_import.sql created successfully!")
