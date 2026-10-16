B4i=true
Group=Code
ModulesStructureVersion=1
Type=Class
Version=8.8
@EndOfDesignText@

' B4i directory picker stub.
'
' B4i support is not implemented yet. This module mirrors the B4A picker's public
' surface so shared code compiles and a real implementation can replace this file:
'   Initialize(Target, EventName)
'   SelectDir(Copy As Boolean)
'
' Neither method selects anything today; SelectDir only logs a warning, so a host
' that requests the picker simply never receives a DirectoryPicked event.
'
' NOTE: B4i compilation requires a Mac builder and has not been verified locally.

Sub Class_Globals
	Private NotImplementedMessage As String = "B4XFlexibleDialog: B4i directory picker is not implemented yet"
End Sub

Public Sub Initialize(Target As Object, EventName As String)
	Log(NotImplementedMessage)
End Sub

Public Sub SelectDir(Copy As Boolean)
	Log(NotImplementedMessage & " (SelectDir)")
End Sub
