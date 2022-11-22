#!/bin/bash
set -exu -o pipefail
mkdir -p build

# Create 
./tools/chr_tool.py res/background.png --output build/background.chr
./tools/chr_tool.py res/sprite.png --output build/sprite.chr

ca65 demo.s -g -o build/demo.o
ld65 -o build/demo.nes -C demo.cfg build/demo.o -m build/demo.map.txt -Ln build/demo.labels.txt --dbgfile build/demo.nes.dbg
python3 tools/demo_fceux_symbols.py
( cd build && wine ~/workspace_local/fceux/fceux.exe demo.nes)
