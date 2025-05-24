# 🎥 CamForge

**CamForge** is an experimental, cross-platform, open-source camera input processor for enabling custom filters and homebrew shaders, for your media needs.

It lets you brew your own real-time filters, shaders, and visual hacks using OpenGL + GLSL — before the feed hits OBS, Zoom, Google Meet, or wherever.

Think: camera-as-canvas.

---

## 🧠 Why

Because your webcam shouldn't be boring.

This project is for streamers, artists, VJs, devs, or anyone who wants to intercept a webcam feed, manipulate it with code (or shaders), and stream it onward.

---

## 🏗️ What It Does (Eventually)

- [ ] Capture webcam input
- [ ] Render it in an OpenGL Context
- [ ] Applly custom GLSL shaders
- [ ] Live-reload shader files
- [ ] Output to virtual webcam (ability to pipe output to OBS, Zoom, Google Meet, etc.)
- [ ] GUI frontend for shader/filter management
- [ ] Cross-platform builds (currently Windows first, next Linux-MacOS)
---

## 💾 Dependencies

Everything vendored into `/third_party`. No need to install system libs.

- [OpenCV](https://opencv.org/)
- [GLFW](https://www.glfw.org/)
- [GLEW](http://glew.sourceforge.net/)
- [glslang](https://github.com/KhronosGroup/glslang) _(for shader validation, soon)_

Setup script:

**Linux**:
```bash
./scripts/setup_deps.sh
```

**Windows**:
```powershell
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process
.\scripts\setup_deps.ps1
```

---

## ⚖️ License

This project is [GNU GPLv3](https://www.gnu.org/licenses/gpl-3.0.txt)  licensed.

Fork it, break it, glitch it — just share back ✨

---