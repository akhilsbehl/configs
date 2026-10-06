# Quick request templates

Copy one JSON file into a private temporary directory, replace placeholders, and run `scripts/run.sh /absolute/request.json`. These are independent requests, not batch recipes. Write templates deliberately have `approved: false`; change only after the user authorises the exact action and content. Never run examples as an installation test suite.

For Drafts or Snoozed, adapt the read-only list template's `folder`. For unread review, page through all returned item types and reconcile counts before recommending changes. For a directory profile via Graph, use `operation=directory`, `action=profile`, `identity=<UPN or ID>` and optional `relationships=true`.

Use returned IDs and links, not hard-coded personal data. Calendar examples use a placeholder timezone and future date so they must be reviewed. File search is KQL and can match content, not just filenames.
