B4A=true
Group=Pages
ModulesStructureVersion=1
Type=Class
Version=9.85
@EndOfDesignText@

' Shared B4XPages launcher page. This single class is the whole demo on every
' platform: it builds its UI with cross-platform views and hosts the library
' directly (the B4J facade in-process, or the B4A/B4i PrefsRenderer which paints
' the form into a host B4XView). It is also the callback target for the library
' events and for the sample RatingStars custom renderer.
'
' Platform notes:
'  - B4J: the facade needs the owner Form, which the page cannot obtain, so Main
'    hands it over with SetHostForm once B4XPages was initialized.
'  - B4A/B4i: the renderer has no built-in Save/Cancel chrome, so the page
'    provides those buttons.

Sub Class_Globals
	Private Root As B4XView
	Private xui As XUI
	Private TitleLabel As Label
	Private PageHost As B4XView
	Private Store As PrefsStore
	Private En As Map
	Private Ms As Map
	Private StoreFileName As String = "prefs-values.json"
	#If B4J
	Private DialogButton As Button
	Private Facade As B4XFlexibleDialog
	Private MainForm As Form
	#Else
	Private SaveButton As Button
	Private CancelButton As Button
	Private Renderer As PrefsRenderer
	Private DirPicker As PrefsDirPicker
	Private Localization As PrefsLocalization
	Private Model As PrefsModel
	Private Controller As PrefsController
	#End If
End Sub

Public Sub Initialize
End Sub

'This event will be called once, before the page becomes visible.
Private Sub B4XPage_Created (Root1 As B4XView)
	Root = Root1
	TitleLabel.Initialize("")
	TitleLabel.Text = "B4XFlexibleDialog"
	TitleLabel.TextSize = 22
	Root.AddView(TitleLabel, 20dip, 16dip, 440dip, 36dip)

	#If B4J
	DialogButton.Initialize("DialogButton")
	DialogButton.Text = "Open preferences dialog"
	Root.AddView(DialogButton, 20dip, 64dip, 300dip, 48dip)
	#Else
	SaveButton.Initialize("SaveButton")
	SaveButton.Text = "Save"
	Root.AddView(SaveButton, 20dip, 64dip, 145dip, 44dip)
	CancelButton.Initialize("CancelButton")
	CancelButton.Text = "Cancel"
	Root.AddView(CancelButton, 175dip, 64dip, 145dip, 44dip)
	#End If

	CreatePageHost
	Root.AddView(PageHost, 340dip, 16dip, Max(200dip, Root.Width - 360dip), Max(240dip, Root.Height - 32dip))
	Setup
End Sub

Private Sub CreatePageHost
	#If B4J
	Dim Anchor As AnchorPane
	Anchor.Initialize("pageHost")
	PageHost = Anchor
	#Else
	PageHost = xui.CreatePanel("pageHost")
	#End If
End Sub

#If B4J
' Called by Main once B4XPages was initialized. The facade needs the owner Form,
' which a B4XPages page cannot obtain on its own.
Public Sub SetHostForm (Form1 As Form)
	MainForm = Form1
	Setup
End Sub
#End If

' Builds the library objects, loads the definition and shows the form. On B4J it
' is a no-op until Main supplies the owner Form through SetHostForm.
Private Sub Setup
	#If B4J
	If MainForm = Null Then Return
	#End If
	LoadDictionaries
	#If B4J
	Facade.Initialize(Me, "Prefs", MainForm)
	Facade.SetDictionary("en", En)
	Facade.SetDictionary("ms", Ms)
	Facade.SetLanguage("en")
	Facade.SetTheme(Facade.CreateLightTheme)
	If Facade.LoadDefinition(File.ReadString(File.DirAssets, "settings.json")) = False Then
		Log("Definition error: " & Facade.LastError)
		Return
	End If
	Facade.RegisterCustomRenderer("RatingStars", Me, "Rating")
	Store.Initialize
	Facade.SetStore(Store)
	If File.Exists(File.DirApp, "prefs-store.json") Then
		If Store.FromJson(File.ReadString(File.DirApp, "prefs-store.json")) Then Facade.LoadStoredValues
	End If
	Facade.CreatePage(PageHost)
	#Else
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
	If File.Exists(StoreDirectory, StoreFileName) Then
		If Store.FromJson(File.ReadString(StoreDirectory, StoreFileName)) Then
			Dim Restored As Int = Controller.ApplyValues(Store.Load)
			Log("Restored " & Restored & " value(s) from " & StoreFileName)
		Else
			Log("Stored values file could not be parsed: " & StoreFileName)
		End If
	End If
	Renderer.Render(PageHost)
	#End If
End Sub

Private Sub LoadDictionaries
	Dim Parser As JSONParser
	Parser.Initialize(File.ReadString(File.DirAssets, "en.json"))
	En = Parser.NextObject
	Parser.Initialize(File.ReadString(File.DirAssets, "ms.json"))
	Ms = Parser.NextObject
End Sub

' Where stored values live on the platforms that persist them (B4J uses File.DirApp
' directly in Setup).
Private Sub StoreDirectory As String
	#If B4J
	Return File.DirApp
	#Else If B4i
	Return File.DirDocuments
	#Else
	Return File.DirInternal
	#End If
End Sub

#If B4J
Private Sub DialogButton_Click
	Facade.Show
End Sub

Sub Prefs_DialogClosed (WasSaved As Boolean)
	Log("Closed. Saved=" & WasSaved & " Values=" & Facade.GetValues)
End Sub
#Else
Private Sub SaveButton_Click
	SavePrefs
End Sub

Private Sub CancelButton_Click
	CancelPrefs
End Sub

' Called by the Save button; the B4A/B4i renderer has no built-in chrome.
Public Sub SavePrefs
	If Renderer.Save Then
		Store.Save(Controller.GetValues)
		File.WriteString(StoreDirectory, StoreFileName, Store.ToJson)
		Log("Saved values: " & Controller.GetValues)
	End If
End Sub

Public Sub CancelPrefs
	Renderer.Cancel
End Sub

Sub Prefs_BrowseDirectory (Id As String)
	DirPicker.SelectDir(False)
End Sub

Sub DirPicker_DirectoryPicked (Uri As String)
	Renderer.SetDirectoryValue(Uri)
End Sub

Sub DirPicker_DirectoryCancelled
	Log("Directory pick cancelled")
End Sub
#End If

Sub Prefs_BeforeSave (Values As Map) As Boolean
	Return True
End Sub

Sub Prefs_AfterSave (Values As Map)
	Log("Saved values: " & Values)
	#If B4J
	File.WriteString(File.DirApp, "prefs-store.json", Store.ToJson)
	#End If
End Sub

Sub Prefs_Action (PreferenceId As String)
	Log("Action: " & PreferenceId)
End Sub

' Sample custom renderer: a 1-5 star rating row using MaterialIcons glyphs. Same
' create/read/validate(/refresh)/dispose lifecycle on every platform; B4A/B4i have
' no refresh trigger, so hosts re-render instead (dispose + recreate).
Private Sub Rating_Create (Args As Map) As Object
	Dim Parent As B4XView = Args.Get("parent")
	#If B4J
	Dim Left As Double = Args.Get("left")
	Dim Top As Double = Args.Get("top")
	Dim Width As Double = Args.Get("width")
	Dim Height As Double = Args.Get("height")
	Dim StarWidth As Double = Width / 5
	#Else
	Dim Left As Int = Args.Get("left")
	Dim Top As Int = Args.Get("top")
	Dim Width As Int = Args.Get("width")
	Dim Height As Int = Args.Get("height")
	Dim StarWidth As Int = Width / 5
	#End If
	Dim Value As Int = Args.Get("value")
	Dim Buttons As List
	Buttons.Initialize
	Dim Handle As Map
	Handle.Initialize
	Handle.Put("buttons", Buttons)
	Handle.Put("value", Value)
	For I = 1 To 5
		Dim Star As Label
		Star.Initialize("ratingStar")
		Dim Tag As Map
		Tag.Initialize
		Tag.Put("handle", Handle)
		Tag.Put("index", I)
		Star.Tag = Tag
		#If B4J
		Star.Font = xui.CreateMaterialIcons(24)
		#Else If B4A
		Star.Typeface = Typeface.MATERIALICONS
		Star.TextSize = 30
		Star.Gravity = Gravity.CENTER
		#Else
		Star.Font = Font.CreateMaterialIcons(30)
		Star.TextAlignment = Star.ALIGNMENT_CENTER
		#End If
		Parent.AddView(Star, Left + (I - 1) * StarWidth, Top, StarWidth, Height)
		Buttons.Add(Star)
	Next
	Rating_Paint(Handle)
	Return Handle
End Sub

Private Sub Rating_Read (Handle As Object, Definition As Map) As Object
	Dim H As Map = Handle
	Return H.Get("value")
End Sub

Private Sub Rating_Validate (Value As Object, Definition As Map) As String
	Try
		Dim RatingValue As Int = Value
		If RatingValue >= 1 And RatingValue <= 5 Then Return ""
	Catch
		Log(LastException.Message)
	End Try
	#If B4J
	If Facade.GetLanguage = "ms" Then Return Ms.Get("validation.rating")
	#Else
	If Localization.GetLanguage = "ms" Then Return Ms.Get("validation.rating")
	#End If
	Return En.Get("validation.rating")
End Sub

Private Sub Rating_Refresh (Handle As Object, Args As Map)
	Dim H As Map = Handle
	H.Put("value", Args.Get("value"))
	Rating_Paint(H)
End Sub

Private Sub Rating_Dispose (Handle As Object)
	Dim H As Map = Handle
	Dim Buttons As List = H.Get("buttons")
	For Each StarObject As Object In Buttons
		Dim Star As B4XView = StarObject
		Star.RemoveViewFromParent
	Next
End Sub

Private Sub Rating_Paint (Handle As Map)
	Dim Buttons As List = Handle.Get("buttons")
	Dim Value As Int = Handle.Get("value")
	For I = 0 To Buttons.Size - 1
		Dim Star As Label = Buttons.Get(I)
		If I < Value Then
			Star.Text = Chr(0xE838)
			#If B4J
			Star.Style = "-fx-background-color: transparent; -fx-text-fill: " & ThemeCss(Facade.GetTheme.AccentColor) & ";"
			#Else
			Star.TextColor = Colors.RGB(255, 193, 7)
			#End If
		Else
			Star.Text = Chr(0xE83A)
			#If B4J
			Star.Style = "-fx-background-color: transparent; -fx-text-fill: " & ThemeCss(Facade.GetTheme.SecondaryTextColor) & ";"
			#Else
			Star.TextColor = Colors.Gray
			#End If
		End If
	Next
End Sub

#If B4J
Private Sub ThemeCss (Color As Int) As String
	Dim R As Int = Bit.And(Bit.ShiftRight(Color, 16), 255)
	Dim G As Int = Bit.And(Bit.ShiftRight(Color, 8), 255)
	Dim B As Int = Bit.And(Color, 255)
	Return "rgb(" & R & "," & G & "," & B & ")"
End Sub

Private Sub ratingStar_MouseClicked (EventData As MouseEvent)
	Rating_StarClicked(Sender)
End Sub
#Else
Private Sub ratingStar_Click
	Rating_StarClicked(Sender)
End Sub
#End If

Private Sub Rating_StarClicked (StarObject As Object)
	Dim Star As Label = StarObject
	Dim Tag As Map = Star.Tag
	Dim Handle As Map = Tag.Get("handle")
	Handle.Put("value", Tag.Get("index"))
	Rating_Paint(Handle)
End Sub
