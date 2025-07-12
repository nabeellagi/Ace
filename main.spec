# -*- mode: python ; coding: utf-8 -*-
from PyInstaller.utils.hooks import collect_submodules, get_package_paths
import os
import site

main_script = 'main.py'
pathex = ['.']

# Collect submodules from your custom folders
hidden_imports = (
    collect_submodules('sections')
    + collect_submodules('helper')
    + collect_submodules('colour')
    + collect_submodules('lightkurve')
    + collect_submodules('streamlit.runtime.scriptrunner')  # <-- Add this
    + ['streamlit.runtime.scriptrunner.magic_funcs']         # <-- Explicit fallback
)

# Include local folders like love/, visual/, images/
datas = []
for folder in ['sections', 'helper', 'love', 'visual', 'images']:
    if os.path.isdir(folder):
        for root, _, files in os.walk(folder):
            for file in files:
                full_path = os.path.join(root, file)
                rel_path = os.path.relpath(root, '.')
                datas.append((full_path, rel_path))
# After your folder walk for datas
if os.path.isfile("app.py"):
    datas.append(("app.py", "."))

# 📦 Include streamlit .dist-info to avoid importlib.metadata errors
site_packages = site.getsitepackages()[0]
for name in os.listdir(site_packages):
    if name.startswith("streamlit-") and name.endswith(".dist-info"):
        metadata_path = os.path.join(site_packages, name)
        datas.append((metadata_path, name))
        break

# ✅ Include Streamlit's static assets (HTML/CSS/JS)
import streamlit
streamlit_path = os.path.dirname(streamlit.__file__)
static_dir = os.path.join(streamlit_path, "static")

if os.path.isdir(static_dir):
    for root, _, files in os.walk(static_dir):
        for file in files:
            full_path = os.path.join(root, file)
            relative_path = os.path.relpath(full_path, streamlit_path)
            destination = os.path.join("streamlit", os.path.dirname(relative_path))
            datas.append((full_path, destination))

a = Analysis(
    [main_script],
    pathex=pathex,
    binaries=[],
    datas=datas,
    hiddenimports=hidden_imports,
    hookspath=[],  # <- Point to the folder containing your hook
    runtime_hooks=[],  # <- Run this before anything else
    excludes=[],
    win_no_prefer_redirects=False,
    win_private_assemblies=False,
    cipher=None,
    noarchive=False,
)


pyz = PYZ(a.pure, a.zipped_data, cipher=None)

exe = EXE(
    pyz,
    a.scripts,
    a.binaries,
    a.zipfiles,
    a.datas,
    [],
    name='AceStreamlitApp',
    debug=False,
    bootloader_ignore_signals=False,
    strip=False,
    upx=True,
    console=True  # True = show terminal; False = GUI-only
)

coll = COLLECT(
    exe,
    a.binaries,
    a.zipfiles,
    a.datas,
    strip=False,
    upx=True,
    name='AceStreamlitApp'
)
