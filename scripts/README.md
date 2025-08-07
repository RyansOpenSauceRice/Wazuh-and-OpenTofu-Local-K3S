# Utility Scripts

This directory contains utility scripts for the Wazuh and OpenTofu with Kustomize project.

## Available Scripts

### `fix-permissions.sh`

This script fixes common permission issues that may occur when working with OpenTofu and Kubernetes.

```bash
./fix-permissions.sh
```

#### Features

- Fixes permissions on the OpenTofu directory
- Fixes permissions on the kubeconfig file
- Fixes permissions on the Wazuh Kubernetes repository
- Removes lock files that might prevent OpenTofu from running

#### Usage

```bash
# Make sure the script is executable
chmod +x scripts/fix-permissions.sh

# Run the script
./scripts/fix-permissions.sh
```

#### When to use

- When you encounter "permission denied" errors with OpenTofu
- When you see "Error acquiring the state lock" messages
- When kubectl commands fail with permission issues
- When switching between running commands with and without sudo

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

## Utils Directory

The `utils` directory contains additional utility scripts that are used by the main scripts.

### `path_resolver.sh`

This script handles path resolution and validation.

```bash
./utils/path_resolver.sh
```

#### Features

- Creates a configuration file if it doesn't exist
- Validates paths to important directories
- Resolves the kubeconfig path
- Provides functions for path validation

#### Usage

```bash
# Run directly
./utils/path_resolver.sh

# Or source in another script
source ./utils/path_resolver.sh
```

#### When to use

- When you need to validate paths before running commands
- When you need to find the correct kubeconfig path

### `k8s_validator.sh`

This script validates Kubernetes configuration and resources.

```bash
./utils/k8s_validator.sh
```

#### Features

- Checks if kubectl is installed
- Checks if the Kubernetes cluster is accessible
- Checks if the necessary resources are available

#### Usage

```bash
# Run directly
./utils/k8s_validator.sh

# Or source in another script
source ./utils/k8s_validator.sh
```

#### When to use

- Before deploying Wazuh to ensure Kubernetes is properly configured
- When troubleshooting Kubernetes-related issues

### `error_handler.sh`

This script handles errors and provides recovery procedures.

```bash
# This script is meant to be sourced by other scripts
source ./utils/error_handler.sh
```

#### Features

- Provides functions for error handling
- Logs errors to a deployment log
- Attempts to recover from common errors
- Displays troubleshooting information

#### Usage

```bash
# Source in another script
source ./utils/error_handler.sh

# Then use the functions
handle_error 1 "Failed to access Kubernetes" recover_kubernetes_access
display_troubleshooting 1 "kubernetes"
```

#### When to use

- When developing new scripts that need error handling
- When troubleshooting deployment issues

## Adding New Scripts

When adding new utility scripts to this directory:

1. Make sure they are executable (`chmod +x scripts/your-script.sh`)
2. Add documentation in this README
3. Follow shell scripting best practices
4. Include proper error handling and user feedback
5. Consider using the utility scripts in the utils directory
