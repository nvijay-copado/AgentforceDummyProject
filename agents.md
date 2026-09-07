# AGENTS.md — Agentia CLI (`agentia`)

Headless CICD CLI for Salesforce ALM / DevOps agent workflows.
Prefer **MCP tools** (`agentia mcp start`) when available; otherwise shell with **`--json`**.
Always invoke commands as `agentia …` (on PATH).

---

## Setup (human / CI — not the agent)

```sh
agentia auth set --cicd <api-key> --region na|emea|emea2|apac|apac2
# or
agentia auth set --cicd <api-key> --custom-url https://test.api.copado.com
# optional CRT
agentia auth set --cicd <api-key> --region na --crt <pat>
```

Cursor MCP:

```json
{
  "mcpServers": {
    "agentia": {
      "command": "agentia",
      "args": ["mcp", "start"]
    }
  }
}
```

Optional project defaults (used by `work create`):

```sh
agentia project default set --project <id> --environment <id> --team <id> --sprint <id> --assign-me
agentia project default get --json
```

---

## Global rules

- Almost all commands support `--json` → `{ status, result }` (or `{ error }`). Prefer JSON; do not parse tables/spinners.
- Pipeline / job commands need `--user-id` and `--organization-id` (MCP: `userId`, `organizationId`).
- Metadata inspect/compare/deps typically need `--pipeline-id`, `--source-org-id`, `--source-credential-id` (+ target/branch as needed).
- Never print secrets from `auth get`. Do not expose keychain material.
- Confirm before destructive ops: `job kill`, `work delete`, conflict resolve/unresolve.

---

## Full CLI command inventory

### `auth` — credentials (keychain)

| Command | Purpose |
| --- | --- |
| `agentia auth set` | Store CICD API key (`--cicd`), optional `--crt`, `--region` or `--custom-url` |
| `agentia auth get` | Show stored credentials (`--cicd` / `--crt` selectors). **Do not echo secrets to the user.** |

### `user`

| Command | Purpose |
| --- | --- |
| `agentia user get [ID]` | Get user by ID; defaults to authenticated user (`me`) |

### `project`

| Command | Purpose |
| --- | --- |
| `agentia project list` | List projects (`--mine` optional) |
| `agentia project default get` | Show defaults (project, environment, team, sprint, epic, feature, assignMe); `--global` |
| `agentia project default set` | Set defaults (`--project`, `--environment`, `--team`, `--sprint`, `--epic`, `--feature`, `--assign-me`, `--global`) |
| `agentia project default unset` | Clear selected defaults |

Defaults map into user-story create payload:

| Default key | Work field |
| --- | --- |
| `project` | `project` |
| `environment` | `sourceEnvironment` |
| `team` | `team` |
| `sprint` | `sprintId` |
| `epic` | `epic` |
| `feature` | `feature` |
| `assignMe` | `assignee` (current user) |

### `environment`

| Command | Purpose |
| --- | --- |
| `agentia environment list` | List/filter environments |
| `agentia environment get ID` | Get environment |
| `agentia environment create NAME` | Create environment |
| `agentia environment update ID` | Update environment |
| `agentia environment auth status ID` | Validate credential auth (`--credentialid`) |
| `agentia environment auth web login ID` | Browser web login for credential (`--credentialid`, `--port`, `--timeout`) |

### `pipeline`

| Command | Purpose |
| --- | --- |
| `agentia pipeline list` | List pipelines (`--user-id`, `--organization-id`) |
| `agentia pipeline get ID` | Describe pipeline |
| `agentia pipeline connection list` | List connections (`--pipeline-id` optional) |

### `work` — user stories

| Command | Purpose |
| --- | --- |
| `agentia work list` | List/filter stories (`--name`, `--title`, `--status`, `--project-id`, `--project-name`, `--assignee-id`, `--assignee-name`, `--owner-id`, `--owner-name`, `--assigned-to-me`, `--owned-by-me`, …) |
| `agentia work get ID` | Full story header + specs + env/pipeline context |
| `agentia work create` | Create story (mutation flags + project defaults) |
| `agentia work update ID` | Update story fields |
| `agentia work delete ID` | Delete story (**confirm first**) |

Important `work get` fields for agents:

- Specs: `functionalRequirements`, `technicalSpecifications`, `acceptanceCriteria`, `asA` / `wantTo` / `soThat`
- Context: `project`, `projectName`, `sourceEnvironment`, `sourceEnvironmentName`, `sourceCredential`, `sourceOrgId`, `pipelineId`, `status`, `components`, branches/release fields

Mutation flags (create/update) include: `--title`, `--status`, `--project`, `--source-environment`, `--source-credential`, `--functional-requirements`, `--technical-specifications`, `--acceptance-criteria`, `--as-a`, `--want-to`, `--so-that`, `--assignee`, `--owner-id`, `--team`, `--sprint-id`, `--epic`, `--feature`, `--theme`, `--priority`, `--planned-points`, `--actual-points`, `--release-id`, `--record-type`, `--close-date`, `--cancellation-reason`, `--excluded-from-cbm` / `--no-excluded-from-cbm`.

### `job` — job executions

| Command | Purpose |
| --- | --- |
| `agentia job list` | List jobs; filters: `--id`, `--status`, `--name`, `--type`, `--parent` (e.g. user story Id), `--context`, `--limit` + pipeline headers |
| `agentia job get ID` | Job + ordered steps (failure detail) |
| `agentia job run ID` | Run all steps (`--restart` optional) |
| `agentia job resume ID` | Resume outstanding steps |
| `agentia job pause ID` | Pause (resumable cancel) |
| `agentia job kill ID` | Cancel (**confirm first**) |

### `metadata`

| Command | Purpose |
| --- | --- |
| `agentia metadata list` | Search metadata index |
| `agentia metadata content get` | Retrieve file content (`--api-name`, `--metadata-type`, `--source`, …) |
| `agentia metadata content compare` | Unified diff between orgs/branches |
| `agentia metadata index compare` | Index-level compare (`--comparison-mode`) |
| `agentia metadata dependency list` | Dependencies; supports `--from-changes`, `--base-ref`, `--stdin`, `--file`, `--retrieve-mode` |
| `agentia metadata refresh run` | Trigger index refresh (`--env`, pipeline/org/credential flags) |
| `agentia metadata refresh deleted` | Refresh deleted-metadata index |
| `agentia metadata refresh status` | Refresh job status (`--job-id`) |

### `promotion`

| Command | Purpose |
| --- | --- |
| `agentia promotion list` | List/filter promotions (pipeline, project, source/dest env, status, …) |
| `agentia promotion get ID` | Get promotion |
| `agentia promotion conflict list -p ID` | List merge conflicts |
| `agentia promotion conflict get ID -p ID` | Raw conflict content (`--output` file optional) |
| `agentia promotion conflict resolve ID -p ID` | Resolve (`--mode auto\|manual`, `--file` for manual) — **confirm** |
| `agentia promotion conflict unresolve ID -p ID` | Undo resolution — **confirm** |

### `mcp`

| Command | Purpose |
| --- | --- |
| `agentia mcp start` | Long-running MCP server over stdio (no `--json`) |

### Built-ins

- `agentia help [COMMAND]`
- `agentia plugins`

---

## MCP tools (prefer these)

JSON-safe; secrets redacted.

| Topic | Tools |
| --- | --- |
| Environment | `agentia_environment_list`, `_get`, `_create`, `_update` |
| User | `agentia_user_get` |
| Project | `agentia_project_list`, `agentia_project_default_get`, `_set`, `_unset` |
| Pipeline | `agentia_pipeline_list`, `_get`, `_connection_list` |
| Work | `agentia_work_list`, `_get`, `_create`, `_update`, `_delete` |
| Job | `agentia_job_list`, `_get`, `_run`, `_resume`, `_pause`, `_kill` |
| Promotion | `agentia_promotion_list`, `_get` |
| Metadata | `agentia_metadata_list`, `_content_get`, `_content_compare`, `_index_compare`, `_dependency_list` |

### CLI-only today (use shell + `--json`)

- `auth *`
- `environment auth status|web login`
- `metadata refresh *`
- `promotion conflict *` (list/get/resolve/unresolve)
- Dependency `--from-changes` / stdin / file variants are richer on CLI than the MCP dependency tool (MCP takes explicit name/type selections)

---

## Recommended agent playbooks

### 1) Orient

1. `agentia user get` / `agentia project default get` / `agentia project list`
2. `agentia pipeline list` + `agentia pipeline connection list` → cache org/credential/env IDs
3. Do not invent Salesforce IDs

### 2) Understand a user story

1. `agentia work list` (e.g. assigned-to-me / name / status) → pick ID
2. `agentia work get <id>`
3. Read `functionalRequirements` + `technicalSpecifications` (+ acceptance criteria) to decide changes
4. Note `sourceEnvironment`, `sourceOrgId`, `sourceCredential`, `pipelineId` for later metadata/job calls

### 3) Implement + dependency check

1. Make implementation changes and commit to Git when asked
2. `agentia metadata dependency list --from-changes --base-ref origin/main --pipeline-id … --source-org-id … --source-credential-id … --target-org-id … --json`
3. If missing dependencies are detected and not included in the change set: notify as missing on destination and offer to retrieve/include them

### 4) Job lifecycle

1. `agentia job list --parent <userStoryId> …` (or name/status/context filters)
2. `agentia job get <id>` for step-level failure detail
3. `agentia job run` / `resume` / `pause` / `kill` only with clear intent; confirm kill

### 5) Metadata impact / compare

1. `agentia metadata list` → filter type/name
2. `agentia metadata dependency list`
3. `agentia metadata content get` / `content compare` / `index compare` before promote
4. Refresh index with `agentia metadata refresh *` when index is stale

### 6) Promotion / conflicts

1. `agentia promotion list` / `agentia promotion get`
2. `agentia promotion conflict list -p <promotionId>`
3. `agentia promotion conflict get` → propose resolution
4. `agentia promotion conflict resolve` only with explicit approval (`--mode auto|manual`)

---

## Output contract

- Success: JSON with `status: 0` and `result`
- Failure: non-zero / `error.message` — surface API text to the user
- MCP tools return structured tool results (same domain payloads, redacted)
