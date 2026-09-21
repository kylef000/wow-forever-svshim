@echo off
rem Keeps !!SVShim's copy of your settings up to date. Leave this window open while you play.
title SVShim
where pwsh >nul 2>nul && (set "PS=pwsh") || (set "PS=powershell")
%PS% -NoProfile -ExecutionPolicy Bypass -File "%~dp0tools\sync.ps1" -Watch %*
pause
