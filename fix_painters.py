import os
import re

# 1. Fix app.dart missing import
with open(r"c:\Users\vishnuu\Projects\dhisha\lib\app.dart", "r", encoding="utf-8") as f:
    app_content = f.read()
if "import 'core/theme/theme_provider.dart';" not in app_content:
    app_content = app_content.replace(
        "import 'core/theme/app_theme.dart';",
        "import 'core/theme/app_theme.dart';\nimport 'core/theme/theme_provider.dart';"
    )
    with open(r"c:\Users\vishnuu\Projects\dhisha\lib\app.dart", "w", encoding="utf-8") as f:
        f.write(app_content)

# 2. Fix const in loading_radar.dart and bottom_nav.dart
for file_path in [
    r"c:\Users\vishnuu\Projects\dhisha\lib\shared\widgets\loading_radar.dart",
    r"c:\Users\vishnuu\Projects\dhisha\lib\shared\widgets\bottom_nav.dart"
]:
    with open(file_path, "r", encoding="utf-8") as f:
        content = f.read()
    content = content.replace("const LoadingRadar", "LoadingRadar")
    # In bottom_nav.dart, remove const from bottom nav constructor or fix const arrays
    content = re.sub(r"const\s+Color", "Color", content)
    # Remove const before AppColors.sunAccent(context) if it exists
    content = re.sub(r"const\s+AppColors", "AppColors", content)
    # In loading_radar, remove const constructor requirement
    content = content.replace("const LoadingRadar({", "LoadingRadar({")
    with open(file_path, "w", encoding="utf-8") as f:
        f.write(content)

# 3. Fix CONST_WITH_NON_CONST in sun_screen and wind_screen
for file_path in [
    r"c:\Users\vishnuu\Projects\dhisha\lib\features\sun\screens\sun_screen.dart",
    r"c:\Users\vishnuu\Projects\dhisha\lib\features\wind\screens\wind_screen.dart"
]:
    with open(file_path, "r", encoding="utf-8") as f:
        content = f.read()
    # Remove const from SunPathChart, AltitudeGauge, AzimuthCompass, WindCompass, etc.
    content = content.replace("const SunPathChart", "SunPathChart")
    content = content.replace("const AltitudeGauge", "AltitudeGauge")
    content = content.replace("const AzimuthCompass", "AzimuthCompass")
    content = content.replace("const WindCompass", "WindCompass")
    content = content.replace("const SeasonalRose", "SeasonalRose")
    content = content.replace("const WindSpeedBar", "WindSpeedBar")
    content = content.replace("const SunInfoStrip", "SunInfoStrip")
    content = content.replace("const _SectionHeader", "_SectionHeader")
    with open(file_path, "w", encoding="utf-8") as f:
        f.write(content)

# 4. Inject BuildContext into 5 CustomPainters
painters = {
    r"c:\Users\vishnuu\Projects\dhisha\lib\features\sun\widgets\altitude_gauge.dart": "_AltitudePainter",
    r"c:\Users\vishnuu\Projects\dhisha\lib\features\sun\widgets\azimuth_compass.dart": "_CompassPainter",
    r"c:\Users\vishnuu\Projects\dhisha\lib\features\sun\widgets\sun_path_chart.dart": "_SunPathPainter",
    r"c:\Users\vishnuu\Projects\dhisha\lib\features\wind\widgets\seasonal_rose.dart": "_SeasonalRosePainter",
    r"c:\Users\vishnuu\Projects\dhisha\lib\features\wind\widgets\wind_compass.dart": "_WindCompassPainter"
}

for path, class_name in painters.items():
    with open(path, "r", encoding="utf-8") as f:
        content = f.read()
    
    # Check if we already injected context
    if "final BuildContext context;" in content:
        continue
        
    # Inject final BuildContext context;
    content = re.sub(
        rf"class {class_name} extends CustomPainter {{(?:\s*)",
        f"class {class_name} extends CustomPainter {{\n  final BuildContext context;\n",
        content,
        count=1
    )
    
    # Inject required this.context
    content = re.sub(
        rf"{class_name}\({{",
        f"{class_name}({{\n    required this.context,",
        content,
        count=1
    )

    # Inject context: context in the CustomPaint constructor
    # i.e., _AltitudePainter(...) -> _AltitudePainter(context: context, ...)
    content = re.sub(
        rf"painter: {class_name}\(",
        f"painter: {class_name}(\n            context: context,",
        content
    )
    
    with open(path, "w", encoding="utf-8") as f:
        f.write(content)

print("Fixes applied successfully!")
