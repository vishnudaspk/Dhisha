import os
import re

target_dir = r"c:\Users\vishnuu\Projects\dhisha\lib"

# The properties that need (context) appended
dynamic_props = [
    "sunAccent", "windAccent", "background", "surface",
    "border", "textPrimary", "textSecondary", "error"
]

def process_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    original_content = content

    # 1. Replace AppColors.prop with AppColors.prop(context)
    for prop in dynamic_props:
        # Regex to match AppColors.prop but NOT AppColors.prop(context)
        pattern = r"AppColors\." + prop + r"(?!\()"
        content = re.sub(pattern, f"AppColors.{prop}(context)", content)

    # 2. Fix const issues: 'const AppColors.prop(context)' -> 'AppColors.prop(context)'
    content = re.sub(r"const\s+(AppColors\.\w+\(context\))", r"\1", content)
    
    # 3. Fix cases where const wrapper encompasses the color
    # e.g. const Center(child: LoadingRadar(color: AppColors.sunAccent(context))) -> Center(child: LoadingRadar(color: AppColors.sunAccent(context)))
    # For a general fix, we will let Dart analyzer guide us if there are complex const issues, 
    # but we can do some easy ones like "const LoadingRadar" -> "LoadingRadar"
    content = content.replace("const LoadingRadar", "LoadingRadar")
    content = content.replace("const Center(child: LoadingRadar", "Center(child: LoadingRadar")
    content = content.replace("const Center(\n            child: LoadingRadar", "Center(\n            child: LoadingRadar")

    if original_content != content:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"Updated {filepath}")

for root, _, files in os.walk(target_dir):
    for file in files:
        if file.endswith(".dart"):
            process_file(os.path.join(root, file))

print("Done migrating AppColors.")
