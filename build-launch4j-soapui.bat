@echo off
setlocal enabledelayedexpansion

title SoapUI Build with Launch4j + NSIS

echo ========================================
echo    SoapUI Builder - Launch4j + NSIS
echo ========================================
echo.
echo NOTE: Set your version in build-launch4j.xml (project.version property)
echo.

REM Check if Ant is available
where ant >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo Error: Ant was not found in PATH.
    echo Check if Ant is installed and add it to the system PATH.
    echo Default location: C:\Program Files\Apache Software Foundation\apache-ant-[VERSION]
    pause
    exit /b 1
)

REM Check if Launch4j exists
if not exist "C:\Program Files (x86)\Launch4j\launch4j.jar" (
    echo Error: Launch4j was not found at: C:\Program Files ^(x86^)\Launch4j
    echo Check if Launch4j is installed in the correct location.
    pause
    exit /b 1
)

REM Check if NSIS exists (optional for installer)
set NSIS_EXISTS=false
if exist "C:\Program Files (x86)\NSIS\makensis.exe" (
    set NSIS_EXISTS=true
)

REM Check if Maven is available
where mvn >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo Error: Maven was not found in PATH.
    echo Make sure Maven is installed and available in PATH.
    pause
    exit /b 1
)

echo Starting SoapUI build...
echo.

REM Ask which type of build to make with validation
if "%NSIS_EXISTS%"=="true" (
    :ask_with_nsis
    echo Choose build type:
    echo 1. Executable only ^(portable^)
    echo 2. Professional installer ^(equivalent to install4j^)
    echo 3. Portable ZIP distribution
    echo 4. Validate Windows build
    echo 5. Clean temporary files
    echo 6. Check registry for existing SoapUI installations ^(version-specific^)
    echo 7. Test installation detection debug ^(original function^)
    echo 8. Test installation scope detection logic ^(corrected version^)
    echo.
    set /p BUILD_TYPE=Enter your choice ^(1-8^): 
    
    REM Check for empty input
    if "!BUILD_TYPE!"=="" (
        echo.
        echo ❌ No option selected. Please enter a number between 1 and 8.
        echo.
        goto ask_with_nsis
    )
    
    REM Validate input
    if "!BUILD_TYPE!"=="1" (
        echo.
        echo Creating portable executable...
        ant -f build-launch4j.xml create-exe
    ) else if "!BUILD_TYPE!"=="2" (
        echo.
        echo Creating professional installer with NSIS...
        ant -f build-launch4j.xml create-installer
    ) else if "!BUILD_TYPE!"=="3" (
        echo.
        echo Creating portable ZIP distribution...
        ant -f build-launch4j.xml create-distribution
    ) else if "!BUILD_TYPE!"=="4" (
        echo.
        echo Validating Windows optimized build...
        ant -f build-launch4j.xml validate-windows-build
    ) else if "!BUILD_TYPE!"=="5" (
        echo.
        echo Cleaning temporary files...
        ant -f build-launch4j.xml clean
    ) else if "!BUILD_TYPE!"=="6" (
        echo.
        echo Checking registry for existing SoapUI installations...
        ant -f build-launch4j.xml check-registry
    ) else if "!BUILD_TYPE!"=="7" (
        echo.
        echo Running installation detection debug...
        ant -f build-launch4j.xml test-detection
    ) else if "!BUILD_TYPE!"=="8" (
        echo.
        echo Testing corrected installation scope detection logic...
        ant -f build-launch4j.xml test-detection-logic
    ) else (
        echo.
        echo ❌ Invalid choice: "!BUILD_TYPE!"
        echo Please enter a number between 1 and 8.
        echo.
        goto ask_with_nsis
    )
) else (
    :ask_without_nsis
    echo NSIS not found - limited options available:
    echo 1. Executable only ^(portable^)
    echo 3. Portable ZIP distribution  
    echo 4. Validate Windows build
    echo 5. Clean temporary files
    echo 6. Check registry for existing SoapUI installations ^(version-specific^)
    echo 7. Test installation detection debug ^(original function^)
    echo 8. Test installation scope detection logic ^(corrected version^)
    echo.
    echo To create professional installers, install NSIS from: https://nsis.sourceforge.io/
    echo.
    set /p BUILD_TYPE=Enter your choice ^(1,3,4,5,6,7,8^): 
    
    REM Check for empty input
    if "!BUILD_TYPE!"=="" (
        echo.
        echo ❌ No option selected. Please enter a valid option: 1, 3, 4, 5, 6, 7, or 8.
        echo.
        goto ask_without_nsis
    )
    
    REM Validate input (only valid options without NSIS)
    if "!BUILD_TYPE!"=="1" (
        echo.
        echo Creating portable executable...
        ant -f build-launch4j.xml create-exe
    ) else if "!BUILD_TYPE!"=="3" (
        echo.
        echo Creating portable ZIP distribution...
        ant -f build-launch4j.xml create-distribution
    ) else if "!BUILD_TYPE!"=="4" (
        echo.
        echo Validating Windows optimized build...
        ant -f build-launch4j.xml validate-windows-build
    ) else if "!BUILD_TYPE!"=="5" (
        echo.
        echo Cleaning temporary files...
        ant -f build-launch4j.xml clean
    ) else if "!BUILD_TYPE!"=="6" (
        echo.
        echo Checking registry for existing SoapUI installations...
        ant -f build-launch4j.xml check-registry
    ) else if "!BUILD_TYPE!"=="7" (
        echo.
        echo Running installation detection debug...
        ant -f build-launch4j.xml test-detection
    ) else if "!BUILD_TYPE!"=="8" (
        echo.
        echo Testing corrected installation scope detection logic...
        ant -f build-launch4j.xml test-detection-logic
    ) else (
        echo.
        echo ❌ Invalid choice: "!BUILD_TYPE!"
        if "!BUILD_TYPE!"=="2" (
            echo Option 2 requires NSIS to be installed.
            echo Install NSIS from: https://nsis.sourceforge.io/
        ) else (
            echo Please enter a valid option: 1, 3, 4, 5, 6, 7, or 8.
        )
        echo.
        goto ask_without_nsis
    )
)

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ================================
    echo    BUILD COMPLETED SUCCESSFULLY!
    echo ================================
    echo.
    echo The executable was created at: soapui-installer\target\launch4j\SoapUI-[VERSION]\bin\SoapUI-[VERSION].exe
    echo.
    echo To run SoapUI:
    echo 1. Navigate to folder 'soapui-installer\target\launch4j\SoapUI-[VERSION]\bin'
    echo 2. Run SoapUI-[VERSION].exe
    echo.
    echo IMPORTANT: 
    echo - Keep all folders together with the executable (lib, jre, licenses, etc.)
    echo - JRE 17 is bundled - no Java installation required
    echo - Version configured in build-launch4j.xml (project.version property)
    echo.
    
    REM Ask if user wants to see optimization statistics
    set /p show_stats=Do you want to see optimization statistics? (y/n): 
    if /i "%show_stats%"=="y" (
        echo.
        echo Displaying optimization statistics...
        ant -f build-launch4j.xml show-optimization-stats
    )
) else (
    echo.
    echo ================================
    echo    BUILD ERROR
    echo ================================
    echo.
    echo Check the errors above and try again.
    echo.
    echo Common problems:
    echo - Java JDK 17 is not available at configured path
    echo - Maven dependencies could not be downloaded
    echo - Insufficient permissions to create files
    echo - Version not configured in build-launch4j.xml (project.version property)
)

echo.
pause 