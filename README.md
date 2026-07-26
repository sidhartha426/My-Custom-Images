# Monorepo CI/CD Architecture

This repository operates as a monorepo for independent components and services. It utilizes dedicated GitHub Actions workflows for each component to build, version, and publish multi-architecture Docker images to the GitHub Container Registry (GHCR). 

This structure allows each component to maintain custom build logic, such as specific image tagging conventions or custom suffixes.

## 🏗️ Core Structure

Every deployable component lives in its own root-level directory containing a `Dockerfile`. Each component is paired with a specific workflow file in the `.github/workflows/` directory.

```text
.
├── .github/
│   └── workflows/
│       ├── component-a.yml      # Dedicated workflow for Component A
│       └── component-b.yml      # Dedicated workflow for Component B
├── <component-folder-a>/        
│   ├── Dockerfile               # Build instructions for A
│   └── ...                      
└── <component-folder-b>/        
    ├── Dockerfile               # Build instructions for B
    └── ...
