<!--
# README first!

This template covers all of the steps required to do a release of the GitLab Environment Toolkit. Issues should only be raised with this template by a GET maintainer who is about to do a release.
-->

Release steps:

- [ ] Confirm no further major MRs are incoming
- [ ] If creating a Backport:
  - [ ] [Create](https://gitlab.com/gitlab-org/gitlab-environment-toolkit/-/branches/new) `support/<GET_major_minor_x>` branch from GET tag. For example, for patch release `2.8.5` - create `support/2.8.x`.
    - Note that the branch must conform to this naming scheme for it to be a protected branch.
  - [ ] Create Merge Request targeting `support/<GET_major_minor_x>` with the following changes:
    - Cherry-picked commits that should be backported
    - Updated GET version strings in repo
- [ ] Update any version strings in repo
  - [ ] [`ansible/galaxy.yml`](../../ansible/galaxy.yml#L3)
- [ ] Complete the following Terraform smoke tests to ensure there's no unexpected data loss from VMs being rebuilt by upgrading from last release. (Optional - Only required for Major or Minor releases)
  - [ ] GCP Omnibus Upgrade
  - [ ] GCP Cloud Native Hybrid Upgrade
  - [ ] AWS Omnibus Upgrade
  - [ ] AWS Cloud Native Hybrid Upgrade
  - [ ] Azure Omnibus Upgrade (Only if any Azure Terraform changes have been made)
- [ ] Release notes created - Should follow similar style as previous releases. [Use this link](https://gitlab.com/gitlab-org/gitlab-environment-toolkit/-/commits/main?ref_type=heads) to go through and collect all notes from last release SHA.
  - Use previous releases for formatting. Big items → Smaller items → Upgrade notes / Breaking changes
  - Cite authors when appropriate
- [ ] Create release
  - [ ] Select to create the tag on the release page but make sure to make it a new _lightweight_ tag with no specific notes.
  - [ ] Fill in release notes
    - Use previous releases for formatting. Big items → Smaller items → Upgrade notes / Breaking changes
    - Cite authors when appropriate
    - [Use this link](https://gitlab.com/gitlab-org/gitlab-environment-toolkit/-/commits/main?ref_type=heads) for reference of what's gone in compared to last release SHA.
    - Remember to also link in the Docker and Terraform registries (links will be the same as previous releases)
- [ ] Announced release in `#gitlab-environment-toolkit` and `#quality` Slack channels as well as the Engineering week-in-review

/label ~"type::maintenance" ~"maintenance::release"
