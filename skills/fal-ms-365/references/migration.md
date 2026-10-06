# Draft migration plan

The bundle is staged in `~/configs/skills/fal-ms-365`. It has not replaced the old skill or CLI and has not added a discovery symlink. Do not remove `query-ms-graph` during draft review.

Before activation:

1. Review Git diff and test report; do not stage unrelated user changes.
2. Test name lookup, directory fields and sharing-link download against the existing CLI with user-approved inputs. Preserve the legacy CLI until parity is accepted. Original script name-query behaviour and log output are not a compatibility guarantee of this draft.
3. Confirm Teams scopes have actually been consented; silently test endpoints. Never treat the helpdesk email as approval completion.
4. Authorise separate sandbox email/invite tests if writes need live validation. Never run them automatically during installation.
5. Approve activation and create a discovery symlink to this Git-tracked skill using the existing user skill-directory convention. Retire the old advertised skill only then; retain or adapt the legacy CLI deliberately.
6. Reload Pi and verify routing/frontmatter discovery. A draft on disk is not proof that Pi has loaded it.

Rollback: remove only the newly approved discovery link and restore the previous advertised skill. Keep all existing credentials, app registration and scripts intact. No automatic migration changes are performed by the scripts.
