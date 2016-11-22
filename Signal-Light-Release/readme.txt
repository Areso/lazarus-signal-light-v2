﻿# Lazarus Signal Light

## About:
This program connects to Firebird's database at returns current status: maintain jobs are in progress (red) or not (green).</br>
It shows current status via TrayIcon with playing sound file.</br>
For admin role there are also ability to update this status on Firebird's database.</br>

## Installation:
### On server
Install (if not installed already Firebird 2.5 or newer)</br>
### On clients machines, for Windows
gds32.dll should be installed in Windows/System32
Edit system32\drivers\etc\services with adding following line: 
gds_db           3050/tcp
### On clients machines, for Linux

## Authors:
Anton Gladyshev, Egor Shishkin.

## License:
All code distributed under GPLv2 and GPLv3 licenses.
To obtain source, please visit https://github.com/Areso/lazarus-signal-light-v2/
Audio from some localized game. You should replace them with your own, because of not clarity licensing status of audio.
gds32.dll not a part of this program and has their own authors and restrictions on use.