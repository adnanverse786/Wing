# DexOS Boot Animation Template

Place sequential frame images in:
- `part0/` for intro (plays once)
- `part1/` for looping segment (loops until boot complete)

Then zip from inside this folder:

```bash
zip -r9 ../bootanimation.zip desc.txt part0 part1
```

Do not use compression methods unsupported by Android boot animation service.
