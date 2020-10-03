#!/usr/bin/env python3

import json
import sys

if len(sys.argv) == 1:
    print("""
This will convert all the frames in the json into a dictionary,
filename -> { x, y, w, h, r }

This assumes that the filename is properly set when exporting from aseprite
    """)
    print("[0] [name] [out]".format(sys.argv[0]))
    sys.exit(0)

with open(sys.argv[1]) as f:
    data = json.loads(f.read())

frames = data["frames"]
processed_frames = {}

for frame in frames:
    processed_frames[frame["filename"]] = frame["frame"]
    processed_frames[frame["filename"]]["r"] = 1 if frame["rotated"] else 0

output = {
    "gridtype": "dynamic",
    "frames": processed_frames,
}

with open(sys.argv[2], "w") as f:
    print(json.dumps(output, indent=2), file=f)

