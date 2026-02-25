#!/bin/bash

# Diffs 2 binary files to see the difference
# Starts by converting those to a textual representation with the help of xxd
# Then use diff to see the comparaison
xxd bak.z64 bak.hex
xxd rom.z64 rom.hex
diff bak.hex rom.hex 