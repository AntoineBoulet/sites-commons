@echo off
setlocal enabledelayedexpansion

rem ==============================================================
rem  compil-figures.bat <chemin\vers\figure.tex>
rem
rem  A lancer depuis la racine du projet. <chemin\vers\figure.tex>
rem  est un chemin relatif a la racine (ex: dossierA\test.tex).
rem
rem  Le fichier .tex ne doit contenir qu'un environnement
rem  tikzpicture (pas de preambule, pas de \documentclass).
rem
rem  Les preambules sont fixes, a la racine du projet :
rem    system\latex\tikz-light.tex
rem    system\latex\tikz-dark.tex
rem
rem  Sortie generee a cote du fichier source :
rem    <meme dossier>\<nom>-light.svg
rem    <meme dossier>\<nom>-dark.svg
rem    <meme dossier>\<nom>.pdf        (variante light)
rem ==============================================================

if "%~1"=="" (
    echo Usage: %~nx0 ^<chemin\vers\figure.tex^>
    exit /b 1
)

set "SRC=%~1"
set "SRCDIR=%~dp1"
set "SRCNAME=%~n1"

rem retire le slash final de %~dp1 pour des concatenations plus propres
if "%SRCDIR:~-1%"=="\" set "SRCDIR=%SRCDIR:~0,-1%"

rem %~dp0 = dossier du script lui-meme (la racine du projet), slash final inclus
set "ROOT=%~dp0"
set "PREAMBLE_LIGHT=%ROOT%system\latex\tikz-light.tex"
set "PREAMBLE_DARK=%ROOT%system\latex\tikz-dark.tex"

if not exist "%SRC%" (
    echo Erreur: %SRC% introuvable.
    exit /b 1
)

if not exist "%PREAMBLE_LIGHT%" (
    echo Erreur: %PREAMBLE_LIGHT% introuvable.
    exit /b 1
)

if not exist "%PREAMBLE_DARK%" (
    echo Erreur: %PREAMBLE_DARK% introuvable.
    exit /b 1
)

for %%M in (light dark) do (
    echo.
    echo === Variante %%M : %SRC% ===

    rem --- assemblage : preambule + début de document + figure + fin de document ---
    if /i "%%M"=="light" (set "PREAMBLE=%PREAMBLE_LIGHT%") else (set "PREAMBLE=%PREAMBLE_DARK%")
    copy /b /y "!PREAMBLE!" "%SRCDIR%\_tmp-%SRCNAME%-%%M.tex" >nul
    echo \begin{document}>> "%SRCDIR%\_tmp-%SRCNAME%-%%M.tex"
    type "%SRC%">> "%SRCDIR%\_tmp-%SRCNAME%-%%M.tex"
    echo \end{document}>> "%SRCDIR%\_tmp-%SRCNAME%-%%M.tex"

    echo Compilation %%M de %SRC%...
    lualatex -interaction=nonstopmode -output-directory="%SRCDIR%" "%SRCDIR%\_tmp-%SRCNAME%-%%M.tex"
    if errorlevel 1 (
        echo Erreur de compilation pour la variante %%M.
        exit /b 1
    )

    echo Conversion en SVG : %SRCNAME%-%%M.svg...
    pdftocairo -svg "%SRCDIR%\_tmp-%SRCNAME%-%%M.pdf" "%SRCDIR%\%SRCNAME%-%%M.svg"

    if /i "%%M"=="light" (
        echo Copie du PDF : %SRCNAME%.pdf...
        copy /y "%SRCDIR%\_tmp-%SRCNAME%-light.pdf" "%SRCDIR%\%SRCNAME%.pdf" >nul
    )
)

echo.
echo Nettoyage des fichiers temporaires...
del /q "%SRCDIR%\_tmp-%SRCNAME%-light.*" 2>nul
del /q "%SRCDIR%\_tmp-%SRCNAME%-dark.*" 2>nul

echo.
echo Termine : %SRCDIR%\%SRCNAME%-light.svg, %SRCDIR%\%SRCNAME%-dark.svg et %SRCDIR%\%SRCNAME%.pdf
endlocal