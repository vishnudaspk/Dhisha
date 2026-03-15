import subprocess
import json
import re

try:
    result = subprocess.run("dart analyze", shell=True, capture_output=True, text=True)
    out = result.stdout + result.stderr
    lines = [line.strip() for line in out.splitlines() if " • " in line]
    
    with open("dart_errors.txt", "w", encoding="utf-8") as f:
        for line in lines:
            f.write(line + "\n")
            
    print("Parsed dart analyzing output!")
except Exception as e:
    print("Error:", e)
