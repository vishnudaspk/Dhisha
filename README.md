# Dhisha 📐 ☀️ 💨

**Dhisha** is a specialized, beautifully designed mobile application crafted meticulously for **architects, urban planners, and site engineers**. The app provides hyper-accurate, real-time meteorological and astronomical data—specifically Sun positioning and Wind patterns—crucial for climate-responsive architectural design, site analysis, and construction planning.

Designed with a strict Dieter Rams-inspired minimalism and the aesthetic of high-end scientific instruments, Dhisha avoids unnecessary clutter, presenting complex geocentric data in a clean, legible, and highly visual format.

---

## 🏗 Why Dhisha is Essential for Architects & Engineers

In modern passive solar design and structural engineering, understanding the localized environment is non-negotiable. Dhisha empowers design professionals directly on the construction site:

*   **Passive Solar Design & Shading:** The interactive Sun Path and Live Azimuth compass allow architects to instantly visualize solar exposure across different times of the day. This is vital for placing windows, designing shading devices (brise-soleil), and maximizing natural daylighting while minimizing thermal heat gain.
*   **Wind & Natural Ventilation:** The real-time atmospheric wind particle visualizer helps engineers understand macro and micro wind vectors. This data is critical for orienting building masses to capture cross-ventilation breezes, or for designing windbreaks and structural reinforcements against prevailing storm winds.
*   **On-Site Orientation:** When standing on an empty lot, determining exact True North vs. Magnetic North can be prone to error. Dhisha fuses gyro, accelerometer, and GPS data into a perfectly calibrated 1.0° resolution True North compass, ensuring site plans are oriented flawlessly before ground is broken.

## ⚙️ Mechanics & Under the Hood

Dhisha combines advanced local mathematical algorithms with real-time hardware fusion to deliver "scientific instrument" grade accuracy without internet dependency for its core solar calculations.

### The Solar Engine (NOAA Core)
The app runs a localized port of the **NOAA Solar Calculation Algorithm** (derived from Jean Meeus' "Astronomical Algorithms"). By utilizing your device's raw GPS latitude, longitude, and current UTC time, Dhisha mathematically calculates:
*   **Julian Century & Equation of Time:** Adjusting for the Earth's elliptical orbit.
*   **Solar Declination & Hour Angle:** To compute the precise angle of the sun relative to the equator.
*   **Atmospheric Refraction Correction:** Utilizing the Meeus/Bennett formula to account for light bending through the Earth's atmosphere, yielding an altitude/azimuth accuracy of < `0.01°`.

This means the Sun Path chart and Azimuth dial are completely rendered offline using pure localized astronomical math.

### Sensor Fusion Compass
To display the live alignment, Dhisha bypasses standard jittery mobile compass APIs. It runs a custom **Sensor Fusion Engine** that:
*   Extracts raw True North heading directly from `flutter_compass`.
*   Applies a low-pass quantization filter (rounding to the nearest `1.0°`) to prevent UI jitter.
*   Drives a physics-based spring simulation (`SpringDescription`) to smoothly rotate the on-screen UI components so they remain physically geo-locked to the real-world environment as you rotate your device.

### Fluid Mechanics Visualizer (Wind)
The Wind UI isn't a pre-rendered video—it is a live **Particle Physics System**. 
*   Up to 2,800 individual particle strokes are initialized across a massive `2000x2000` grid.
*   On every frame (60fps), particles compute their vectors based on current wind speed (m/s) and meteorological direction.
*   To prevent the strokes from clustering into artificial patterns (a common PRNG anomaly), Dhisha wraps the boundary logic using a strict mathematical modulo wrap-around (`x = -1000` teleportation), permanently locking the particles' relative distribution and creating a perfectly continuous, random atmospheric flow.

---

## 🛠 Tech Stack

*   **Framework:** Flutter (Dart)
*   **Architecture:** Riverpod (State Management)
*   **Sensors:** `geolocator`, `flutter_compass`, `sensors_plus`
*   **Design Language:** Custom minimalist design system using `CustomPaint` and `Canvas` APIs.

## 🚀 Getting Started

Since Dhisha relies heavily on native device sensors (GPS, Magnetometer) for its calculations, it must be run on a physical device. iOS requires Xcode builds, while Android can be built directly via standard Flutter commands.

```bash
flutter pub get
flutter run --release
```
