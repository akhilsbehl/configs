# Exports and downloads

Email export defaults to HTML, not binary MSG. Outlook SaveAs uses format 5. Headers are retained as provided by Outlook; companion `_files` directories are copied. Attachments are separate files prefixed `attachment-<index>-` to avoid duplicate names. Do not claim every inline image or remote asset has been embedded: Outlook's export may still reference external resources.

Windows APIs save into a unique Windows temporary staging directory. The WSL bridge copies files into the exact requested absolute Linux output directory (default `/tmp`), checks all destination names before copying, verifies each file by SHA-256, restricts files to mode 600 and directories it creates to 700, and deletes staging only after success. Existing directory permissions are left unchanged. The email's read state is not changed.

Destination conflicts stop the operation. No overwriting or version guessing. Name sanitisation flattens attachment paths and rejects invalid/reserved names. The bridge rejects symlink source artifacts. Integrity errors can leave partial output and staging files; surface paths/failures and inspect before retry. No attachment execution.

Shared-file download verifies size against Graph metadata and then copy integrity. This proves downloaded bytes and transfer integrity, not that the document's claims are correct or that a file did not change during search. Large files are currently hashed in memory in the Node bridge; use caution for very large downloads. No ZIP extraction or recursive folder download.

Only report files saved when returned artifact entries contain `verified: true` and a Linux `path`. Companion directories are verified recursively. Private HTML files can contain active/remote content: do not automatically open or trust them.
