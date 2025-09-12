# GODOT BLIT SPRITE 2D 
**<ins>a shit ass gd script that helps me make more fnf !!!</ins>**



**Have you ever been using a sprite 2D in godot and you have region rect turned on and a shader applied 
and it messes up because there is no UV correction?**

_No?_ aw man that was my whole selling point :(

either way this solves the problem for me of having to modify every shader to consider region rects, whilst also taking into account json loading, positioning, rotation and all that shiz

**just download the entire project or the blit sprite folder if you too want to make some wacky fnf stuff or whatever else you can find to do with Ts** 

_**SIDE NOTE:**_ The json format needed is in technicaly a non-standard format for FNF, So using 

```
Blit_Sprite2D.BLIT_RES.convert_XML("path/to/file.xml","save/location.json")
Blit_Sprite2D.BLIT_RES.append_offsets("path/to/converted.json","path/to/offsets.json")
```

is necessary in order to use this, someday I might update this and add a UI for doing that in the editor itself but for now running the scene is needed for that to work
