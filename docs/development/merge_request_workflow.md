# Merge Request Workflow

GitLab Environment Toolkit team uses the [Reviewers feature](https://docs.gitlab.com/ee/development/code_review.html#dogfooding-the-reviewers-feature) in the code review process. The process looks like this:

1. Author opens a merge request in a project. Label ~"workflow::in dev" is applied by default.
1. When ready for review, the Author applies the ~"workflow::ready for review" label and mentions `@gl-quality/get-maintainers`.
1. When they are able to work on the merge request, a Maintainer adds themselves under the Reviewers section, and adds the ~"workflow::in review" label.
1. The Maintainer works with the Author to get the merge request to a state where they approve it.
    - The Maintainer could apply ~"workflow::in dev" to the merge request if there are additional changes that need to be done by the Author. When the merge request is ready to be handed back for further review, Author should apply ~"workflow::ready for review" label and mention the Maintainer who previously reviewed the merge request.

**NOTE**: If you are working on a merge request that requires a response quicker than the [First-response SLO](https://about.gitlab.com/handbook/engineering/workflow/code-review/#first-response-slo), please `@` mention the `gl-quality/get-maintainers` group in order to alert the team.

## Merge Request Workflow labels

Labels help to provide a high-level overview for the merge request state. We use the following labels:

- ~"Quality" and ~"section::enablement": default labels
- ~"workflow::in dev": work on merge request is in progress
- ~"workflow::ready for review": merge request is ready for review
- ~"workflow::in review": merge request is in the process of being reviewed by maintainers
- ~"breaking change": merge request adds a breaking change

## Assigning Merge Requests

We recommend contributors to **not** assign merge requests to an individual when looking for the review, unless there is a specific reason someone should look at a merge request. Rather, the merge request should have the ~"workflow::ready for review" label applied, and a reviewer will add themselves under the Reviewers section when they are beginning to look into it. When looking for a merge request to work on, consider the [First-response SLO](https://about.gitlab.com/handbook/engineering/workflow/code-review/#first-response-slo). Anything in danger of breaching that deadline should be looked at first.
