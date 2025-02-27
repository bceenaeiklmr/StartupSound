# StartupSound

A free solution to use a custom boot sound for Windows 11.

## About
I have fond memories from childhood - coming home from school, booting up the family PC, and hearing Brian Eno's magical startup sound. Unfortunately, Windows 11 removed the ability to customize the startup sound easily. This script brings back that nostalgic experience by allowing you to set a custom startup sound on Windows 11.

This project does not include the Windows 95 startup sound, but you can view the original sound here:

[The Microsoft Sound (Windows 95)](https://en.wikipedia.org/wiki/File:The_Microsoft_Sound_(Windows_95).wav)

## Features
- Play a custom WAV file on startup.
- Uses Windows Task Scheduler to run seamlessly in the background.
- Simple installation and configuration.
- No third-party software required—just AutoHotkey.

## Installation
### Requirements
- Windows 11
- AutoHotkey v2.0+
- A WAV file of your desired startup sound 

### Setup
1. Download the script from [GitHub](https://github.com/bceenaeiklmr/StartupSound).
2. Place your desired WAV file in the same directory as the script.
3. Edit `StartupSound.ahk` and change `file_name := "your_choosen_file.wav"` to your WAV file's name.
4. Run `StartupSound.ahk` (it will prompt for admin access).
5. Restart to test!

## How It Works
- The script uses AutoHotkey to create a scheduled task that plays your chosen WAV file when you log in.
- A small PowerShell script is run silently via VBScript to play the sound without opening a visible terminal window.
- The default Windows startup sound is disabled to avoid conflicts.

## Troubleshooting
- If the sound doesn’t play, ensure your WAV file is valid and accessible.
- Check Task Scheduler (`taskschd.msc`) to see if the task exists and is enabled.

## License
This project is licensed under the [MIT License](LICENSE).

## Credits
Created by **Bence Markiel** ([@bceenaeiklmr](https://github.com/bceenaeiklmr)).
