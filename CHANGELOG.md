# 🗒️ Changelog

All notable changes to **CatWalk Enhanced** are listed below. 🐾

## v1.3 - Angry theming & heat tint 🌡️🎨

- Fixed angry cat SVGs to follow Plasma's dynamic color scheme (`fill:currentColor` + `ColorScheme-Text`). 🎨
- Cat now color-shifts from yellow → orange → red as temperature climbs above the angry threshold, with smooth 500ms animated transitions. 🌡️🔥

## v1.2 - Temperature & angry mode 😡🔥

- Added temperature display in `°C`, `°F`, or `K` from any KSysGuard sensor.
- Added angry cat mode with SVG frame switching at a configurable temperature threshold.
- Added 7 display combinations via dropdown for cat, CPU, and temperature mixes.
- Added a temperature size slider alongside the cat and CPU text size sliders.
- Added divider scale and thickness controls.
- Added sensor polling guards so sensors stop polling when their feature is turned off.
- Fixed temperature readings of `0°C` and below so they display correctly.
- Fixed vertical auto-spacing so it fills the available panel height correctly.

## v1.1 - Layout overhaul 📐

- Added dynamic spacing with auto-fill or fixed pixel spacing via slider/manual entry.
- Added stacked layout mode with text below the cat.
- Added swap order support.
- Added a divider line between elements.
- Added independent size sliders for cat and CPU text, with linked scaling support.
- Improved centering so the layout stays pixel-perfect in both orientations.

## v1.0 - Original fork baseline 🐱

- Basic cat + CPU side-by-side layout.
- Fixed spacing between elements.

