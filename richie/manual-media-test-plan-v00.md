# Richie Markdown image smoke test

Use this focused plan only for the new Markdown image behavior. Do not rerun the
full Richie manual suite.

## Setup and evidence

1. Build and start the current Richie service.
2. Open this file with `richie review manual-media-test-plan-v00.md`.
3. Keep the browser console and Network panel open.
4. Capture a screenshot only when actual rendering differs from the expected
   state.
5. Remove test feedback after each case unless the case says to keep it for the
   export check.

## MI-01. Local and absolute raster images

Confirm the relative image under `Image fixtures` renders at the document width
without stretching beyond the reading area. Confirm its alt text is
`Relative screenshot`.

Confirm the absolute-path image also renders. The automated suite separately
verifies an absolute image outside the document directory.

Hover each image. Confirm one menu appears with `Comment`, `Replace`, and `Delete`.
No alt-text, URL, crop, or region-specific action should appear.

Expected: both images remain readable, preserve their natural proportions, and
act as one whole-image target each.

## MI-02. Remote HTTPS image

Scroll to `Remote HTTPS fixture`.

Expected: the W3C image loads automatically when it enters the viewport. It does
not require a load button. Its request in the Network panel does not carry the
Richie review URL as a referrer.

Hover the image and add this comment:

> Confirm this remote image is still required.

Keep this operation open for MI-04.

## MI-03. Failed and blocked images

Inspect the 4 fixtures under `Fallback fixtures`.

Expected:

- the missing local image shows `Image could not load` and its exact Markdown;
- the non-image local file shows the same safe fallback after the media route
  rejects it;
- the HTTP image is blocked without loading;
- the unresolved reference shows `Image reference is missing its definition`;
- none of these cases displays an active broken-image icon without source context.

Hover each fallback. Confirm the same whole-image menu remains available.

## MI-04. Image review presentation and export

Use the linked image under `Linked-image fixture`.

1. Add a comment: `Check the linked destination and image together.`
2. Confirm the card scope is `media` and quotes the complete outer link syntax.
3. Remove that comment.
4. Replace the linked image with:

   `![Replacement screenshot](./figs/table-replace-2026-07-29-16-52-07.png)`

5. Confirm the image becomes dimmed and a visible `Replacement:` panel shows the
   literal Markdown. Confirm Richie does not render the proposed replacement.
6. Remove the replacement.
7. Delete the linked image.
8. Confirm the image is dimmed with a visible `Delete image` overlay.
9. Click `Jump to text` and confirm the linked image returns to view.
10. Finish the review.

Expected export:

- the original file is unchanged;
- the commented copy contains the open remote-image comment and linked-image
  deletion;
- both markers say `image` and quote the complete target syntax;
- the linked-image marker appears after the outer closing parenthesis;
- no rendered HTML, image bytes, token, or local media URL appears in Markdown.

## Image fixtures

### Relative screenshot

![Relative screenshot](./figs/search-nav-2026-07-29-14-39-31.png "Relative image")

### Absolute-path screenshot

![Absolute screenshot](/home/akhil/warchives/richie/figs/table-replace-2026-07-29-16-52-07.png)

### Remote HTTPS fixture

![W3C remote image](https://www.w3.org/Icons/w3c_home.png)

### Linked-image fixture

[![Linked screenshot](./figs/mermaid-deletion-2026-07-29-16-57-07.png)](https://www.w3.org/)

### Reference-style fixture

![Reference screenshot][reference-screenshot]

[reference-screenshot]: ./figs/top-bar-2026-07-29-15-03-12.png "Reference image"

### Fallback fixtures

![Missing local image](./figs/does-not-exist.png)

![Not an image](./spec.md)

![Blocked HTTP image](http://www.w3.org/Icons/w3c_home.png)

![Missing reference][definition-does-not-exist]
