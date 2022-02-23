# Triangles aren't vertex order invariant

Triangles which need to be clipped interpolate slightly differently depending on their vertex order.
In addition, triangles sent through the tessellation pipeline with tessellation factors set in such a way that the tessellator doesn't actually do anything have different vertex order than triangles that don't.  (This wouldn't matter if it weren't for the above issue.)

## Known Broken GPUs

All Apple GPUs seem to be affected

Please file an issue if you find an affected non-Apple GPU or a non-affected Apple GPU

## Running

To run the app:
* Build the project with Xcode 11 or later.
* Target macOS 10.14 or later.

The application will draw two passes.  In the first pass, it will draw with the pass1 configuration and depth write enabled.  In the second pass, it will draw with the pass2 configuration, first in red with depth greater, then in green with depth equal, and finally in blue with depth lower.  A passing GPU should have all triangles identical in both passes, and should therefore be entirely green.  A failing GPU will have some sections either red or blue.
