# Pending CHANGELOG - Project framework

This file contains all the upcoming changes for the next version for module.

When ready to make a new version, please move them to `CHANGELOG.md`.
A single version should be prepared at a time to avoid conflicts in that file.

Please indicate in bold if the new version will contain breaking changes.
E.g. **This version contains breaking changes**

# Waiting for versioning


## Makefiles
- **Fix build of requirements in dist folder of Google function**
- Integrate Python end-to-end (e2e) tests at module-level. As implemented in btdp-am repository.
  Global e2e tests can be made using a dedicated module.
- Add new module_type `gcb` to support modules without Dockerfile. For instance, to create modules dedicated for e2e-tests.

- **Fix check of explicit versioning of packages mentioned in requirements.txt**
- Fix pylint check that were looking at non-Python files too. Now only Python files should be considered

- Regroup the `%-all` and `%-module-<MODULE_NAME>` commands in a generic way. Any matching target will be run
- Rework some existence checks for needed files and directories.
  In particular, fail fast if BUILD_REQUIREMENTS is missing; or for unsupported module TYPE

## Configurations
- New samples have been created to handle the file integration pipeline defined in Confluence: https://confluence.e-loreal.com/display/BTDP/4.4.6.1+File+integration+pipeline.

## IaC
- Fix the issue #144 regarding the bad order of clustering fields in Bigquery tables
- Fix the permission given to the AMaaS service account to access the project. Moved the permission to setup/access.

## Workflows
- A subworkflows has been created to call sprocs more easily (**WAITING FOR DOCUMENTATION IN CONFLUENCE**)

## CI/CD
- Enable uniform bucket-level access on deploy and integration buckets
- Add step in module deploy triggers to run e2e-tests (if any); after deploy and before goto next.
  Per default, only on `qa`. A new boolean parameter `e2etests` is available in triggers env configuration.

## Init
- Enable uniform bucket-level access on deploy bucket
- **repair the target `all` of the Makefile of setup/init. The target `iac-clean-state` needs `iac-prepare` to have already been run**
- in target `iac-clean-state`, only try to import Apigee app in Terraform state if it is missing from it

## Modules
- Update to `0.3.0` the version of the shared `loreal` package in sample modules
- **Fix runtime of sample modules for Cloud function by upgrading it to `python310`. And raise timeout to 5 minutes.**

## Miscellaneous
- Fix some trailing whitespaces blocking commits
- Add lenient Mypy configuration file `.mypy.ini` to enforce using type hints in Python modules.
  No check is performed yet on type hints consistency
