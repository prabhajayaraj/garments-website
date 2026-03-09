#!/bin/bash
set -e
echo "Building static HTML site..."
git clone https://github.com/prabhajayaraj/garments-website-2
git pull origin main
mkdir -p build
cp ./garments-website-2/* build/
echo "Build complete. Output in /build"
