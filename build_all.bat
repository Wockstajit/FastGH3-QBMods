@echo off
pushd "%~dp0"
set SKIP_TEST_JORSPY=1

for %%Q in (*.q) do node ..\QBC\QBC.js c "%%Q" -g gh3

:: stuff i need to test, or need personally in general
for %%A in (
	whammy_120FPS
	eval
	gh5_touch_glow
) do copy "%%A.qb.xen" "..\..\..\DATA\MODS\%%A.qb.xen" /y >nul
:: prepackage for the repo just because
for %%A in (
	FPS_display
	whammy_120FPS
) do copy "%%A.qb.xen" "..\..\..\DATA\MODS\disabled\%%A.qb.xen" /y >nul

jorspy\__build
if %SKIP_TEST_JORSPY% EQU 1 goto :_skip_test_jorspy
copy "jorspy.pak.xen" "..\..\DATA\MODS" /y
copy "jorspy.qb.xen" "..\..\DATA\MODS" /y
:_skip_test_jorspy

popd
