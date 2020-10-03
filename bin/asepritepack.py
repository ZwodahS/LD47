#!/usr/bin/env python3

import json
import sys
from PIL import Image
import rectpack

"""
This is currently a work in progress
"""
if __name__ == "__main__":
    doc="""
    Each argument should be a png:json pair.

    For example

    {0} output.png:output.json tiles.png:tiles.json background.png:background.json

    The first pair will always be the output file.
    """

    if len(sys.argv) <= 2: # we need minimum 3 args to work
        print(doc.format(sys.argv[0]))
        sys.exit(0)

    outputfile = sys.argv[1].split(":")
    if len(outputfile) != 2:
        print("Unable to process: {}".format(sys.argv[2]))
        sys.exit(1)

    mappings = {}
    for inputfile in sys.argv[2:]:
        try:
            p, j = inputfile.split(":")
        except:
            print("Fail to process: {}".format(inputfile))
            sys.exit(1)
        mappings[j] = p

    # load all the files provided and load the images
    loaded = {}
    for k, v in mappings.items():
        loaded[k] = {}

        with open(k) as f:
            json_data = json.loads(f.read())
            loaded[k]["conf"] = json_data;

        loaded[k]['img'] = Image.open(v)

    # for each of the files provided load all the frameTags
    loadedFrameTags = {}
    for k, v in loaded.items():
        conf = v["conf"]
        for frame in conf["meta"]["frameTags"]:
            # check for duplicate
            if frame["name"] in loadedFrameTags:
                print("duplicated: {}".format(frame["name"]))
                sys.exit(0)
            loadedFrameTags[frame["name"]] = { "conf": conf, "img": v["img"], "frame": frame }

    # HACK: need to change once we need to pack into multiple images
    size = (1024, 1024)
    packed_image = Image.new('RGBA', size, 0x00000000)

    # prepare the packer
    packer = rectpack.newPacker(rotation=False)
    packer.add_bin(size[0], size[1])

    # for each of the loadedFrameTags, add each of the frame into the packer
    for name, frameTag in loadedFrameTags.items():
        conf = frameTag["conf"]
        for frame in range(frameTag["frame"]["from"], frameTag["frame"]["to"] + 1):
            f = conf["frames"][frame]
            packer.add_rect(f["spriteSourceSize"]["w"], f["spriteSourceSize"]["h"], (name, frame))

    # pack
    packer.pack()

    # unpack all the rect and store them in the original conf so we can pack them properly
    # We need all the frames to be together due to the "from" and "to" of frameTags
    for rect in packer.rect_list():
        rid = rect[5]
        name, frame_no = rid
        frameTag = loadedFrameTags[name]
        # set update the frames data for the rect to paste into
        frameTag["conf"]["frames"][frame_no]["rect"] = rect

    # prepare the final output frames and frameTags
    frames = []
    frameTags = []
    for frameName, frameTag in loadedFrameTags.items():
        oldFrameTag = frameTag["frame"]
        conf = frameTag["conf"]
        img = frameTag["img"]
        frameFrom = len(frames)

        # iterate each of the frame of the frameTag and paste the sub image to the right location
        for frameNo in range(frameTag["frame"]["from"], frameTag["frame"]["to"] + 1):
            f = conf["frames"][frameNo]
            r = f["frame"]
            sourceRect = (r["x"], r["y"], r["x"] + r["w"], r["y"] + r["h"])
            targetRect = f["rect"]

            # once we have multiple bin, then we will need to not default to packed_image
            packed_image.paste(
                frameTag['img'].crop(sourceRect),
                (targetRect[1], targetRect[2], targetRect[1] + targetRect[3], targetRect[2] + targetRect[4])
            )

            # add the frames
            frames.append({
                "filename": f["filename"],
                "frame": { "x": targetRect[1], "y": targetRect[2], "w": targetRect[3], "h": targetRect[4] },
                "rotated": f["rotated"],
                "trimmed": f["trimmed"],
                "spriteSourceSize": { "x": 0, "y": 0, "w": targetRect[3], "h": targetRect[4] },
                "sourceSize": { "w": size[0], "h": size[1] },
                "duration": f["duration"],
            })

        frameTo = len(frames) - 1

        # update the frametags
        frameTags.append({
            "name": frameName, "from": frameFrom, "to": frameTo, "direction": oldFrameTag["direction"]
        })

    # output the same format as aseprite
    outputjson = {
        "frames": frames,
        "meta": {
            "image": outputfile[0].split('/')[-1],
            "format": "RGBA8888",
            "size": {"w": size[0], "h": size[1]},
            "scale": "1",
            "frameTags": frameTags
        }
    }
    with open(outputfile[1], "w") as f:
        print(json.dumps(outputjson, indent=2), file=f)

    # output the new image
    packed_image.save(outputfile[0])
