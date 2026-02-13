# 🎉 Catwalk Enhanced - Enhanced CPU Cat Monitor for KDE Plasma

[![Catwalk Enhanced Demo](https://raw.githubusercontent.com/BLADR-ONE/CatWalk-Enhanced-Plasmoid/refs/heads/main/catWalkEnhanced.gif)](https://github.com/BLADR-ONE/CatWalk-Enhanced-Plasmoid)

**Enhanced fork of the adorable [CatWalk CPU monitor](https://www.pling.com/p/2137844)** 🐱💻

## ✨ New Features
| Feature | Before | Now |
|---------|--------|-----|
| **Spacing** | Fixed | **Dynamic** - grows/shrinks with widget size 🧩 |
| **Layout** | Side-by-side only | **Side-by-side OR stacked** (text below cat) 📐 |
| **Position** | Cat left only | **Swap positions** - left/right OR top/bottom 🔄 |
| **Sizing** | Cat bigger than text | **Perfectly balanced** - sliders control both 🎯 |
| **Centering** | Sometimes off | **Pixel-perfect centering** everywhere 🎨 |

## 🚀 Installation

### 🖥️ Plasma 6 (Recommended)
```bash
# Download release ZIP & install
plasmapkg2 -i org.kde.plasma.catwalkenhanced.zip

# Or from extracted folder
plasmapkg2 -i org.kde.plasma.catwalkenhanced/
```

### 🔄 Restart Plasma (if needed)
```bash
kquitapp6 plasmashell && kstart6 plasmashell
```

### 🗑️ Uninstall
```bash
plasmapkg2 -r org.kde.plasma.catwalkenhanced
```

## ⚙️ Configuration
```
📱 Panel: Auto-sized perfectly
🖥️ Desktop: Resizable with dynamic spacing
🔧 Settings:
  • Cat Size (25-200%)        [slider]
  • Text Size (25-200%)       [slider]
  • Link sizes               [checkbox]
  • "Text below cat"         [checkbox]
  • "Swap order"             [checkbox]
  • Idle threshold           [slider]
  • Update rate              [spinbox]
```

## 👥 Credits
```
✨ Enhanced: BLADR-ONE (https://github.com/BLADR-ONE)
🐱 Original: Yuri Saurov (dr@i-glu4it.ru) - CatWalk v2.4
📄 License: GPL-3.0+
```

## 🐛 Issues
[File issue](https://github.com/BLADR-ONE/CatWalk-Enhanced-Plasmoid/issues)

## 📦 Plasma 6 Compatible ✓
```
Id: org.kde.plasma.catwalkenhanced
Version: 1.0
API: Plasma 6+
Provides: org.kde.plasma.systemmonitor
```

---

⭐ **Star if you meow it!** 🐱✨
