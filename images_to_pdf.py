import sys, os, re
from pathlib import Path
from datetime import datetime
from PIL import Image

IMG_EXT = {".png", ".jpg", ".jpeg", ".bmp", ".tif", ".tiff", ".webp"}

def natural_key(s: str):
    return [int(t) if t.isdigit() else t.lower() for t in re.split(r'(\d+)', s)]

def collect_images_from_args(args):
    files = []
    for arg in args:
        p = Path(arg)
        if p.is_dir():
            files += [f for f in p.iterdir() if f.suffix.lower() in IMG_EXT]
        elif p.is_file() and p.suffix.lower() in IMG_EXT:
            files.append(p)
    return sorted(set(files), key=lambda p: natural_key(p.name))

def collect_images_interactive():
    folder = input("Mappe med billeder (tom = .): ").strip() or "."
    p = Path(folder)
    if not p.exists():
        print("Mappen findes ikke.")
        sys.exit(1)
    files = [f for f in p.iterdir() if f.suffix.lower() in IMG_EXT]
    return sorted(files, key=lambda p: natural_key(p.name))

def images_to_pdf(files, out_path):
    pages = []
    for f in files:
        im = Image.open(f)
        if im.mode in ("RGBA", "P"):
            im = im.convert("RGB")
        else:
            im = im.copy()
        pages.append(im)

    if not pages:
        print("Ingen gyldige billedfiler fundet.")
        return

    first, rest = pages[0], pages[1:]
    out_path.parent.mkdir(parents=True, exist_ok=True)
    first.save(out_path, save_all=True, append_images=rest)
    print(f"PDF lavet: {out_path}")

def main():
    files = collect_images_from_args(sys.argv[1:]) if len(sys.argv) > 1 else collect_images_interactive()
    if not files:
        print("Ingen billeder fundet.")
        sys.exit(1)

    base_name = files[0].parent.name or "billeder"
    ts = datetime.now().strftime("%Y-%m-%d_%H%M")
    out_name = f"{base_name}_{ts}.pdf"
    out = files[0].parent / out_name

    print(f"Antal billeder: {len(files)}")
    print("Foerste 3:", ", ".join(f.name for f in files[:3]) + (" ..." if len(files) > 3 else ""))
    images_to_pdf(files, out)

if __name__ == "__main__":
    main()