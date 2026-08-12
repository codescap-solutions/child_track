import sys

def check(file_path):
    with open(file_path, 'r') as f:
        content = f.read()

    lines = content.split('\n')
    
    stack = []
    
    for i in range(936, 1286):
        line = lines[i]
        for j, char in enumerate(line):
            if char in ['{', '[', '(']:
                stack.append((char, i+1, j+1))
            elif char in ['}', ']', ')']:
                if stack:
                    top_char, top_line, top_col = stack[-1]
                    if (char == '}' and top_char == '{') or \
                       (char == ']' and top_char == '[') or \
                       (char == ')' and top_char == '('):
                        stack.pop()
                    else:
                        print(f"Mismatch! Expected match for '{top_char}' from ({top_line}, {top_col}), but found '{char}' at ({i+1}, {j+1})")
                        stack.pop()
                else:
                    print(f"Extra '{char}' found at line {i+1}, col {j+1}")

    print("Remaining open brackets at line 1285:")
    for b in stack:
        print(b)

check('lib/app/home/view/home_page.dart')
