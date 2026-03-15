import os

try:
    with open("machine_analyze.txt", "rb") as f:
        content = f.read()
    
    try:
        text = content.decode('utf-16le')
    except:
        text = content.decode('utf-8')
        
    lines = text.strip().split('\n')
    errors = {}
    
    for line in lines:
        if line.strip():
            parts = line.split('|')
            if len(parts) >= 8:
                err_type = parts[2]
                msg = parts[7]
                file_path = parts[3]
                key = f"{err_type}: {msg}"
                if key not in errors:
                    errors[key] = []
                if file_path not in errors[key]:
                    errors[key].append(file_path)
                    
    with open("parsed_errors.txt", "w", encoding="utf-8") as out:
        for key, files in errors.items():
            out.write(f"[{key}] occurs in {len(files)} files. Examples:\n")
            for f in files[:5]:
                out.write(f"  - {f}\n")
            
except Exception as e:
    with open("parsed_errors.txt", "w", encoding="utf-8") as out:
        out.write(f"Error reading parse: {e}")
