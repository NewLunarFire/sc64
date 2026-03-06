#!/bin/bash

# Diffs 2 binary files to see the difference
# Starts by converting those to a textual representation with the help of xxd
# Then use diff to see the comparaison
xxd $1 $1.hex
xxd $2 $2.hex
diff $1.hex $2.hex 