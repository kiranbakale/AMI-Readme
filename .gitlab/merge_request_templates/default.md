## What does this MR do?

<!-- Briefly describe what this MR is about. -->


<!-- Set the appropriate milestone -->
/milestone %

## Related issues

<!-- There should always be a corresponding issue raised and reviewed by the GET maintainers team -->
<!-- Link related issues below. Insert the issue link or reference after the word "Closes" if merging this should automatically close it. -->

## Author's checklist

When ready for review, the Author applies the ~"workflow::ready for review" label and mention `@gl-quality/get-maintainers`:

- Merge request:
  - [ ] Corresponding Issue raised and reviewed by the GET maintainers team.
  - [ ] Merge Request Title and Description are up to date, accurate, and descriptive
  - [ ] MR targeting the appropriate branch
  - [ ] MR has a green pipeline
- Code:
  - [ ] Check the area changed works as expected. Consider testing it in different environment sizes (1k,3k,10k,etc.).
  - [ ] Documentation created/updated in the same MR.
  - [ ] If this MR adds an optional configuration - check that all permutations continue to work.
  - [ ] For Terraform changes: setup a previous version environment, then run a `terraform plan` with your new changes and ensure nothing will be destroyed. If anything will be destroyed and this can't be avoided please add a comment to the current MR.
- [ ] Create any follow-up issue(s) to support the new feature across other supported cloud providers or advanced configurations. Create 1 issue for each provider/configuration. Contact the [Quality Enablement](https://about.gitlab.com/handbook/engineering/quality/sec-enablement-qe-team/) team if unsure.

/label ~"Quality" ~"section::enablement"
