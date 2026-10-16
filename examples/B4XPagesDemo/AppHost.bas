B4A=true
Group=Code
ModulesStructureVersion=1
Type=StaticCode
Version=14.2
@EndOfDesignText@

' Neutral entry point used by the shared B4XPages page. Each platform's Main
' creates its own PrefsHost class (which owns the facade/renderer, persistence
' and the sample rating renderer) and assigns it to Target here. The page never
' references a platform module directly, which is required on B4A where a page
' class cannot access Activity-module members.

Sub Process_Globals
	Public Target As Object
End Sub

Public Sub ShowPrefsPage (Host As B4XView)
	CallSub2(Target, "ShowPrefsPage", Host)
End Sub

Public Sub ShowPrefsDialog
	CallSub(Target, "ShowPrefsDialog")
End Sub

Public Sub SavePrefs
	CallSub(Target, "SavePrefs")
End Sub

Public Sub CancelPrefs
	CallSub(Target, "CancelPrefs")
End Sub
