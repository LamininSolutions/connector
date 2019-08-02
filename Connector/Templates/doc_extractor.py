#!/usr/bin/env python3

import sys

if len(sys.argv) < 2:
    print("usage: {} <input>\n".format(sys.argv[0]), file=sys.stderr)
    sys.exit(1)

TAG = "rST"
START_TOKEN = "/*" + TAG + "*" * (80 - (len(TAG) + 4)) + "*"
END_TOKEN   = "**" + TAG + "*" * (80 - (len(TAG) + 4)) + "/"

with open(sys.argv[1]) as f:
    extracting = False

    for i, line in enumerate(f):
        if line.startswith(END_TOKEN):
            extracting = False
            continue
        if line.startswith(START_TOKEN):
            extracting = True
            continue
        if extracting:
            print(line, end="")
