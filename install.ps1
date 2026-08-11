# install.ps1 - Installation af Book Digitalization Tools
# Brug: irm https://MBBP1.github.io/install.ps1 | iex

$logFile = "$env:TEMP\BookDigitalizer_install_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
Start-Transcript -Path $logFile -Append

Write-Host ""
Write-Host "=================================================="
Write-Host "    BOOK DIGITALIZATION TOOLS - INSTALLATION"
Write-Host "=================================================="
Write-Host ""

Write-Host "Dette script installerer foelgende programmer:"
Write-Host "  - Python (via Chocolatey)"
Write-Host "  - Chocolatey (Windows package manager)"
Write-Host "  - Tesseract OCR (med dansk sprogpakke)"
Write-Host "  - Ghostscript (PDF processing)"
Write-Host "  - pngquant (billedoptimering)"
Write-Host "  - Python-biblioteker: Pillow, pyautogui, opencv-python, pytesseract, ocrmypdf"
Write-Host ""

if ($args -contains "-WhatIf" -or $args -contains "-DryRun") {
    Write-Host "DRY-RUN: Ingen ændringer foretages"
    Write-Host ""
    Write-Host "Foelgende handlinger ville blive udfoert:"
    Write-Host "  - Oprette mappe: $env:USERPROFILE\Documents\BookDigitalizer"
    Write-Host "  - Installere Python (hvis mangler)"
    Write-Host "  - Installere Chocolatey (hvis mangler)"
    Write-Host "  - Installere Tesseract, Ghostscript, pngquant"
    Write-Host "  - Installere Python-pakker via pip"
    Write-Host "  - Downloade scripts fra GitHub"
    Write-Host "  - Oprette genveje på skrivebordet"
    Write-Host ""
    Stop-Transcript
    exit 0
}

$confirm = Read-Host "Fortsæt med installationen? (j/n)"
if ($confirm -ne "j" -and $confirm -ne "j") {
    Write-Host "Installation afbrudt."
    Stop-Transcript
    exit 0
}

function Test-ProgramInstalled {
    param([string]$ProgramName)
    try {
        $null = Get-Command $ProgramName -ErrorAction Stop
        return $true
    } catch {
        return $false
    }
}

function Test-PythonPackage {
    param([string]$PackageName)
    try {
        $result = python -c "import $PackageName" 2>&1
        return $true
    } catch {
        return $false
    }
}

function Update-Path {
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
}

function Install-PythonPackage {
    param([string]$PackageName)
    Write-Host "  Installerer $PackageName..."
    try {
        $result = python -m pip install $PackageName 2>&1
        if ($LASTEXITCODE -ne 0) {
            throw "pip install fejlede med exit code $LASTEXITCODE"
        }
        Write-Host "    $PackageName installeret"
        return $true
    } catch {
        Write-Host "    Fejl ved installation af $PackageName : $_"
        return $false
    }
}

$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "Advarsel: Scriptet kører ikke som Administrator!"
    Write-Host "Nogle installationer (især Chocolatey og system-pakker) kræver administrator-rettigheder."
    $continue = Read-Host "Forsæt alligevel? (j/n)"
    if ($continue -ne "j" -and $continue -ne "j") {
        Write-Host "Installation afbrudt. Kør scriptet som Administrator for bedste resultat."
        Stop-Transcript
        exit 0
    }
}

Write-Host "[1/8] Tjekker Python..."
if (-not (Test-ProgramInstalled "python")) {
    Write-Host "  Python er ikke installeret!"
    if ($isAdmin) {
        Write-Host "  Installerer Python via Chocolatey..."
        if (-not (Test-ProgramInstalled "choco")) {
            Write-Host "  Installerer Chocolatey..."
            Set-ExecutionPolicy Bypass -Scope Process -Force
            try {
                [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
                iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
                Update-Path
            } catch {
                Write-Host "  Kunne ikke installere Chocolatey: $_"
                Write-Host "  Installer Python manuelt fra: https://www.python.org/downloads/"
                Read-Host "  Tryk Enter når Python er installeret..."
            }
        }
        
        if (Test-ProgramInstalled "choco") {
            choco install python -y
            Update-Path
            refreshenv 2>$null
        }
    } else {
        Write-Host "  Installer Python manuelt fra: https://www.python.org/downloads/"
        Write-Host "  Husk at markere 'Add Python to PATH' under installationen."
        Read-Host "  Tryk Enter når Python er installeret..."
    }
} else {
    $pythonVersion = python --version
    Write-Host "  Python fundet: $pythonVersion"
}

Write-Host "[2/8] Opgraderer pip..."
try {
    python -m pip install --upgrade pip
    Write-Host "  pip opgraderet"
} catch {
    Write-Host "  Kunne ikke opgradere pip: $_"
}

Write-Host "[3/8] Installerer Python-biblioteker..."
$pythonPackages = @(
    "Pillow",
    "pyautogui",
    "opencv-python",
    "pytesseract"
)

$failedPackages = @()
foreach ($package in $pythonPackages) {
    if (Test-PythonPackage $package) {
        Write-Host "  $package allerede installeret"
    } else {
        if (-not (Install-PythonPackage $package)) {
            $failedPackages += $package
        }
    }
}

Write-Host "[4/8] Installerer OCRmyPDF..."
if (Test-PythonPackage "ocrmypdf") {
    Write-Host "  OCRmyPDF allerede installeret"
} else {
    Install-PythonPackage "ocrmypdf"
}

Write-Host "[5/8] Tjekker Chocolatey..."
if (-not (Test-ProgramInstalled "choco")) {
    Write-Host "  Installerer Chocolatey..."
    Set-ExecutionPolicy Bypass -Scope Process -Force
    try {
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
        iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
        Update-Path
        Write-Host "  Chocolatey installeret"
    } catch {
        Write-Host "  Kunne ikke installere Chocolatey: $_"
        Write-Host "  Nogle system-værktøjer vil ikke blive installeret automatisk."
    }
} else {
    Write-Host "  Chocolatey fundet"
}

Write-Host "[6/8] Installerer system-værktøjer..."

$systemTools = @(
    @{Name="tesseract"; ChocolateyPackage="tesseract"},
    @{Name="ghostscript"; ChocolateyPackage="ghostscript"},
    @{Name="pngquant"; ChocolateyPackage="pngquant"}
)

$toolErrors = @()

foreach ($tool in $systemTools) {
    if (Test-ProgramInstalled $tool.Name) {
        Write-Host "  $($tool.Name) allerede installeret"
    } else {
        if ($isAdmin -and (Test-ProgramInstalled "choco")) {
            Write-Host "  Installerer $($tool.Name) via Chocolatey..."
            try {
                choco install $tool.ChocolateyPackage -y
                Write-Host "    $($tool.Name) installeret"
            } catch {
                Write-Host "    Fejl ved installation af $($tool.Name): $_"
                $toolErrors += $tool.Name
            }
        } else {
            Write-Host "  $($tool.Name) mangler - installer manuelt:"
            if ($isAdmin) {
                Write-Host "    choco install $($tool.ChocolateyPackage) -y"
            } else {
                Write-Host "    Kør scriptet som Administrator for automatisk installation"
            }
            $toolErrors += $tool.Name
        }
    }
}

Write-Host "[7/8] Installerer dansk sprogpakke til Tesseract..."

if (Test-ProgramInstalled "tesseract") {
    $tesseractPath = (Get-Command tesseract).Source
    $tessdataDir = Join-Path (Split-Path $tesseractPath -Parent) "tessdata"
    
    $danFile = Join-Path $tessdataDir "dan.traineddata"
    if (Test-Path $danFile) {
        Write-Host "  Dansk sprogpakke allerede installeret"
    } else {
        Write-Host "  Downloader dansk sprogpakke..."
        try {
            $danUrl = "https://github.com/tesseract-ocr/tessdata/raw/main/dan.traineddata"
            Invoke-WebRequest -Uri $danUrl -OutFile $danFile
            Write-Host "  Dansk sprogpakke installeret"
        } catch {
            Write-Host "  Kunne ikke downloade dansk sprogpakke: $_"
            Write-Host "    Download manuelt fra: https://github.com/tesseract-ocr/tessdata"
        }
    }
} else {
    Write-Host "  Tesseract ikke installeret - dansk sprogpakke springes over"
}

Write-Host "[8/8] Henter scripts fra GitHub..."

$scriptDir = "$env:USERPROFILE\Documents\BookDigitalizer"
New-Item -ItemType Directory -Force -Path $scriptDir | Out-Null

# Skift disse til dine egne værdier
$githubUser = "MBBP1"
$githubRepo = "bookshare"
$rawBase = "https://raw.githubusercontent.com/$githubUser/$githubRepo/main"

$scripts = @(
    @{Name="auto_capture_pages.py"; Url="$rawBase/auto_capture_pages.py"},
    @{Name="images_to_pdf.py"; Url="$rawBase/images_to_pdf.py"},
    @{Name="ocr_pdf.py"; Url="$rawBase/ocr_pdf.py"}
)

$downloadErrors = @()
foreach ($script in $scripts) {
    $outputPath = Join-Path $scriptDir $script.Name
    Write-Host "  Downloader $($script.Name)..."
    try {
        Invoke-WebRequest -Uri $script.Url -OutFile $outputPath -ErrorAction Stop
        Write-Host "    Gemt i: $outputPath"
    } catch {
        Write-Host "    Fejl ved download af $($script.Name): $_"
        $downloadErrors += $script.Name
    }
}

Update-Path

Write-Host "Opretter genveje..."

$batchContent = @'
@echo off
chcp 65001 >nul
echo ========================================
echo Book Digitalization Tools
echo ========================================
echo.
echo Vaelg et vaerktoej:
echo 1. Auto Capture Pages (fang sider)
echo 2. Images to PDF (konverter billeder til PDF)
echo 3. OCR PDF (goer PDF soegbar)
echo 4. Alle scripts (vis alle)
echo.
set /p choice="Indtast nummer (1-4): "
if "%choice%"=="1" python "%USERPROFILE%\Documents\BookDigitalizer\auto_capture_pages.py"
if "%choice%"=="2" python "%USERPROFILE%\Documents\BookDigitalizer\images_to_pdf.py"
if "%choice%"=="3" python "%USERPROFILE%\Documents\BookDigitalizer\ocr_pdf.py"
if "%choice%"=="4" dir "%USERPROFILE%\Documents\BookDigitalizer\*.py"
pause
'@

$batchPath = "$env:USERPROFILE\Desktop\BookDigitalizer.bat"
$batchContent | Out-File -FilePath $batchPath -Encoding ASCII
Write-Host "  Genvej: BookDigitalizer.bat"

$ocrBatchContent = @'
@echo off
chcp 65001 >nul
echo OCR PDF - Goer PDF soegbar
echo.
set /p input_pdf="Sti til input PDF: "
if "%input_pdf%"=="" (
    echo Ingen fil angivet.
    pause
    exit /b
)
set /p output_pdf="Sti til output PDF (tryk Enter for auto-navn): "
if "%output_pdf%"=="" (
    set "output_pdf=%input_pdf:~0,-4%_OCR.pdf"
)
python -m ocrmypdf --language dan+eng --rotate-pages --deskew --optimize 2 --jobs 4 --skip-text "%input_pdf%" "%output_pdf%"
if errorlevel 1 (
    echo Der opstod en fejl under OCR-processen.
) else (
    echo Faerdig! PDF gemt som: %output_pdf%
)
pause
'@

$ocrBatchPath = "$env:USERPROFILE\Desktop\OCR_PDF.bat"
$ocrBatchContent | Out-File -FilePath $ocrBatchPath -Encoding ASCII
Write-Host "  Genvej: OCR_PDF.bat"

$readmeContent = @'
Book Digitalization Tools
=========================

Installerede vaerktoejer:

1. Auto Capture Pages
   Fanger sider fra PDF/browser ved at tage screenshots
   Brug: koer auto_capture_pages.py

2. Images to PDF
   Konverterer billeder til én PDF-fil
   Brug: koer images_to_pdf.py

3. OCR PDF
   Goer PDF soegbar og kopierbar (som Adobe Acrobat Pro)
   Brug: koer ocr_pdf.py eller brug OCR_PDF.bat på skrivebordet

Genveje på skrivebordet:
- BookDigitalizer.bat - Menu med alle vaerktoejer
- OCR_PDF.bat - Direkte OCR af PDF

Afhaengigheder installeret:
- Python 3.x
- Pillow (billedbehandling)
- pyautogui (skaermoptagelse)
- OCRmyPDF (OCR)
- Tesseract (OCR motor)
- Ghostscript (PDF processing)
- pngquant (optimering)

Fejlfinding:
Hvis noget ikke virker, proev at koere install.ps1 igen som Administrator.

Log-filer:
Installationslog gemmes i: %TEMP%\BookDigitalizer_install_*.log
'@

$readmePath = "$scriptDir\README.txt"
$readmeContent | Out-File -FilePath $readmePath -Encoding UTF8

Write-Host ""
Write-Host "=================================================="
Write-Host "              INSTALLATION FAERDIG"
Write-Host "=================================================="
Write-Host ""

Write-Host "Scripts installeret i: $scriptDir"
Write-Host "Genveje oprettet på skrivebordet:"
Write-Host "   - BookDigitalizer.bat (menu)"
Write-Host "   - OCR_PDF.bat (direkte OCR)"
Write-Host ""

if ($failedPackages.Count -gt 0) {
    Write-Host "Foelgende Python-pakker fejlede: $($failedPackages -join ', ')"
    Write-Host "   Proev at installere manuelt: pip install $($failedPackages -join ' ')"
}

if ($toolErrors.Count -gt 0) {
    Write-Host "Foelgende system-vaerktoejer fejlede: $($toolErrors -join ', ')"
    Write-Host "   Koer scriptet som Administrator eller installer manuelt."
}

if ($downloadErrors.Count -gt 0) {
    Write-Host "Foelgende scripts fejlede download: $($downloadErrors -join ', ')"
    Write-Host "   Tjek at GitHub repoet er korrekt og offentligt tilgaengeligt."
}

Write-Host ""
Write-Host "Installationslog gemt i: $logFile"
Write-Host ""

Stop-Transcript

Read-Host "Tryk Enter for at afslutte"
