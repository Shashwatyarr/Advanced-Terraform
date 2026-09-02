#!/bin/bash
set -e

echo "🚀 Building Lambda Layer with Pillow using Docker..."

# Get the directory where the script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_DIR="$( cd "$SCRIPT_DIR/.." && pwd )"
TERRAFORM_DIR="$PROJECT_DIR/terraform"

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed. Please install Docker first."
    echo "📖 Visit: https://docs.docker.com/get-docker/"
    exit 1
fi

# Check if Docker is running
if ! docker info &> /dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker first."
    exit 1
fi

echo "📦 Building layer in Linux container (Python 3.12)..."

# Build the layer using Docker with Python 3.12 on Linux AMD64
docker run --rm \
  --platform linux/amd64 \
  -v "//$(echo "$TERRAFORM_DIR" | sed 's|^C:||' | sed 's|\\|/|g'):/output" \
  python:3.12-slim \
  bash -c "
    echo '📦 Installing Pillow for Linux AMD64...' && \
    pip install --quiet Pillow==10.4.0 -t /tmp/python/lib/python3.12/site-packages/ && \
    cd /tmp && \
    echo '📦 Creating layer zip file...' && \
    apt-get update -qq && apt-get install -y -qq zip > /dev/null 2>&1 && \
    zip -q -r pillow_layer.zip python/ && \
    cp pillow_layer.zip /output/ && \
    echo '✅ Layer built successfully for Linux (Lambda-compatible)!'
  "

echo "📍 Location: $TERRAFORM_DIR/pillow_layer.zip"
echo "✅ Layer is now compatible with AWS Lambda on all platforms!"
