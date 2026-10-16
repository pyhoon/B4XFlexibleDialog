B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=10.7
@EndOfDesignText@

' B4J side of the B4XPages demo. Owns the library facade, the persisted store
' and the sample rating renderer, and is exposed to the shared page through the
' AppHost code module. Keeping this in a class (rather than the Main project
' module) makes the B4J and B4A examples structurally identical.

Sub Class_Globals
	Private fx As JFX
	Private MainForm As Form
	Private Facade As B4XFlexibleDialog
	Private Store As PrefsStore
	Private En As Map
	Private Ms As Map
	Private StarFont As Font
End Sub

Public Sub Initialize (Form1 As Form)
	MainForm = Form1
	Dim Parser As JSONParser
	Parser.Initialize(File.ReadString(File.DirAssets, "en.json"))
	En = Parser.NextObject
	Parser.Initialize(File.ReadString(File.DirAssets, "ms.json"))
	Ms = Parser.NextObject

	Facade.Initialize(Me, "Prefs", MainForm)
	Facade.SetDictionary("en", En)
	Facade.SetDictionary("ms", Ms)
	Facade.SetLanguage("en")
	Facade.SetTheme(Facade.CreateLightTheme)
	If Facade.LoadDefinition(File.ReadString(File.DirAssets, "settings.json")) = False Then
		fx.Msgbox(MainForm, Facade.LastError, "Definition error")
		Return
	End If
	Facade.RegisterCustomRenderer("RatingStars", Me, "Rating")

	Store.Initialize
	Facade.SetStore(Store)
	If File.Exists(File.DirApp, "prefs-store.json") Then
		If Store.FromJson(File.ReadString(File.DirApp, "prefs-store.json")) Then Facade.LoadStoredValues
	End If
End Sub

' Called by the shared B4XMainPage: opens the modal preferences dialog.
Public Sub ShowPrefsDialog
	Facade.Show
End Sub

' Called by the shared B4XMainPage: mounts the settings page into the given host.
Public Sub ShowPrefsPage (Host As B4XView)
	Facade.CreatePage(Host)
End Sub

Sub Prefs_BeforeSave(Values As Map) As Boolean
	Return True
End Sub

Sub Prefs_AfterSave(Values As Map)
	Log("Saved values: " & Values)
	File.WriteString(File.DirApp, "prefs-store.json", Store.ToJson)
End Sub

Sub Prefs_DialogClosed(WasSaved As Boolean)
	Log("Closed. Saved=" & WasSaved & " Values=" & Facade.GetValues)
End Sub

Sub Prefs_Action(PreferenceId As String)
	Log("Action: " & PreferenceId)
End Sub

' Sample custom renderer: a 1-5 star rating row using MaterialIcons glyphs.
Private Sub Rating_Create(Args As Map) As Object
	Dim Parent As B4XView = Args.Get("parent")
	Dim Left As Double = Args.Get("left")
	Dim Top As Double = Args.Get("top")
	Dim Width As Double = Args.Get("width")
	Dim Height As Double = Args.Get("height")
	Dim Value As Int = Args.Get("value")
	If StarFont.IsInitialized = False Then StarFont = fx.LoadFont(File.DirAssets, "b4x_materialicons.ttf", 24)
	Dim Buttons As List
	Buttons.Initialize
	Dim Handle As Map
	Handle.Initialize
	Handle.Put("buttons", Buttons)
	Handle.Put("value", Value)
	Dim StarWidth As Double = Width / 5
	For I = 1 To 5
		Dim Star As Label
		Star.Initialize("ratingStar")
		Dim Tag As Map
		Tag.Initialize
		Tag.Put("handle", Handle)
		Tag.Put("index", I)
		Star.Tag = Tag
		Star.Font = StarFont
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
	If Facade.GetLanguage = "ms" Then Return Ms.Get("validation.rating")
	Return En.Get("validation.rating")
End Sub

Private Sub Rating_Refresh(Handle As Object, Args As Map)
	Dim H As Map = Handle
	H.Put("value", Args.Get("value"))
	Rating_Paint(H)
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
	Dim T As PrefsTheme = Facade.GetTheme
	Dim OnText As String = ThemeCss(T.AccentColor)
	Dim OffText As String = ThemeCss(T.SecondaryTextColor)
	Dim Buttons As List = Handle.Get("buttons")
	Dim Value As Int = Handle.Get("value")
	For I = 0 To Buttons.Size - 1
		Dim Star As Label = Buttons.Get(I)
		If I < Value Then
			Star.Text = Chr(0xE838)
			Star.Style = "-fx-background-color: transparent; -fx-text-fill: " & OnText & ";"
		Else
			Star.Text = Chr(0xE83A)
			Star.Style = "-fx-background-color: transparent; -fx-text-fill: " & OffText & ";"
		End If
	Next
End Sub

Private Sub ThemeCss(Color As Int) As String
	Dim R As Int = Bit.And(Bit.ShiftRight(Color, 16), 255)
	Dim G As Int = Bit.And(Bit.ShiftRight(Color, 8), 255)
	Dim B As Int = Bit.And(Color, 255)
	Return "rgb(" & R & "," & G & "," & B & ")"
End Sub

Private Sub ratingStar_MouseClicked (EventData As MouseEvent)
	Dim Star As Label = Sender
	Dim Tag As Map = Star.Tag
	Dim Handle As Map = Tag.Get("handle")
	Handle.Put("value", Tag.Get("index"))
	Rating_Paint(Handle)
End Sub
