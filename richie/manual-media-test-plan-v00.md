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

## MI-01. Remote HTTPS image

Scroll to `Remote HTTPS fixture`.

Expected: the W3C image loads automatically when it enters the viewport. It does
not require a load button. Its request in the Network panel does not carry the
Richie review URL as a referrer.

Hover the image and add this comment:

> Confirm this remote image is still required.

Keep this operation open for MI-04.

## MI-02. Failed and blocked images

Inspect the 4 fixtures under `Fallback fixtures`.

Expected:

- the missing local image shows `Image could not load` and its exact Markdown;
- the non-image local file shows the same safe fallback after the media route
  rejects it;
- the HTTP image is blocked without loading;
- the unresolved reference shows `Image reference is missing its definition`;
- none of these cases displays an active broken-image icon without source context.

Hover each fallback. Confirm the same whole-image menu remains available.

## MI-03. Reference-style image

Inspect the reference-style image below.

Expected: the image source resolves through its definition, and the whole image
is one review target. Add and remove a comment to confirm the normal image
review controls remain available.

## MI-04. Image review presentation and export

Use the remote image under `Remote HTTPS fixture`.

1. Confirm the open comment is visible in the feedback inventory.
2. Remove the comment.
3. Finish the review.

Expected export:

- the original file is unchanged;
- no rendered HTML, image bytes, token, or local media URL appears in Markdown.

## Remote HTTPS fixture

![W3C remote image](https://www.w3.org/Icons/w3c_home.png)

## Reference-style fixture

![Reference screenshot][reference-screenshot]

[reference-screenshot]: https://www.w3.org/Icons/w3c_home.png "Reference image"

## Fallback fixtures

![Missing local image](./does-not-exist.png)

![Not an image](./spec.md)

![Blocked HTTP image](http://www.w3.org/Icons/w3c_home.png)

![Missing reference][definition-does-not-exist]
