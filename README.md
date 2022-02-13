# Broken Depth Write

Shaders that output to the dual source blend outputs (but don't use dual source blend) that also use fragment discard don't properly write depth

## Known Broken GPUs

Intel GPUs from Broadwell onwards seem to be affected

Please file an issue if you find an affected pre-Broadwell GPU or a non-affected Broadwell+ GPU

## Configure the Sample Code Project

To run the app:
* Build the project with Xcode 11 or later.
* Target an iOS device or simulator with iOS 11 or later.
