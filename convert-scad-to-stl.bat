@echo off
setlocal enabledelayedexpansion

echo ========================================
echo OpenSCAD to STL and PNG Batch Converter
echo High Quality Settings
echo ========================================
echo.

REM Check if OpenSCAD is in PATH or use common installation paths
set "OPENSCAD_PATH=openscad"

REM Try to find OpenSCAD
where openscad >nul 2>&1
if errorlevel 1 (
    if exist "C:\Program Files\OpenSCAD\openscad.exe" (
        set "OPENSCAD_PATH=C:\Program Files\OpenSCAD\openscad.exe"
    ) else if exist "C:\Program Files (x86)\OpenSCAD\openscad.exe" (
        set "OPENSCAD_PATH=C:\Program Files (x86)\OpenSCAD\openscad.exe"
    ) else (
        echo ERROR: OpenSCAD not found!
        echo Please install OpenSCAD or add it to your PATH.
        pause
        exit /b 1
    )
)

echo Using OpenSCAD: !OPENSCAD_PATH!
echo.
echo Processing all .scad files...
echo.

REM Counter for processed files
set /a count=0

REM Process all .scad files recursively in current directory and subdirectories
for /r %%f in (*.scad) do (
    set "input=%%f"
    set "output_stl=%%~dpnf.stl"
    set "output_img1=%%~dpnf-iso.png"
    set "output_img2=%%~dpnf-back.png"

    echo [!count!] Processing: %%~nxf
    echo     Input:  !input!

    REM Generate STL file with highest quality settings
    echo     Generating STL...
    "!OPENSCAD_PATH!" -o "!output_stl!" --render -D "$fn=100" -D "$fa=1" -D "$fs=0.1" "!input!"

    if errorlevel 1 (
        echo     [FAILED] Error generating STL for %%~nxf
    ) else (
        echo     [SUCCESS] STL: !output_stl!

        REM Generate isometric view PNG (default view)
        echo     Generating isometric view...
        "!OPENSCAD_PATH!" -o "!output_img1!" --render --autocenter --viewall --imgsize=1920,1080 --colorscheme=Nature -D "$fn=100" -D "$fa=1" -D "$fs=0.1" "!input!"

        if errorlevel 1 (
            echo     [FAILED] Error generating isometric view
        ) else (
            echo     [SUCCESS] Image: !output_img1!
        )

        REM Generate back view PNG (rotated 180 degrees)
        echo     Generating back view...
        "!OPENSCAD_PATH!" -o "!output_img2!" --render --autocenter --viewall --imgsize=1920,1080 --colorscheme=Nature --camera=0,0,0,55,0,205,350 -D "$fn=100" -D "$fa=1" -D "$fs=0.1" "!input!"

        if errorlevel 1 (
            echo     [FAILED] Error generating back view
        ) else (
            echo     [SUCCESS] Image: !output_img2!
        )

        set /a count+=1
    )
    echo.
)

echo ========================================
echo Conversion Complete!
echo Successfully processed !count! file(s)
echo Generated: STL + 2 PNG images per file
echo ========================================
pause
