# Broken shared buffer coherency

If you copy from a private buffer to a shared buffer in one command buffer, then update it atomically in another, the CPU will never see the atomic updates

## Known Broken GPUs

- AMD Discrete GPUs

Please file an issue if you find an affected non-AMD GPU or a non-affected AMD GPU

## Running

To run:
```bash
swift AMDCoherency.swift
```
