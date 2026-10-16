B4A=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=14.2
@EndOfDesignText@

' B4A side of the B4XPages demo. Owns the model/controller, the library
' PrefsRenderer (which builds the form into a host B4XView), the SAF directory
' picker, persistence and the sample rating custom renderer. It is a class, not
' a code module, because the renderer holds view-typed fields which B4A forbids
' in Process_Globals; Main instantiates it and exposes it through AppHost.

Sub Class_Globals
	Private Model As PrefsModel
	Private Controller As PrefsController
	Private Localization As PrefsLocalization
	Private Renderer As PrefsRenderer
	Private DirPicker As PrefsDirPicker
	Private Store As PrefsStore
	Private StarFont As Typeface
	Private En As Map
	Private Ms As Map
	Private StoreFileName As String = "prefs-values.json"
End Sub

Public Sub Initialize
	Dim Parser As JSONParser
	Parser.Initialize(File.ReadString(File.DirAssets, "en.json"))
	En = Parser.NextObject
	Parser.Initialize(File.ReadString(File.DirAssets, "ms.json"))
	Ms = Parser.NextObject

	Localization.Initialize
	Localization.SetDictionary("en", En)
	Localization.SetDictionary("ms", Ms)
	Localization.SetLanguage("en")
	Model.Initialize
	If Model.LoadFromJson(File.ReadString(File.DirAssets, "settings.json")) = False Then
		Log("Definition error: " & Model.LastError)
		Return
	End If
	Controller.Initialize(Model)
	Renderer.Initialize(Me, "Prefs", Model, Controller, Localization)
	Renderer.RegisterCustomRenderer("RatingStars", Me, "Rating")
	DirPicker.Initialize(Me, "DirPicker")
	Store.Initialize
	If File.Exists(File.DirInternal, StoreFileName) Then
		If Store.FromJson(File.ReadString(File.DirInternal, StoreFileName)) Then
			Dim Restored As Int = Controller.ApplyValues(Store.Load)
			Log("Restored " & Restored & " value(s) from " & StoreFileName)
		Else
			Log("Stored values file could not be parsed: " & StoreFileName)
		End If
	End If
End Sub

' Called by the shared B4XMainPage: renders the settings form into the host.
Public Sub ShowPrefsPage (Host As B4XView)
	Renderer.Render(Host)
End Sub

' Called by the shared B4XMainPage Save button.
Public Sub SavePrefs
	If Renderer.Save Then
		Store.Save(Controller.GetValues)
		File.WriteString(File.DirInternal, StoreFileName, Store.ToJson)
		Log("Saved values: " & Controller.GetValues)
	End If
End Sub

' Called by the shared B4XMainPage Cancel button.
Public Sub CancelPrefs
	Renderer.Cancel
End Sub

Sub Prefs_BeforeSave(Values As Map) As Boolean
	Return True
End Sub

Sub Prefs_AfterSave(Values As Map)
	Log("Saved values: " & Values)
End Sub

Sub Prefs_Action(PreferenceId As String)
	Log("Action: " & PreferenceId)
End Sub

Sub Prefs_BrowseDirectory(Id As String)
	DirPicker.SelectDir(False)
End Sub

Sub DirPicker_DirectoryPicked(Uri As String)
	Renderer.SetDirectoryValue(Uri)
End Sub

Sub DirPicker_DirectoryCancelled
	Log("Directory pick cancelled")
End Sub

' Sample custom renderer: a 1-5 rating row using MaterialIcons glyphs. Same
' create/read/validate/dispose lifecycle as B4J; B4A has no refresh trigger, so
' hosts re-render instead, which disposes and recreates the control.
Private Sub Rating_Create(Args As Map) As Object
	Dim Parent As B4XView = Args.Get("parent")
	Dim Left As Int = Args.Get("left")
	Dim Top As Int = Args.Get("top")
	Dim Width As Int = Args.Get("width")
	Dim Height As Int = Args.Get("height")
	Dim Value As Int = Args.Get("value")
	Dim Buttons As List
	Buttons.Initialize
	Dim Handle As Map
	Handle.Initialize
	Handle.Put("buttons", Buttons)
	Handle.Put("value", Value)
	If StarFont.IsInitialized = False Then StarFont = Typeface.LoadFromAssets("b4x_materialicons.ttf")
	Dim StarWidth As Int = Width / 5
	For I = 1 To 5
		Dim Star As Label
		Star.Initialize("ratingStar")
		Dim Tag As Map
		Tag.Initialize
		Tag.Put("handle", Handle)
		Tag.Put("index", I)
		Star.Tag = Tag
		Star.Typeface = StarFont
		Star.TextSize = 30
		Star.Gravity = Gravity.CENTER
		Parent.AddView(Star, Left + (I - 1) * StarWidth, Top, StarWidth, Height)
		Buttons.Add(Star)
	Next
	Rating_Paint(Handle)
	Return Handle
End Sub

Private Sub Rating_Read(Handle As Object, Definition As Map) As Object
	Dim H As Map = Handle
	Return H.Get("value")
End Sub

Private Sub Rating_Validate(Value As Object, Definition As Map) As String
	Try
		Dim RatingValue As Int = Value
		If RatingValue >= 1 And RatingValue <= 5 Then Return ""
	Catch
		Log(LastException.Message)
	End Try
	If Localization.GetLanguage = "ms" Then Return Ms.Get("validation.rating")
	Return En.Get("validation.rating")
End Sub

Private Sub Rating_Dispose(Handle As Object)
	Dim H As Map = Handle
	Dim Buttons As List = H.Get("buttons")
	For Each StarObject As Object In Buttons
		Dim Star As B4XView = StarObject
		Star.RemoveViewFromParent
	Next
End Sub

Private Sub Rating_Paint(Handle As Map)
	Dim Buttons As List = Handle.Get("buttons")
	Dim Value As Int = Handle.Get("value")
	For I = 0 To Buttons.Size - 1
		Dim Star As Label = Buttons.Get(I)
		If I < Value Then
			Star.Text = Chr(0xE838)
			Star.TextColor = Colors.RGB(255, 193, 7)
		Else
			Star.Text = Chr(0xE83A)
			Star.TextColor = Colors.Gray
		End If
	Next
End Sub

Private Sub ratingStar_Click
	Dim Star As Label = Sender
	Dim Tag As Map = Star.Tag
	Dim Handle As Map = Tag.Get("handle")
	Handle.Put("value", Tag.Get("index"))
	Rating_Paint(Handle)
End Sub
