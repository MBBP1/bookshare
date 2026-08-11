import time, os, sys
import pyautogui as pg

pg.FAILSAFE = True  

print("=== Auto Page Capture (Windows - Mouse Click Version) ===")
print("=== Vaalg path to folder for saving images ===")
folder = input("Folder for pictures (empty = ./captures): ").strip() or "captures"
os.makedirs(folder, exist_ok=True)

try:
    total = int(input("Number of pages to be saved? "))
except:
    print("Not a valid number.")
    sys.exit(1)

delay_between = float(input("Wait time after click before screenshot (sec., eg 0.4): ") or "0.4")


print("\nPlace your mouse on the TOP LEFT corner of the page. You have 5 seconds.")
time.sleep(5)
x1, y1 = pg.position()

print("Place your mouse on the LOWER RIGHT corner of the page. You have 5 seconds.")
time.sleep(5)
x2, y2 = pg.position()

x, y = min(x1, x2), min(y1, y2)
w, h = abs(x2 - x1), abs(y2 - y1)
if w < 50 or h < 50:
    print("Area too small.")
    sys.exit(1)


print("\nPlace your mouse on the 'next page' button. You have 5 seconds.")
time.sleep(5)
next_x, next_y = pg.position()

print("\nStarting in 3 seconds. Make sure PDF/browser is on page 1.")
time.sleep(3)

for i in range(1, total + 1):
    
    img = pg.screenshot(region=(x, y, w, h))
    out = os.path.join(folder, f"page_{i:03d}.png")
    img.save(out)
    print(f"[{i}/{total}] Saved: {out}")

    if i == total:
        break

    
    pg.click(next_x, next_y)
    time.sleep(delay_between)

print("Done. Files saved in:", os.path.abspath(folder))