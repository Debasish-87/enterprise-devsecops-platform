#!/bin/bash
# ============================================================
# Clones the RAG application source repository
# ============================================================
set -euo pipefail

echo "=================================="
echo "Cloning RAG Repository"
echo "=================================="

rm -rf app-source

git clone \
  https://github.com/Debasish-87/rag-based-document-qa.git \
  app-source

echo "=================================="
echo "Repository cloned successfully"
echo "=================================="

ls -la app-source
