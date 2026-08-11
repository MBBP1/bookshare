# ocr_pdf.py - Gør PDF søgbar med OCR
import sys
import os
import subprocess
from pathlib import Path

def check_tesseract_language(lang="dan"):
    """Tjek om Tesseract har det angivne sprog installeret"""
    try:
        result = subprocess.run(
            ["tesseract", "--list-langs"],
            capture_output=True,
            text=True,
            check=True
        )
        available_langs = result.stdout.strip().split('\n')[1:]
        return lang in available_langs
    except:
        return False

def main():
    print("=== OCR PDF - Goer PDF soegbar og kopierbar ===")
    print("")
    
    if not check_tesseract_language("dan"):
        print("Advarsel: Dansk sprogpakke mangler muligvis for Tesseract")
        print("   OCR kan stadig fungere med engelsk, men dansk vil vaere daarligere")
        print("   Download dan.traineddata fra: https://github.com/tesseract-ocr/tessdata")
        print("")
    
    if len(sys.argv) > 1:
        input_pdf = sys.argv[1]
    else:
        input_pdf = input("Sti til PDF-fil: ").strip()
        if not input_pdf:
            print("Ingen fil angivet.")
            sys.exit(1)
    
    input_path = Path(input_pdf)
    if not input_path.exists():
        print(f"Filen findes ikke: {input_pdf}")
        sys.exit(1)
    
    if input_path.suffix.lower() != '.pdf':
        print(f"Advarsel: Filen er ikke en PDF: {input_pdf}")
        confirm = input("Fortsæt alligevel? (j/n): ").strip().lower()
        if confirm != "j":
            sys.exit(1)
    
    if len(sys.argv) > 2:
        output_pdf = sys.argv[2]
    else:
        default_output = input_path.parent / f"{input_path.stem}_OCR.pdf"
        output_pdf = input(f"Sti til output PDF (Enter = {default_output}): ").strip()
        if not output_pdf:
            output_pdf = str(default_output)
    
    output_path = Path(output_pdf)
    if output_path.exists():
        overwrite = input(f"Advarsel: {output_path} findes allerede. Overskriv? (j/n): ").strip().lower()
        if overwrite != "j":
            print("OCR afbrudt.")
            sys.exit(1)
    
    languages = input("Sprog (Enter for 'dan+eng', eller angiv fx 'eng'): ").strip()
    if not languages:
        languages = "dan+eng"
    
    print(f"\nOCR behandler: {input_path.name}")
    print(f"Output gemmes som: {output_path.name}")
    print(f"Sprog: {languages}")
    print("Dette kan tage et par minutter afhaengigt af dokumentets stoerrelse...")
    print("")
    
    cmd = [
        "python", "-m", "ocrmypdf",
        "--language", languages,
        "--rotate-pages",
        "--deskew",
        "--optimize", "2",
        "--jobs", "4",
        "--skip-text",
        str(input_path),
        str(output_path)
    ]
    
    try:
        result = subprocess.run(cmd, capture_output=True, text=True)
        
        if result.returncode == 0:
            print(f"\nOCR faerdig! PDF gemt: {output_path}")
            size_mb = output_path.stat().st_size / 1024 / 1024
            print(f"Filstoerrelse: {size_mb:.2f} MB")
        else:
            print(f"\nOCR fejlede med exit code {result.returncode}")
            if result.stderr:
                print("Fejlbesked:")
                print(result.stderr)
            sys.exit(1)
            
    except FileNotFoundError:
        print("\nOCRmyPDF er ikke installeret.")
        print("   Koer: pip install ocrmypdf")
        print("   Eller koer install.ps1 igen")
        sys.exit(1)
    except Exception as e:
        print(f"\nUventet fejl: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()