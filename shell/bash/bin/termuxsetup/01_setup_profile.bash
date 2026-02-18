#!/bin/bash

cd ~/.termux
curl -fLo font.tar.xz https://github.com/ryanoasis/nerd-fonts/releases/download/v3.1.1/JetBrainsMono.tar.xz
mkdir fonts
tar -xvJf font.tar.xz -C ./fonts
rm font.tar.xz
cp "fonts/JetBrainsMonoNerdFontMono-Regular.ttf" font.ttf
rm -rf fonts
