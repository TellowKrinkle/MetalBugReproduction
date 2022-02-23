# Broken Float → UChar optimization

The shader compiler mistakenly optimizes `uchar(floatval) & 0x80` to `char(floatval) < 0` in an attempt to save an instruction

## Known Broken GPUs

Intel GPUs from Broadwell onwards seem to be affected

Please file an issue if you find an affected pre-Broadwell GPU or a non-affected Broadwell+ GPU

## Running

To run:
```bash
swift IntelFail.swift
```