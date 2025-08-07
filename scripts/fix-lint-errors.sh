#!/bin/bash
# Script to fix common linting errors in the repository
# Usage: ./scripts/fix-lint-errors.sh

set -e

echo "🔍 Starting linting fixes..."

# Check if required tools are installed
check_command() {
  if ! command -v "$1" &> /dev/null; then
    echo "❌ $1 is not installed. Installing..."
    if [[ "$1" == "tofu" ]]; then
      curl --proto '=https' --tlsv1.2 -fsSL https://get.opentofu.org/install-opentofu.sh -o install-opentofu.sh
      chmod +x install-opentofu.sh
      ./install-opentofu.sh --install-method standalone
      rm install-opentofu.sh
    elif [[ "$1" == "markdownlint" ]]; then
      npm install -g markdownlint-cli
    elif [[ "$1" == "shellcheck" ]]; then
      if [[ "$(uname)" == "Darwin" ]]; then
        brew install shellcheck
      else
        apt-get update && apt-get install -y shellcheck
      fi
    fi
  fi
}

# Fix Markdown linting issues
fix_markdown_lint() {
  echo "📝 Fixing Markdown linting issues..."
  
  # Create a markdownlint config file if it doesn't exist
  if [ ! -f ".markdownlint.json" ]; then
    cat > .markdownlint.json << 'EOF'
{
  "default": true,
  "MD013": { "line_length": 120 },
  "MD033": false,
  "MD041": false
}
EOF
    echo "✅ Created .markdownlint.json configuration"
  fi
  
  # Find all markdown files and fix common issues
  find . -name "*.md" -type f -not -path "./node_modules/*" -not -path "./.git/*" | while read -r file; do
    echo "   Processing $file"
    
    # Fix trailing whitespace
    sed -i.bak 's/[ \t]*$//' "$file"
    
    # Fix multiple consecutive blank lines
    sed -i.bak '/^$/N;/^\n$/D' "$file"
    
    # Fix missing newline at end of file
    [[ "$(tail -c1 "$file")" != "" ]] && echo "" >> "$file"
    
    # Run markdownlint auto-fix if available
    if command -v markdownlint &> /dev/null; then
      markdownlint --fix "$file" || true
    fi
    
    # Remove backup files
    rm -f "$file.bak"
  done
}

# Fix OpenTofu linting issues
fix_opentofu_lint() {
  echo "🔧 Fixing OpenTofu linting issues..."
  
  # Create a .tflint.hcl file if it doesn't exist
  if [ ! -f ".tflint.hcl" ]; then
    cat > .tflint.hcl << 'EOF'
plugin "terraform" {
  enabled = true
  preset  = "recommended"
}
EOF
    echo "✅ Created .tflint.hcl configuration"
  fi
  
  # Format all Terraform files
  find . -name "*.tf" -type f -not -path "./.terraform/*" | while read -r file; do
    echo "   Formatting $file"
    tofu fmt "$file"
  done
  
  # Initialize OpenTofu in each directory containing .tf files
  find . -name "*.tf" -type f -not -path "./.terraform/*" | xargs -I{} dirname {} | sort -u | while read -r dir; do
    echo "   Validating in $dir"
    (cd "$dir" && tofu init -backend=false -input=false && tofu validate) || true
  done
}

# Fix shell script linting issues
fix_shell_lint() {
  echo "🐚 Fixing shell script linting issues..."
  
  # Find all shell scripts and fix common issues
  find . -name "*.sh" -type f -not -path "./node_modules/*" -not -path "./.git/*" | while read -r file; do
    echo "   Processing $file"
    
    # Make scripts executable
    chmod +x "$file"
    
    # Fix shebang if missing
    if ! grep -q "^#!/bin/bash" "$file" && ! grep -q "^#!/usr/bin/env bash" "$file"; then
      sed -i.bak '1s/^/#!/bin/bash\n/' "$file"
    fi
    
    # Fix trailing whitespace
    sed -i.bak 's/[ \t]*$//' "$file"
    
    # Fix missing newline at end of file
    [[ "$(tail -c1 "$file")" != "" ]] && echo "" >> "$file"
    
    # Run shellcheck and attempt to fix issues
    if command -v shellcheck &> /dev/null; then
      shellcheck -f diff "$file" | patch -p1 "$file" || true
    fi
    
    # Remove backup files
    rm -f "$file.bak"
  done
}

# Main execution
echo "🔄 Checking required tools..."
check_command "tofu"
check_command "markdownlint"
check_command "shellcheck"

# Run fixes
fix_markdown_lint
fix_opentofu_lint
fix_shell_lint

echo "✨ Linting fixes completed! Please review the changes before committing."