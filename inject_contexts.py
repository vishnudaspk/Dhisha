import os

fixes = {
    r"c:\Users\vishnuu\Projects\dhisha\lib\features\sun\widgets\altitude_gauge.dart": {
        "class _RealisticAltitudePainter extends CustomPainter {": "class _RealisticAltitudePainter extends CustomPainter {\n  final BuildContext context;",
        "_RealisticAltitudePainter({required this.altitude});": "_RealisticAltitudePainter({required this.context, required this.altitude});",
        "_RealisticAltitudePainter(\n                      altitude:": "_RealisticAltitudePainter(\n                      context: context,\n                      altitude:"
    },
    r"c:\Users\vishnuu\Projects\dhisha\lib\features\sun\widgets\azimuth_compass.dart": {
        "class _AzimuthCompassPainter extends CustomPainter {": "class _AzimuthCompassPainter extends CustomPainter {\n  final BuildContext context;",
        "_AzimuthCompassPainter({required this.azimuth});": "_AzimuthCompassPainter({required this.context, required this.azimuth});",
        "_AzimuthCompassPainter(azimuth: azimuth)": "_AzimuthCompassPainter(context: context, azimuth: azimuth)"
    },
    r"c:\Users\vishnuu\Projects\dhisha\lib\features\sun\widgets\sun_path_chart.dart": {
        "class _SunPathPainter extends CustomPainter {": "class _SunPathPainter extends CustomPainter {\n  final BuildContext context;",
        "_SunPathPainter({": "_SunPathPainter({\n    required this.context,",
        "_SunPathPainter(\n            arcs: widget.arcs,": "_SunPathPainter(\n            context: context,\n            arcs: widget.arcs,"
    },
    r"c:\Users\vishnuu\Projects\dhisha\lib\features\wind\widgets\seasonal_rose.dart": {
        "class _SeasonalRosePainter extends CustomPainter {": "class _SeasonalRosePainter extends CustomPainter {\n  final BuildContext context;",
        "_SeasonalRosePainter({": "_SeasonalRosePainter({\n    required this.context,",
        "_SeasonalRosePainter(\n              pattern: widget.pattern,": "_SeasonalRosePainter(\n              context: context,\n              pattern: widget.pattern,"
    },
    r"c:\Users\vishnuu\Projects\dhisha\lib\features\wind\widgets\wind_compass.dart": {
        "class _WindCompassPainter extends CustomPainter {": "class _WindCompassPainter extends CustomPainter {\n  final BuildContext context;",
        "_WindCompassPainter({": "_WindCompassPainter({\n    required this.context,",
        "_WindCompassPainter(\n            heading: widget.heading,": "_WindCompassPainter(\n            context: context,\n            heading: widget.heading,"
    }
}

for filepath, replacements in fixes.items():
    if os.path.exists(filepath):
        with open(filepath, "r", encoding="utf-8") as f:
            content = f.read()
        for old_str, new_str in replacements.items():
            if old_str in content:
                content = content.replace(old_str, new_str)
            else:
                print(f"Warning: Could not find '{old_str}' in {filepath}")
        with open(filepath, "w", encoding="utf-8") as f:
            f.write(content)
    else:
        print(f"Missing file {filepath}")

print("Done injecting BuildContext.")
