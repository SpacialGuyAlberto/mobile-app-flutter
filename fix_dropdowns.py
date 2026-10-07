import re

with open('lib/screens/projekt/create_segment_screen.dart', 'r') as f:
    content = f.read()

# Use regex to find DropdownButtonFormField<String> or DropdownButtonFormField<String?>
# and insert isExpanded: true, right after value: ...

def replacer(match):
    prefix = match.group(1)
    value_line = match.group(2)
    # Add isExpanded right after value
    # value_line contains the indentation
    indent = re.match(r'^(\s*)', value_line).group(1)
    return f"{prefix}{value_line}\n{indent}isExpanded: true,"

content = re.sub(r'(DropdownButtonFormField<String\??>\(\n)(.*?value:.*?,)', replacer, content)

with open('lib/screens/projekt/create_segment_screen.dart', 'w') as f:
    f.write(content)

