# Broken Mipmap Rendering

Rendering with mipmaps is slightly nondeterministic

(This breaks Dolphin's fifo ci)

## Known Broken GPUs

Apple M1s seem to be affected

Please file an issue if you find an affected non-M1 GPU or a non-affected M1 GPU

## Running

To run:
```bash
swiftc -O RepeatedRunTest.swift
./RepeatedRunTest
```
