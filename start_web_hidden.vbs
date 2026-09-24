' start_web_hidden.vbs - launch start_web.bat with a hidden window
' Called by start_web.bat (bootstrap); can also be double-clicked manually.
Set ws = CreateObject("WScript.Shell")
Set fso = CreateObject("Scripting.FileSystemObject")
dir = fso.GetParentFolderName(WScript.ScriptFullName)
bat = dir & "\start_web.bat"
' intWindowStyle=0 (hidden) needs explicit "cmd /c" to take effect for batch files
ws.Run "cmd /c """ & bat & """ --hidden", 0, False
