B4J=true
Group=Classes
ModulesStructureVersion=1
Type=Class
Version=10.7
@EndOfDesignText@
' Public cross-platform facade for a JSON-backed preferences UI.
' B4J  - modal dialog (Show) and an embeddable JavaFX page (CreatePage).
' B4A  - modal overlay dialog (Show) and an embeddable page (CreatePage).
' B4i  - not implemented yet; Show/CreatePage compile but do nothing.
Sub Class_Globals
	Private Callback As Object
	Private EventPrefix As String
	#If B4A
	Private OwnerForm As Activity
	#Else If B4J
	Private OwnerForm As Form
	#Else
	Private OwnerForm As Page
	#End If
	Private Model As PrefsModel
	Private Controller As PrefsController
	Private Localization As PrefsLocalization
	Private CurrentTheme As PrefsTheme
	Private ActivePage As PrefsPage
	Private PageActive As Boolean
	Private PageStylesheetAdded As Boolean
	#If B4A
	Private ActiveDialog As PrefsDialog
	#End If
	Private FileProvider As PrefsFileProvider
	Private CustomRenderers As Map
	Private Ready As Boolean
	Public LastError As String
End Sub

Public Sub Initialize (EventTarget As Object, EventName As String, Owner As Object)
	Callback = EventTarget
	EventPrefix = EventName
	OwnerForm = Owner
	Model.Initialize
	Controller.Initialize(Model)
	Localization.Initialize
	CurrentTheme.Initialize(False)
	FileProvider.Initialize(OwnerForm)
	CustomRenderers.Initialize
	Ready = False
	LastError = ""
End Sub

Public Sub SetFileProvider (Provider As PrefsFileProvider)
	FileProvider = Provider
End Sub

Public Sub GetFileProvider As PrefsFileProvider
	Return FileProvider
End Sub

' Registers a custom renderer for "custom" preferences. Name must match the
' options.renderer value in the definition. Target is the module hosting the
' lifecycle subs (class instances are not supported as the target); EventName
' is their prefix. Required lifecycle subs, where <E> is the event name:
'   <E>_Create(Args As Map) As Object
'   <E>_Read(Handle As Object, Definition As Map) As Object
'   <E>_Validate(Value As Object, Definition As Map) As String
'   <E>_Refresh(Handle As Object, Args As Map)
'   <E>_Dispose(Handle As Object)
Public Sub RegisterCustomRenderer (Name As String, Target As Object, EventName As String)
	Dim Entry As Map
	Entry.Initialize
	Entry.Put("target", Target)
	Entry.Put("event", EventName)
	CustomRenderers.Put(Name, Entry)
End Sub

Public Sub GetCustomRenderer (Name As String) As Map
	If CustomRenderers.ContainsKey(Name) Then Return CustomRenderers.Get(Name)
	Return Null
End Sub

Public Sub LoadDefinition (DefinitionJson As String) As Boolean
	If PageActive Then DisposePage
	Dim NewModel As PrefsModel
	NewModel.Initialize
	If NewModel.LoadFromJson(DefinitionJson) = False Then
		LastError = NewModel.LastError
		Ready = False
		Return False
	End If
	Model = NewModel
	Controller.Initialize(Model)
	Ready = True
	LastError = ""
	Return True
End Sub

' Enables persistence. Committed values are written to the store after commit/set/reset.
Public Sub SetStore (S As PrefsStore)
	Controller.SetStore(S)
End Sub

Public Sub GetStore As PrefsStore
	Return Controller.GetStore
End Sub

' Loads stored values into committed state for known value preferences. Returns applied count.
Public Sub LoadStoredValues As Int
	If CheckReady = False Then Return 0
	Dim S As PrefsStore = Controller.GetStore
	If S.IsInitialized = False Then Return 0
	Dim Applied As Int = Controller.ApplyValues(S.Load)
	If PageActive Then ActivePage.RefreshValues
	Return Applied
End Sub

' Persists the current committed values into the store, preserving unknown stored keys.
Public Sub SaveStoredValues
	Dim S As PrefsStore = Controller.GetStore
	If S.IsInitialized Then S.Save(Controller.GetValues)
End Sub

' Imports values from a JSON object string into the store, then applies them. Returns applied count.
Public Sub ImportValues (JsonText As String) As Int
	If CheckReady = False Then Return 0
	Dim S As PrefsStore = Controller.GetStore
	If S.IsInitialized = False Then Return 0
	If S.FromJson(JsonText) = False Then
		LastError = "Invalid JSON passed to ImportValues."
		Return 0
	End If
	Dim Applied As Int = Controller.ApplyValues(S.Load)
	If PageActive Then ActivePage.RefreshValues
	Return Applied
End Sub

' Saves committed values into the store and returns a JSON snapshot.
Public Sub ExportValues As String
	Dim S As PrefsStore = Controller.GetStore
	If S.IsInitialized = False Then Return ""
	S.Save(Controller.GetValues)
	Return S.ToJson
End Sub

Public Sub SetDictionary (Language As String, Values As Map)
	Localization.SetDictionary(Language, Values)
End Sub

Public Sub SetLanguage (Language As String)
	Localization.SetLanguage(Language)
	If PageActive Then ActivePage.RefreshLocalization
End Sub

Public Sub GetLanguage As String
	Return Localization.GetLanguage
End Sub

Public Sub SetTheme (Value As PrefsTheme)
	CurrentTheme = Value
	If PageActive Then ActivePage.SetTheme(Value)
End Sub

Public Sub CreateLightTheme As PrefsTheme
	Dim Value As PrefsTheme
	Value.Initialize(False)
	Return Value
End Sub

Public Sub CreateDarkTheme As PrefsTheme
	Dim Value As PrefsTheme
	Value.Initialize(True)
	Return Value
End Sub

Public Sub IsDarkTheme As Boolean
	Return CurrentTheme.IsDark
End Sub

' Returns the active theme object. Custom renderers can read its colors so
' they follow theme changes (the same object is mutated by theme toggles).
Public Sub GetTheme As PrefsTheme
	Return CurrentTheme
End Sub

Public Sub SetValue (Id As String, Value As Object) As Boolean
	If CheckReady = False Then Return False
	If Controller.SetValue(Id, Value) = False Then
		LastError = Controller.LastError
		Return False
	End If
	If PageActive Then ActivePage.RefreshValue(Id, Value)
	LastError = ""
	Return True
End Sub

Public Sub GetValue (Id As String) As Object
	If Ready = False Then Return Null
	Return Controller.GetValue(Id)
End Sub

Public Sub GetValues As Map
	If Ready = False Then
		Dim Empty As Map
		Empty.Initialize
		Return Empty
	End If
	Return Controller.GetValues
End Sub

Public Sub ResetToDefaults
	If CheckReady = False Then Return
	Controller.ResetToDefaults
	If PageActive Then ActivePage.RefreshValues
End Sub

Public Sub ResetPreference (Id As String)
	If CheckReady = False Then Return
	Controller.ResetPreference(Id)
	If PageActive Then ActivePage.RefreshValue(Id, Controller.GetValue(Id))
End Sub

' Shows the dialog. On B4J this blocks until the window closes. On B4A it builds
' an overlay and returns immediately; the _DialogClosed event is raised by the
' dialog when the user finishes. In both cases the host receives exactly one
' _DialogClosed(Saved As Boolean) call.
Public Sub Show
	If CheckReady = False Then
		ReportError(LastError)
		Return
	End If
	If PageActive Then ActivePage.RefreshValues
	Dim Dialog As PrefsDialog
	Dialog.Initialize(OwnerForm, Controller, Model, Localization, CurrentTheme, FileProvider, CustomRenderers, Callback, EventPrefix)
	#If B4J
	Dim WasSaved As Boolean = Dialog.Show
	CallSub2(Callback, EventPrefix & "_DialogClosed", WasSaved)
	#Else If B4A
	ActiveDialog = Dialog
	Dialog.Show
	#Else
	Dialog.Show
	CallSub2(Callback, EventPrefix & "_DialogClosed", False)
	#End If
End Sub

' Mounts the settings page inside a caller-owned container. The container is
' typed as B4XView so callers can pass any host view (an AnchorPane on B4J,
' a Panel on B4A).
Public Sub CreatePage (Container As B4XView)
	If CheckReady = False Then
		ReportError(LastError)
		Return
	End If
	If PageActive Then DisposePage
	#If B4A
	ActiveDialog = Null
	#End If
	#If B4J
	If PageStylesheetAdded = False Then
		Dim CssUri As String = File.GetUri(File.DirAssets, "prefs.css")
		If OwnerForm.Stylesheets.IndexOf(CssUri) = -1 Then OwnerForm.Stylesheets.Add(CssUri)
		PageStylesheetAdded = True
	End If
	#End If
	ActivePage.Initialize(Container, Controller, Model, Localization, CurrentTheme, FileProvider, CustomRenderers, Callback, EventPrefix)
	PageActive = True
End Sub

Public Sub RefreshPage
	If PageActive Then ActivePage.RefreshValues
End Sub

Public Sub DisposePage
	If PageActive Then
		ActivePage.Dispose
		PageActive = False
	End If
End Sub

' Delivers a directory chosen by the host application (after a _BrowseDirectory
' event) to the currently open dialog or page. No-op elsewhere.
Public Sub SetDirectoryValue (Uri As String)
	#If B4A
	If ActiveDialog <> Null Then
		ActiveDialog.SetDirectoryValue(Uri)
	Else If PageActive Then
		ActivePage.SetDirectoryValue(Uri)
	End If
	#End If
End Sub

Private Sub CheckReady As Boolean
	If Ready = False Then
		LastError = "LoadDefinition must succeed before accessing preference values or showing the dialog."
		Return False
	End If
	Return True
End Sub

Private Sub ReportError (Message As String)
	Log("B4XFlexibleDialog: " & Message)
End Sub
