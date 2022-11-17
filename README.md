# Broken Discard with Early Depth

Shaders with early depth tests that can also discard end up discarding regardless of whether they actually executed the discard or not

## Known Broken GPUs

All Apple GPUs seem to be affected

Please file an issue if you find an affected non-Apple GPU or a non-affected Apple GPU

## Configure the Sample Code Project

To run the app:
* Build the project with Xcode 11 or later.
* Target an iOS device or simulator with iOS 11 or later.
