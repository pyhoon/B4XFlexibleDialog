B4i=true
Group=Code
ModulesStructureVersion=1
Type=Class
Version=8.8
@EndOfDesignText@

' B4i UI renderer stub.
'
' B4i support is not implemented yet. This module exists so the library ships a
' B4i type with the same public surface as B4XFlexibleDialog/B4A/PrefsRenderer.bas,
' which keeps shared call sites (for example the B4XPages demo's B4XMainPage)
' compiling against the library on every platform, and gives a real renderer a
' drop-in home:
'   Initialize(Target, EventName, Definition, ValueController, L10n)
'   RegisterCustomRenderer(Name, Target, EventName)
'   Render(Parent As B4XView)
'   SetDirectoryValue(Uri)
'   Save As Boolean
'   Cancel
'   Dispose
'
' Every method is a no-op that logs a warning. Save returns True so hosts that
' gate persistence on it still behave predictably.
'
' NOTE: B4i compilation requires a Mac builder and has not been verified locally.

Sub Class_Globals
	Private NotImplementedMessage As String = "B4XFlexibleDialog: B4i renderer is not implemented yet"
End Sub

Public Sub Initialize(Target As Object, EventName As String, Definition As PrefsModel, ValueController As PrefsController, L10n As PrefsLocalization)
	Log(NotImplementedMessage)
End Sub

Public Sub RegisterCustomRenderer(Name As String, Target As Object, EventName As String)
	Log(NotImplementedMessage & " (RegisterCustomRenderer " & Name & ")")
End Sub

Public Sub Render(Parent As B4XView)
	Log(NotImplementedMessage & " (Render)")
End Sub

Public Sub SetDirectoryValue(Uri As String)
	Log(NotImplementedMessage & " (SetDirectoryValue)")
End Sub

Public Sub Save As Boolean
	Log(NotImplementedMessage & " (Save)")
	Return True
End Sub

Public Sub Cancel
	Log(NotImplementedMessage & " (Cancel)")
End Sub

Public Sub Dispose
	Log(NotImplementedMessage & " (Dispose)")
End Sub
