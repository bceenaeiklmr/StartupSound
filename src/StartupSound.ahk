; Script     StartupSound.ahk
; License:   MIT License
; Author:    Bence Markiel (bceenaeiklmr)
; Github:    https://github.com/bceenaeiklmr/StartupSound
; Date       27.02.2025
; Version    0.2

#Requires AutoHotkey v2.0
#Warn

file_name := "your_choosen_file.wav"
StartupSound(file_name)


class StartupSound extends TaskScheduler {

    ; Create the necessary files for the scheduled task
    create_files() {

        ; VBS script to run the PowerShell
        vbs := "
        (
        ' Create an object for executing the shell
        Set objShell = CreateObject("WScript.Shell")

        ' PowerShell script to play the sound
        ps_code = "play_sound.ps1"

        ' Run the embedded PS script
        objShell.Run "powershell.exe -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File " & ps_code, 0, False

        ' Release the object
        Set objShell = Nothing
        )"

        ; PowerShell script to play the sound
        ps1 := "powershell.exe -c (New-Object Media.SoundPlayer `"%audio_file%`").PlaySync();"

        ; Replace the placeholders with the actual values
        path_play_sound := StrReplace(A_ScriptDir "\play_sound.ps1", "\", "\\")
        ps1 := StrReplace(ps1, "%audio_file%", this.audio_file)
        vbs := StrReplace(vbs, "play_sound.ps1", path_play_sound)
        
        ; Create the files
        if FileExist(path_play_sound)
            FileDelete(path_play_sound)
        if FileExist(this.task.file)
            FileDelete(this.task.file)
        FileAppend(ps1, path_play_sound)
        FileAppend(vbs, this.task.file)
        return
    }

    ; Enable/disable the default Windows startup sound
    set_default_startup_sound(value := 1) {
        reg := { key : "HKEY_CURRENT_USER\AppEvents\EventLabels\WindowsLogon\"
            , value : "ExcludeFromCPL"
            , type : "REG_DWORD" }
        current_value := RegRead(reg.key, reg.value, reg.type)
        if (current_value != value) {
            try RegWrite(value, reg.type, reg.key, reg.value)
            catch OSError {
                throw OSError
            }
        }
    }

    __New(wav_file) {

        ; Verify Windows version
        if !(A_OSVersion ~= "^10\.0\.") {
            MsgBox("This script is only for Windows 10/11." .
                   "The program will exit.", A_ScriptName, 0x10)
            ExitApp()
        }

        ; Verify the audio file exists
        if !(FileExist(this.audio_file := wav_file)) {
            MsgBox("The specified audio file does not exist." .
                   "The program will exit.", A_ScriptName, 0x10)
            ExitApp()
        }
        ; Add the script directory to the audio file path
        if !(InStr(this.audio_file, A_ScriptDir)) {
            this.audio_file := A_ScriptDir "\" this.audio_file
        }

        ; Adding or removing a task requires admin privileges
        RunAsAdmin()

        ; Disable the default startup sound
        this.set_default_startup_sound(0)

        ; Task settings
        this.task := task := {
            name : StrReplace(A_ScriptName, ".ahk"),
            file : A_ScriptDir "\run_silent.vbs",
            settings : A_ScriptDir '\settings.xml'
        }

        ; Create the files for the task
        this.create_files()

        ; Remove the task if it already exists
        this.delete_task(task.name)
        
        ; Create the task by XML
        FileAppend(this.settings_to_xml(), task.settings, "UTF-16")
        this.create_task_from_xml(task.name, task.settings)
        FileDelete(task.settings)

        ; Check if the task was created successfully
        if (this.task_status(task.name) == "Ready") {
            MsgBox("Task created successfully. Relog to your account.",, "T1")
        } else {
            MsgBox("Task creation failed.",, "T1")
        }

        ; Display the log file content if debug mode is enabled
        if (%this.base.__Class%.debug) {
            log_path := %this.base.__Class%.log_path
            schtasks_log := FileRead(log_path)
            FileDelete(log_path)
            MsgBox(schtasks_log)
        }
        return     
    }

    ; Convert the task settings to XML format
    settings_to_xml() {

        ; Get the task settings
        task := this.task
        
        ; Add quotes to the file path
        task.file := '"' task.file '"'
        
        ; The user ID under which the task runs
        task.UserId := "NT AUTHORITY\SYSTEM"

        ; The task can be started on demand
        task.AllowStartOnDemand := true
        
        ; The task will not start if the computer is running on battery power
        task.DisallowStartIfOnBatteries := false
        
        ; The task will stop if the computer switches to battery power
        task.StopIfGoingOnBatteries := true
        
        ; The task will start as soon as possible after the trigger is activated
        task.StartWhenAvailable := false
        
        ; The task is enabled
        task.Enabled := true
        
        ; The task is hidden from the Task Scheduler UI
        task.Hidden := false
        
        ; The priority of the task (0-10), 2 highest, 2-3 above normal, 4-6 normal, 7-8 below normal, 9-10 lowest
        task.priority := 4

        str := "
        (
        <?xml version="1.0" encoding="UTF-16"?>
        <Task version="1.2" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task">
        <RegistrationInfo>
            <Date>2025-02-26T14:38:56.4645525</Date>
            <Author>bceenaeiklmr</Author>
            <Description>Execute a custom login sound script on login.</Description>
            <URI></URI>
        </RegistrationInfo>
        <Triggers>
            <LogonTrigger>
            <Enabled>true</Enabled>
            </LogonTrigger>
        </Triggers>
        <Principals>
            <Principal id="Author">
            <UserId>%UserId%</UserId>
            <LogonType>InteractiveToken</LogonType>
            <RunLevel>LeastPrivilege</RunLevel>
            </Principal>
        </Principals>
        <Settings>
            <MultipleInstancesPolicy>IgnoreNew</MultipleInstancesPolicy>
            <DisallowStartIfOnBatteries>%DisallowStartIfOnBatteries%</DisallowStartIfOnBatteries>
            <StopIfGoingOnBatteries>%StopIfGoingOnBatteries%</StopIfGoingOnBatteries>
            <AllowHardTerminate>true</AllowHardTerminate>
            <StartWhenAvailable>%StartWhenAvailable%</StartWhenAvailable>
            <RunOnlyIfNetworkAvailable>false</RunOnlyIfNetworkAvailable>
            <IdleSettings>
            <StopOnIdleEnd>true</StopOnIdleEnd>
            <RestartOnIdle>false</RestartOnIdle>
            </IdleSettings>
            <AllowStartOnDemand>%AllowStartOnDemand%</AllowStartOnDemand>
            <Enabled>%Enabled%</Enabled>
            <Hidden>%Hidden%</Hidden>
            <RunOnlyIfIdle>false</RunOnlyIfIdle>
            <WakeToRun>false</WakeToRun>
            <ExecutionTimeLimit>PT2S</ExecutionTimeLimit>
            <Priority>%priority%</Priority>
        </Settings>
        <Actions Context="Author">
            <Exec>
            <Command>wscript.exe</Command>
            <Arguments>%file%</Arguments>
            </Exec>
        </Actions>
        </Task>
        )"

        ; Replace the placeholders with the settings
        for k in task.OwnProps() {
            str := StrReplace(str, "%" k "%", task.%k%)
        }

        return str
    }
}

class TaskScheduler {

    static debug := False
    static log_path := A_ScriptDir "\schtasks_log.txt"

    ; Get the status of a task by name
    task_status(task_name := "") {

        ; Set task name parameter
        if (task_name) {
            task_name := " /tn `"" task_name "`""
        }

        ; Capture the output of the schtasks command
        result := ExecShellCmd("schtasks /query" task_name)
        
        if (task_name == "") {
            return result
        }
        return InStr(result, "Disabled") ? "Disabled" 
             : InStr(result, "Running") ? "Running"
             : InStr(result, "Ready") ? "Ready"
             : "Not found"
    }

    ; Create a task from an XML file
    create_task_from_xml(task_name, path) {
        cmd := ' /c schtasks /create /tn "' task_name '" /xml "' path '" /f'
        if (%this.__Class%.debug) {
            cmd .= ' > ' %this.__Class%.log_path ' 2>&1'
        }
        RunWait(A_ComSpec cmd, , 'Hide')
        return
    }

    ; Delete a task by name
    delete_task(task_name) {
        return ExecShellCmd("schtasks /delete /tn " task_name " /f")
    }
}


; Execute a shell command and return the output
ExecShellCmd(cmd) {
    return ComObject("WScript.Shell").Exec(A_ComSpec " /C " cmd)
        .StdOut.ReadAll()
}

; Restart the script with admin privileges if not already running as admin
RunAsAdmin() {
    
    ; Get the command line arguments
    params := ""
    for arg in A_Args {
        params .= " " arg
    }

    ; Get the full command line of this script
    cmd := DllCall("GetCommandLine", "str")

    ; Restart the script with admin privileges
    if (!A_IsAdmin || !RegExMatch(cmd, " /restart")) {
        
        ; Path and parameters are different for compiled scripts
        if (A_IsCompiled) {
            path := A_ScriptFullPath
        } else {
            path := '"' A_AhkPath '"'
            params := '"' A_ScriptFullPath '"' params
        }
        ; Add the restart parameter to avoid an infinite loop
        params := '/restart ' params

        ; Execute the script as admin
        DllCall("shell32\ShellExecute", "UInt", 0, "str", "RunAs", "str", path, "str", params, "str", A_WorkingDir, "int", 1)
        ExitApp()
    }
}
