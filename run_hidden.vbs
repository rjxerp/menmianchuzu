' run_hidden.vbs - run a command with a hidden window (silent service start)
' usage: wscript //nologo run_hidden.vbs <program> [args...]
Set ws = CreateObject("WScript.Shell")
Set fso = CreateObject("Scripting.FileSystemObject")
' work dir = folder of this script (same as start_web.bat)
ws.CurrentDirectory = fso.GetParentFolderName(WScript.ScriptFullName)
If WScript.Arguments.Count < 1 Then WScript.Quit 1
cmdline = """" & WScript.Arguments(0) & """"
For i = 1 To WScript.Arguments.Count - 1
  cmdline = cmdline & " " & WScript.Arguments(i)
Next
' intWindowStyle=0 (hidden), bWaitOnReturn=False
ws.Run cmdline, 0, False
