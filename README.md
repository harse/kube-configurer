# Kubernetes Config Manager

A script to manage multiple isolated kubeconfig files by automatically merging them into your shell environment and normalizing their internal identifiers.

## Critical Requirement

**Single Context Limitation:** This tool is designed to work with kubeconfig files that contain **exactly one context**. If a file contains multiple contexts, the script will skip it to prevent data corruption or ambiguity.

## Overview

If you work with multiple Kubernetes clusters, managing separate kubeconfig files can become tedious. This tool scans a specified directory (and its subdirectories) for kubeconfig files, renames the internal `cluster`, `user`, and `context` names to match the parent folder and filename, and securely merges them into your `KUBECONFIG` environment variable.

### Key Features
* **Auto-discovery:** Recursively finds config files in `~/.kube/configs/`.
* **Smart Renaming:** Normalizes contexts to `<folder-name>-<file-name>` to avoid context name collisions.
* **Dynamic Merging:** Automatically constructs and exports the `KUBECONFIG` path list.

## Prerequisites

* `bash` or `zsh`
* **yq** (Go implementation by Mike Farah)
    ```bash
    # Install on macOS via Homebrew
    brew install yq
    ```

## Setup

1.  Place the `kube-configer.sh` script in a safe location, for example, `~/.kube/kube-configer.sh`.
2.  Make the script executable:
    ```bash
    chmod +x ~/.kube/kube-configer.sh
    ```
3.  Add the following alias to your `~/.zshrc` or `~/.bashrc` file.
    > **Note:** You must use `source` so the script can export the environment variable directly to your current shell session.
    ```bash
    alias refresh-kubeconfig="source ~/.kube/kube-configer.sh"
    ```
4.  Reload your shell configuration:
    ```bash
    source ~/.zshrc
    ```
5.  Run the alias anytime you add a new configuration file to your `~/.kube/configs` directory:
    ```bash
    refresh-kubeconfig
    ```

## Template Structure

The script expects your configuration files to be organized in the following hierarchy:

```text
~/.kube/configs/
├── <environment>/           # Optional: Grouping folder (e.g., prod, staging, dev)
│   ├── <cluster-name>.yaml  # Individual kubeconfig file
│   └── <cluster-name>.yml
└── <stand-alone-config>.yaml%