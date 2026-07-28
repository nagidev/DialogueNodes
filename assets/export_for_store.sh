#!/bin/bash

echo "Making export folder..."
rm -rf export
mkdir -p export
echo "Copying files to export folder..."
cp -r addons export/
cp LICENSE export/addons/dialogue_nodes
cp README.md export/addons/dialogue_nodes
echo "Compressing files into zip..."
cd export && zip -r export.zip addons
rm -rf addons
echo "Done."

