B4A=true
Group=Classes
ModulesStructureVersion=1
Type=Class
Version=14.2
@EndOfDesignText@
' Minimal Storage Access Framework directory picker for B4A.
' Opens the system folder picker, takes a persistable URI permission, and saves the tree URI string
' to File.DirInternal for reuse across restarts.
' Raises <prefix>_DirectoryPicked(Uri As String) or <prefix>_DirectoryCancelled.
' Uses only Intent, JavaObject and File; no DocumentFile dependency.

' B4i support is not implemented yet. This module mirrors the B4A picker's public
' surface so shared code compiles and a real implementation can replace this file:
'   Initialize(Target, EventName)
'   SelectDir(bCopy As Boolean)
'
' Neither method selects anything today; SelectDir only logs a warning, so a host
' that requests the picker simply never receives a DirectoryPicked event.
'
' NOTE: B4i compilation requires a Mac builder and has not been verified locally.
Sub Class_Globals
	#If B4i
	Private NotImplementedMessage As String = "B4XFlexibleDialog: B4i directory picker is not implemented yet"
	#Else
	Private Callback As Object
	Private EventPrefix As String	
	Private ctxt As JavaObject
	Private ion As Object
	Public PreviousUriFileName As String = "PrefsDirUri"
	#End If
End Sub

Public Sub Initialize(Target As Object, EventName As String)
	#If B4i
	Log(NotImplementedMessage)
	#Else
	Callback = Target
	EventPrefix = EventName
	ctxt.InitializeContext
	#End If
End Sub

' Opens the system folder picker. When UsePrevious is True and a persisted
' grant still exists, the saved URI is returned without showing any UI.
Public Sub SelectDir(UsePrevious As Boolean)
	#If B4i
	Log(NotImplementedMessage & " (SelectDir)")
	#Else
	If UsePrevious Then
		Dim Saved As String = ReadSavedUri
		If Saved <> "" And HasPersistedPermission(Saved) Then
			RaisePicked(Saved)
			Return
		End If
	End If
	Dim i As Intent
	i.Initialize("android.intent.action.OPEN_DOCUMENT_TREE", "")
	i.PutExtra("android.content.extra.SHOW_ADVANCED", True)
	StartActivityForResult(i)
	#End If
End Sub

#If B4A
Private Sub ion_Event(MethodName As String, Args() As Object) As Object
	If -1 = Args(0) Then
		Dim i As Intent = Args(1)
		Dim jo As JavaObject = i
		Dim treeUri As Object = jo.RunMethod("getData", Null)
		Dim takeFlags As Int = Bit.And(i.Flags, 3)
		ctxt.RunMethodJO("getContentResolver", Null).RunMethod("takePersistableUriPermission", Array(treeUri, takeFlags))
		Dim temp As Object = treeUri
		Dim Uri As String = temp
		File.WriteString(File.DirInternal, PreviousUriFileName, Uri)
		RaisePicked(Uri)
	Else
		CallSubDelayed(Callback, EventPrefix & "_DirectoryCancelled")
	End If
	Return Null
End Sub

Private Sub ReadSavedUri As String
	If File.Exists(File.DirInternal, PreviousUriFileName) = False Then Return ""
	Return File.ReadString(File.DirInternal, PreviousUriFileName)
End Sub

Private Sub HasPersistedPermission(Uri As String) As Boolean
	Dim list As List = ctxt.RunMethodJO("getContentResolver", Null).RunMethod("getPersistedUriPermissions", Null)
	If list.IsInitialized = False Then Return False
	For Each uripermission As JavaObject In list
		Dim u As Object = uripermission.RunMethod("getUri", Null)
		Dim s As String = u
		If s = Uri And uripermission.RunMethod("isWritePermission", Null) = True Then Return True
	Next
	Return False
End Sub

Private Sub RaisePicked(Uri As String)
	CallSubDelayed2(Callback, EventPrefix & "_DirectoryPicked", Uri)
End Sub

Private Sub StartActivityForResult(i As Intent)
	Dim jo As JavaObject = GetBA
	ion = jo.CreateEvent("anywheresoftware.b4a.IOnActivityResult", "ion", Null)
	jo.RunMethod("startActivityForResult", Array As Object(ion, i))
End Sub

Private Sub GetBA As Object
	Dim jo As JavaObject = Me
	Return jo.RunMethod("getBA", Null)
End Sub
#End If