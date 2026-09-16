# Development Workflow

## Copado defaults

- Copado org: `generic_test14`
- Project: `a0oWV000001DDi1YAG` (Naman DX 2026)
- Pipeline: `a0MWV000001M7zx2AC` (Naman DX 2026)
- Base branch: `dxstaging-main`

## Basic delivery cycle

### 1. Create or find the User Story

Use `agentia cicd work list` to avoid duplicates. Create when needed:

```bash
agentia cicd work create \
  --title "<TITLE>" \
  --project "a0oWV000001DDi1YAG" \
  --functional-requirements "<BEHAVIOR_AND_SCOPE>" \
  --technical-specifications "<IMPLEMENTATION_APPROACH>" \
  --acceptance-criteria "<ACTION -> EXPECTED RESULT>" \
  --json
```

Read it back and retain its Salesforce ID and generated Copado name:

```bash
agentia cicd work get "<STORY_ID>" --json
```

Never guess IDs or generated names.

### 2. Create the feature branch

Require a clean working tree, then branch from the latest remote base:

```bash
git status --short
git fetch origin dxstaging-main
git switch -c "feature/<COPADO-STORY-NAME>" origin/dxstaging-main
```

### 3. Start development

```bash
agentia cicd work update "<STORY_ID>" \
  --status "Development In Progress" \
  --json
```

Implement and test the feature. Keep these story fields current:

- `--functional-requirements`: behavior and scope
- `--technical-specifications`: implementation details
- `--acceptance-criteria`: short, verifiable checks
- `--status`: current workflow status

Read the story back after meaningful updates.

### 4. Maintain architecture

Maintain a root `architecture.md`. Update it only for meaningful changes to components, responsibilities, dependencies, boundaries, or runtime flows. Keep it concise and high-level.

### 5. Complete and synchronize

After the developer confirms the work is ready:

```bash
git fetch origin dxstaging-main
git merge origin/dxstaging-main
```

Resolve conflicts, rerun tests, then push:

```bash
git push -u origin HEAD
```

### 6. Create the merge request

Create the GitLab MR using `glab`, targeting `dxstaging-main`, and retain the actual MR URL.

### 7. Complete the User Story update

Preserve the existing specifications and add the MR URL:

```bash
agentia cicd work update "<STORY_ID>" \
  --project "a0oWV000001DDi1YAG" \
  --functional-requirements "<FINAL_BEHAVIOR_AND_SCOPE>" \
  --technical-specifications "<IMPLEMENTATION_DETAILS_AND_MR_URL>" \
  --acceptance-criteria "<ACTION -> EXPECTED RESULT>" \
  --status "Ready for Test" \
  --json

agentia cicd work get "<STORY_ID>" --json
```

The cycle is complete when the branch is pushed, the MR exists, its URL is recorded, and the story is verified as `Ready for Test`.
