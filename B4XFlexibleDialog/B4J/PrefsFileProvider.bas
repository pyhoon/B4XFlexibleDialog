B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=10.7
@EndOfDesignText@
' File/directory selection abstraction.
' Default behavior uses the B4J JavaFX FileChooser / DirectoryChooser.
' An application may supply its own picker via SetCustomHandler; the custom subs receive
' the Options map and must return a PrefsFileResult: Sub MyPicker_File(Options As Map) As PrefsFileResult
Sub Class_Globals
	Private fx As JFX
	Private OwnerForm As Form
	Private HandlerTarget As Object
	Private FileHandlerEvent As String
	Private DirectoryHandlerEvent As String
	Private HasFileHandler As Boolean
	Private HasDirectoryHandler As Boolean
	Public LastError As String
End Sub

Public Sub Initialize(Owner As Form)
	OwnerForm = Owner
	HandlerTarget = Null
	FileHandlerEvent = ""
	DirectoryHandlerEvent = ""
	HasFileHandler = False
	HasDirectoryHandler = False
	LastError = ""
End Sub

Public Sub SetCustomHandler(Target As Object, FileSub As String, DirectorySub As String)
	HandlerTarget = Target
	FileHandlerEvent = FileSub
	DirectoryHandlerEvent = DirectorySub
	HasFileHandler = (FileSub <> "")
	HasDirectoryHandler = (DirectorySub <> "")
End Sub

Public Sub SelectFile(Options As Map) As PrefsFileResult
	If HasFileHandler Then
		Dim Custom As Object = CallSub2(HandlerTarget, FileHandlerEvent, Options)
		If Custom Is PrefsFileResult Then Return Custom
		Dim Invalid As PrefsFileResult
		Invalid.Initialize
		Invalid.SetFailed("Custom file handler did not return a PrefsFileResult.")
		Return Invalid
	End If
	Return BuiltInSelectFile(Options)
End Sub

Public Sub SelectDirectory(Options As Map) As PrefsFileResult
	If HasDirectoryHandler Then
		Dim Custom As Object = CallSub2(HandlerTarget, DirectoryHandlerEvent, Options)
		If Custom Is PrefsFileResult Then Return Custom
		Dim Invalid As PrefsFileResult
		Invalid.Initialize
		Invalid.SetFailed("Custom directory handler did not return a PrefsFileResult.")
		Return Invalid
	End If
	Return BuiltInSelectDirectory(Options)
End Sub

Private Sub BuiltInSelectFile(Options As Map) As PrefsFileResult
	Dim Result As PrefsFileResult
	Result.Initialize
	Dim Chooser As FileChooser
	Chooser.Initialize
	If Options.ContainsKey("title") Then Chooser.Title = Options.Get("title")
	If Options.ContainsKey("initialDirectory") Then
		Dim Initial As String = Options.Get("initialDirectory")
		If Initial <> "" Then Chooser.InitialDirectory = Initial
	End If
	If Options.ContainsKey("extensions") And IsListObject(Options.Get("extensions")) Then
		Dim Extensions As List = Options.Get("extensions")
		Dim Patterns As List
		Patterns.Initialize
		For Each ExtensionObject As Object In Extensions
			Patterns.Add("*." & ExtensionObject)
		Next
		If Patterns.Size > 0 Then Chooser.SetExtensionFilter("Allowed files", Patterns)
	End If
	Dim Selected As String = Chooser.ShowOpen(OwnerForm)
	If Selected = "" Or Selected = Null Then
		Result.SetCancelled
		Return Result
	End If
	Dim SelectedName As String = File.GetName(Selected)
	Dim SelectedParent As String = ParentOf(Selected)
	Result.SetSelected(Selected, File.GetUri(SelectedParent, SelectedName), SelectedName, MimeFromExtension(Selected), "path")
	Return Result
End Sub

Private Sub BuiltInSelectDirectory(Options As Map) As PrefsFileResult
	Dim Result As PrefsFileResult
	Result.Initialize
	Dim Chooser As DirectoryChooser
	Chooser.Initialize
	If Options.ContainsKey("title") Then Chooser.Title = Options.Get("title")
	If Options.ContainsKey("initialDirectory") Then
		Dim Initial As String = Options.Get("initialDirectory")
		If Initial <> "" Then Chooser.InitialDirectory = Initial
	End If
	Dim Selected As String = Chooser.Show(OwnerForm)
	If Selected = "" Or Selected = Null Then
		Result.SetCancelled
		Return Result
	End If
	Result.SetSelected(Selected, File.GetUri(Selected, ""), File.GetName(Selected), "inode/directory", "path")
	Return Result
End Sub

' Copies a selected file into application-managed storage and returns the stored path.
' Returns "" when copying is not possible.
Public Sub CopyToAppStorage(SourcePath As String, TargetFileName As String) As String
	Try
		Dim DirectoryName As String = File.Combine(File.DirApp, "prefs-files")
		If File.Exists(DirectoryName, "") = False Then File.MakeDir(File.DirApp, "prefs-files")
		Dim TargetName As String = TargetFileName
		If TargetName = "" Then TargetName = File.GetName(SourcePath)
		File.Copy(ParentOf(SourcePath), File.GetName(SourcePath), DirectoryName, TargetName)
		Return File.Combine(DirectoryName, TargetName)
	Catch
		LastError = LastException.Message
		Return ""
	End Try
End Sub

Private Sub MimeFromExtension(FilePath As String) As String
	Dim Name As String = File.GetName(FilePath)
	Dim DotIndex As Int = Name.LastIndexOf(".")
	If DotIndex = -1 Then Return "application/octet-stream"
	Dim Extension As String = Name.SubString(DotIndex + 1).ToLowerCase
	Select Extension
		Case "png": Return "image/png"
		Case "jpg", "jpeg": Return "image/jpeg"
		Case "gif": Return "image/gif"
		Case "webp": Return "image/webp"
		Case "txt": Return "text/plain"
		Case "json": Return "application/json"
		Case "pdf": Return "application/pdf"
	End Select
	Return "application/octet-stream"
End Sub

Private Sub IsListObject(Value As Object) As Boolean
	If Value Is List Then Return True
	Return False
End Sub

Private Sub ParentOf(FullPath As String) As String
	Dim SeparatorIndex As Int = FullPath.LastIndexOf("\")
	If SeparatorIndex = -1 Then SeparatorIndex = FullPath.LastIndexOf("/")
	If SeparatorIndex = -1 Then Return FullPath
	Return FullPath.SubString2(0, SeparatorIndex)
End Sub
