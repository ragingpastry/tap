# Tap

## Description

Command-line utility used to trigger GitlabCI pipelines

## Usage

```bash
tap run -h
Usage:
  run [options] [variables ...]

Arguments:
  [variables ...]

Options:
  -h, --help
  -b, --branch=BRANCH        The name of the branch. Will use current branch if not provided
  -p, --api-key=API_KEY      API key to use for authentication (env: GITLAB_API_KEY)
```

The API key can be defined via the environment variable `GITLAB_API_KEY`

The tool will attempt to auto-detect the current working branch if the `--branch` flag is not given.

We also attempt to auto-detect the project path based on `origin`. Currently this is not configurable.

Variables must be passed in this format: `VAR1=VAL1 VAR2=VAL2`

Currently this is hardcoded to look at repo.dso.mil. This will be changed in the future.


## Example

`tap run --api-key <API_KEY> "DEPLOYMENT_TYPE=app-deploy" "DEPLOYMENT=staging-monitoring"`
