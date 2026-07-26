
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
├── component-a/        
│   ├── Dockerfile               # Build instructions for A
│   └── ...                      
└── component-b/        
    ├── Dockerfile               # Build instructions for B
    └── ...
```


## 🚀 Commit and Tagging Workflow

To trigger a build and publish process for a specific component, this repository uses a **tag-based deployment strategy**. Each workflow is configured to listen for Git tags that specifically match its corresponding component's folder name.

### Tag Format

To trigger a build, your Git tag must follow this exact convention:

> `<folder-name>-v<version>`

**Example:** If you want to release version `2.5` of the code inside `component-a`, the tag must be `component-a-v2.5`.

### Step-by-Step Deployment Process

1. **Commit Changes:** Make and commit your changes within the target component's directory.
```bash
git add component-a/
git commit -m "feat: update component A features"

```


2. **Create a Tag:** Tag the commit with the component name and the new version number.
```bash
git tag component-a-v2.5

```


3. **Push the Tag:** Push the tag to GitHub to trigger the workflow.
```bash
git push origin component-a-v2.5

```



### How the CI/CD Pipeline Reacts

When you push the tag, the following automated sequence occurs:

1. **Selective Triggering:** Only the workflow file listening for tags matching `component-a-v*` (i.e., `.github/workflows/component-a.yml`) will run. All other component workflows remain dormant.
2. **Version Extraction:** The workflow automatically extracts the version number (e.g., `2.5`) from the Git tag.
3. **Build & Push:** The action builds the multi-architecture image using `component-a/Dockerfile` and pushes it to GHCR.
4. **Final Artifact:** The newly built image becomes instantly available in the registry, tagged perfectly with your version:
`ghcr.io/<your-github-username>/component-a:2.5`
