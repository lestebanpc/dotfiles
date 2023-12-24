#!/bin/bash

cd .termux
curl -fLo font.zip https://github.com/ryanoasis/nerd-fonts/releases/download/v3.1.1/JetBrainsMono.zip
mkdir fonts 
mv font.zip fonts 
cd fonts 
unzip font.zip 
mv "JetBrainsMonoNerdFont-Regular.ttf" .. 
cd .. 
mv "JetBrainsMonoNerdFont-Regular.ttf" font.ttf 
rm -rf fonts


