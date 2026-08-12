import sys

def check(file_path):
    with open(file_path, 'r') as f:
        content = f.read()

    lines = content.split('\n')
    
    stack = []
    
    # Check lines 641 to 1485
    for i in range(640, 1485):
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
                        print(f"Mismatched bracket: expected match for '{top_char}' from ({top_line}, {top_col}), but found '{char}' at ({i+1}, {j+1})")
                        # don't return, keep checking
                        stack.pop() # just pop the mismatched one
                else:
                    print(f"Extra '{char}' found at line {i+1}, col {j+1}")

    print("Remaining open brackets at line 1485:")
    for b in stack:
        print(b)

check('lib/app/home/view/home_page.dart')
