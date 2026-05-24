# 😻 CatWalk Enhanced - KDE Plasma 6 CPU Companion 🐾⚡

[![CatWalk Enhanced Demo](https://raw.githubusercontent.com/BLADR-ONE/CatWalk-Enhanced-Plasmoid/refs/heads/main/catWalkEnhanced.gif)](https://github.com/BLADR-ONE/CatWalk-Enhanced-Plasmoid)
[![GitHub Stars](https://img.shields.io/github/stars/BLADR-ONE/CatWalk-Enhanced-Plasmoid?style=social)](https://github.com/BLADR-ONE/CatWalk-Enhanced-Plasmoid/stargazers)

**A playful, configurable CPU and temperature monitor for KDE Plasma 6+** 🐈‍⬛

CatWalk Enhanced is a feature-packed fork of the classic [CatWalk CPU monitor](https://www.pling.com/p/2137844). It keeps the cute cat animation, then adds flexible layouts, temperature monitoring, angry frames, and a bunch of sizing and spacing controls for a tighter Plasma 6 fit. ✨

---

## ✨ Features

| Feature | What it does 🐱 |
| :--- | :--- |
| **CPU-paced walking** | The cat animation speed is tied to CPU usage using `Math.ceil(5000 / Math.sqrt(cpu + 35) - 400)`, so higher load makes the paws move faster and lighter load slows the walk down. ⚡ |
| **7 display combinations** | Pick any mix of cat, CPU, and temperature: cat only, CPU only, temperature only, cat + CPU, cat + temperature, CPU + temperature, or all three. |
| **Temperature display** | Show any KSysGuard temperature sensor in `°C`, `°F`, or `K`. 🔥 |
| **Angry mode** | When the temperature reaches the configured threshold, the cat switches to angry SVG frames and shifts from yellow → orange → red as it gets hotter. Set the threshold to `0` for always-angry mode. 😡🌡️ |
| **Flexible layout** | Use side-by-side or stacked layout, place the text below the cat, swap the order, and show or hide the divider. 📐 |
| **Divider controls** | Render a divider as a simple rectangle line with configurable size from `25%` to `200%` and thickness from `1px` to `10px`. |
| **Spacing modes** | Use automatic spacing to fill available space, or pick a fixed gap with a slider from `0` to `500px` or manual entry. |
| **Independent sizing** | Adjust cat, CPU %, temperature, and divider sizes independently. Link the size sliders if you want them to scale together. ✨ |
| **Performance-minded polling** | Sensors only poll when their feature is active, which keeps unused readings out of the way. |
| **Color coding** | CPU text stays neutral at `60%+` and turns red at `85%+`. Temperature stays neutral at `70°C+` and turns red at `85°C+`. |
| **Live sensor preview** | The settings page shows a live sensor reading so you can verify the sensor ID before you commit it. 🧪 |

### 🐾 Animation Note

The cat walks at a speed derived from CPU usage:

```js
Math.ceil(5000 / Math.sqrt(cpu + 35) - 400)
```

That means the cat is calmer at low load and scamper-fast when the CPU gets busy. ⚡

---

## 🚀 Installation

CatWalk Enhanced requires **KDE Plasma 6+**.

Install the packaged plasmoid:

```bash
kpackagetool6 --type Plasma/Applet --install org.kde.plasma.catwalkEnhanced.zip
```

Upgrade an existing install:

```bash
kpackagetool6 --type Plasma/Applet --upgrade org.kde.plasma.catwalkEnhanced.zip
```

If the widget does not appear right away, restart Plasma Shell:

```bash
kquitapp6 plasmashell && kstart6 plasmashell
```

Uninstall:

```bash
kpackagetool6 --type Plasma/Applet --remove org.kde.plasma.catwalkEnhanced
```

After installing, right-click your desktop or panel, choose **Add Widgets**, and search for **CatWalk Enhanced**. 🐱

---

## ⚙️ Configuration

### 🧩 Display

- **Displayed items**: choose one of the 7 cat / CPU / temperature combinations.
- **Temperature unit**: choose Celsius (`°C`), Fahrenheit (`°F`), or Kelvin (`K`).
- **Text below cat**: stack the text under the cat instead of keeping everything side-by-side.
- **Swap order**: reverse the visible order of the cat and text.
- **Show divider**: add a divider between visible elements.

### 📏 Spacing

- **Auto spacing**: the widget fills the available room automatically.
- **Fixed spacing**: set a gap with the slider, or type a manual pixel value.

### 🔢 Sizing

- **Link sizes**: keep cat, CPU text, temperature text, and divider size tied together.
- **Cat size**: scale the cat frames.
- **CPU % size**: scale the CPU text.
- **Temperature size**: scale the temperature text.
- **Divider size**: scale the divider length from `25%` to `200%`.
- **Divider thickness**: adjust the divider line from `1px` to `10px`.

### 🌡️ Temperature Sensor

To use temperature display or angry mode, paste a valid KSysGuard sensor ID into the temperature sensor field:

1. Open **KDE System Monitor**.
2. Go to the **Sensors** tab.
3. Right-click the temperature sensor you want.
4. Select **Copy sensor name**.
5. Paste it into CatWalk Enhanced's **Temperature sensor** field.

The settings page includes a live sensor preview so you can confirm the sensor is correct before saving. 🧪

### 😡 Angry Mode

- **Enable angry mode**: turns angry cat frames on or off.
- **Temperature threshold**: the cat becomes angry when the sensor value is greater than or equal to this threshold.
- **Threshold `0`**: always uses angry frames.

Angry mode swaps to angry SVG frames and color-shifts the cat from yellow → orange → red as the temperature climbs, with smooth animated transitions. 🌡️✨

### 🎨 Color Cues

- CPU text uses a neutral highlight at `60%+` and turns red at `85%+`.
- Temperature text uses a neutral highlight at `70°C+` and turns red at `85°C+`.

---

## 👥 Credits

✨ **Enhanced by:** [BLADR-ONE](https://github.com/BLADR-ONE)

🐱 **Original concept:** Yuri Saurov - CatWalk v2.4

📄 **License:** GPL-3.0+

---

## 🐛 Issues

Found a bug or have feedback? [File an issue](https://github.com/BLADR-ONE/CatWalk-Enhanced-Plasmoid/issues). 🛠️

---

## 📦 Plasma 6 Compatibility

| Field | Value |
| :--- | :--- |
| **Id** | `org.kde.plasma.catwalkEnhanced` |
| **Version** | `1.2` |
| **API** | `Plasma 6+` |
| **Provides** | `Plasma/Applet` |

⭐ Star it if you meow it
