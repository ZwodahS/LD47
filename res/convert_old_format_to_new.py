#!/usr/bin/env python3

import json
import sys

if len(sys.argv) == 1:
    sys.exit(0)

filename = sys.argv[1]
gridsize = None
if len(sys.argv) > 2:
    gridsize = sys.argv[2]
    gridsize = gridsize.split(",")
    gridsize = (int(gridsize[0]), int(gridsize[1]))

with open(filename) as f:
    data = json.loads(f.read())

frames = data

output = {}
output["gridtype"] = "fixed" if gridsize is not None else "dynamic"
if gridsize:
    output["gridsize"] = { "x": gridsize[0], "y": gridsize[1] }

output["frames"] = {}
for k, v in frames.items():
    if gridsize is not None:
        if v["x"] % gridsize[0] != 0 or v["y"] % gridsize[1] != 0:
            print(f"Wrong gridsize: {v}");
            sys.exit(0)
        output["frames"][k] = { "x": int(v["x"] / gridsize[0]), "y": int(v["y"] / gridsize[1]) }
    else:
        output["frames"][k] = v

with open(filename + ".processed", "w") as f:
    print(json.dumps(output, indent=2), file=f)

