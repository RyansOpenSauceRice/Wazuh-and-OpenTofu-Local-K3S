# Utility Scripts

This directory contains utility scripts for the Wazuh and OpenTofu with Kustomize project.

## Available Scripts

### `fix-lint-errors.sh`

This script automatically fixes common linting errors in the repository.

#### Features

- Fixes Markdown linting issues
- Formats and validates OpenTofu (Terraform) files
- Fixes shell script linting issues
- Installs required tools if they're missing

#### Usage

```bash
# Make sure the script is executable
chmod +x scripts/fix-lint-errors.sh

# Run the script
./scripts/fix-lint-errors.sh
```

#### What it fixes

- **Markdown**:
  - Trailing whitespace
  - Multiple consecutive blank lines
  - Missing newline at end of file
  - Line length issues (when using markdownlint)

- **OpenTofu/Terraform**:
  - Formatting issues (using `tofu fmt`)
  - Validation errors (using `tofu validate`)

- **Shell Scripts**:
  - Missing or incorrect shebang
  - Trailing whitespace
  - Missing newline at end of file
  - Common shellcheck issues

#### Requirements

The script will attempt to install these tools if they're missing:

- `tofu` (OpenTofu CLI)
- `markdownlint` (for Markdown linting)
- `shellcheck` (for shell script linting)

## Adding New Scripts

When adding new utility scripts to this directory:

1. Make sure they are executable (`chmod +x scripts/your-script.sh`)
2. Add documentation in this README
3. Follow shell scripting best practices
4. Include proper error handling and user feedback
