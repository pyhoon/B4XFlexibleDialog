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
'  - B4J: the facade needs the owner Form, obtained with B4XPages.GetNativeParent;
'    a button opens the modal dialog next to the embedded page.
'  - B4A: a button opens the same form in a modal overlay with Save/Cancel, in
'    addition to the inline page (the renderer has no built-in chrome).
'  - B4i: the renderer has no built-in Save/Cancel chrome, so the page provides
'    those buttons (no dialog).

Sub Class_Globals
	Private Root As B4XView
	Private xui As XUI
	Private TitleLabel As Label
	Private PageHost As B4XView
	Private Store As PrefsStore
	Private En As Map
	Private Ms As Map
	Private StoreFileName As String = "prefs-values.json"
	Private SetupDone As Boolean
	Private PageHostReady As Boolean
	Private MediaChooser1 As MediaChooser
	#If B4J
	Private DialogButton As Button
	Private Facade As B4XFlexibleDialog
	#Else
	Private DemoTheme As PrefsTheme
	Private SaveButton As Button
	Private CancelButton As Button
	Private Renderer As PrefsRenderer
	Private DirPicker As PrefsDirPicker
	Private Localization As PrefsLocalization
	Private Model As PrefsModel
	Private Controller As PrefsController
	#If B4A
	Private OpenDialogButton As Button
	Private DialogOverlay As B4XView
	Private DialogCard As B4XView
	Private DialogHost As B4XView
	Private DialogTitle As Label
	Private DialogSaveButton As Button
	Private DialogCancelButton As Button
	Private DialogRenderer As PrefsRenderer
	Private DialogOpen As Boolean
	#End If
	#End If
End Sub

Public Sub Initialize
End Sub

'This event will be called once, before the page becomes visible.
Private Sub B4XPage_Created (Root1 As B4XView)
	Root = Root1
	TitleLabel.Initialize("")
	TitleLabel.Text = "B4XFlexibleDialog"
	TitleLabel.As(B4XView).TextSize = 22
	Root.AddView(TitleLabel, 20dip, 16dip, 440dip, 36dip)

	#If B4J
	DialogButton.Initialize("DialogButton")
	DialogButton.Text = "Open preferences dialog"
	Root.AddView(DialogButton, 20dip, 64dip, 300dip, 48dip)
	#Else if B4i
	SaveButton.Initialize("SaveButton", SaveButton.STYLE_SYSTEM)
	SaveButton.Text = "Save"
	Root.AddView(SaveButton, 20dip, 64dip, 145dip, 44dip)
	CancelButton.Initialize("CancelButton", SaveButton.STYLE_SYSTEM)
	CancelButton.Text = "Cancel"
	Root.AddView(CancelButton, 175dip, 64dip, 145dip, 44dip)
	#Else
	SaveButton.Initialize("SaveButton")
	SaveButton.Text = "Save"
	Root.AddView(SaveButton, 20dip, 64dip, 145dip, 44dip)
	CancelButton.Initialize("CancelButton")
	CancelButton.Text = "Cancel"
	Root.AddView(CancelButton, 175dip, 64dip, 145dip, 44dip)
	OpenDialogButton.Initialize("OpenDialogButton")
	OpenDialogButton.Text = "Open preferences dialog"
	Root.AddView(OpenDialogButton, 20dip, 116dip, 300dip, 44dip)
	#End If

	CreatePageHost
	Root.AddView(PageHost, 340dip, 16dip, Max(200dip, Root.Width - 360dip), Max(240dip, Root.Height - 32dip))
	#If B4A
	CreateDialog
	#End If
	PageHostReady = True
	Setup
End Sub

' Keeps the hosted page filling the right-hand side as the page is resized.
Private Sub B4XPage_Resize (Width As Int, Height As Int)
	If PageHostReady Then PageHost.SetLayoutAnimated(0, 340dip, 16dip, Max(200dip, Root.Width - 360dip), Max(240dip, Root.Height - 32dip))
	#If B4A
	If DialogOpen Then LayoutDialog
	#End If
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

' Builds the library objects, loads the definition and shows the form.
Private Sub Setup
	If SetupDone Then Return
	SetupDone = True
	LoadDictionaries
	#If B4J
	Dim MainForm As Form = B4XPages.GetNativeParent(Me)
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
	Facade.RegisterCustomRenderer("MediaImage", Me, "MediaImage")
	Facade.RegisterCustomRenderer("XuiText", Me, "XuiText")
	Store.Initialize
	Facade.SetStore(Store)
	If File.Exists(StoreDirectory, StoreFileName) Then
		If Store.FromJson(File.ReadString(StoreDirectory, StoreFileName)) Then Facade.LoadStoredValues
	End If
	CallSubDelayed(Me, "MountPage")
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
	Renderer.RegisterCustomRenderer("MediaImage", Me, "MediaImage")
	Renderer.RegisterCustomRenderer("XuiText", Me, "XuiText")
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

#If B4J
' Deferred so the owner Form has been shown and its Scene exists before the
' facade attaches its stylesheet.
Private Sub MountPage
	Facade.CreatePage(PageHost)
End Sub
#End If

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
	If Renderer.Save Then CommitValues
End Sub

Private Sub CommitValues
	Store.Save(Controller.GetValues)
	File.WriteString(StoreDirectory, StoreFileName, Store.ToJson)
	Log("Saved values: " & Controller.GetValues)
End Sub

Public Sub CancelPrefs
	Renderer.Cancel
End Sub

Sub Prefs_BrowseDirectory (Id As String)
	DirPicker.SelectDir(False)
End Sub

Sub DirPicker_DirectoryPicked (Uri As String)
	#If B4A
	If DialogOpen Then
		DialogRenderer.SetDirectoryValue(Uri)
		Return
	End If
	#End If
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
	File.WriteString(StoreDirectory, StoreFileName, Store.ToJson)
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

' ---------------------------------------------------------------------------
' Demo-only spike: a custom renderer that hosts two third-party cross-platform
' libraries (the shipped B4A/B4i renderer is untouched):
'   - XUI Views  -> XUIViewsUtils.CreateB4XImageView builds the thumbnail from
'                   code, without a designer layout.
'   - MediaChooser -> picks an image on B4J, B4A and B4i and raises a
'                   ResumableSub so the handler can await the result.
' It proves both can be driven from a custom renderer's create/read/refresh/
' dispose lifecycle while staying platform-agnostic.
Private Sub MediaImage_Create (Args As Map) As Object
	Dim Parent As B4XView = Args.Get("parent")
	Dim Definition As Map = Args.Get("definition")
	#If B4J
	Dim Left As Double = Args.Get("left")
	Dim Top As Double = Args.Get("top")
	Dim Width As Double = Args.Get("width")
	Dim Height As Double = Args.Get("height")
	Dim Size As Double = Min(Height, 72dip)
	#Else
	Dim Left As Int = Args.Get("left")
	Dim Top As Int = Args.Get("top")
	Dim Width As Int = Args.Get("width")
	Dim Height As Int = Args.Get("height")
	Dim Size As Int = Min(Height, 72dip)
	#End If

	Dim Preview As B4XImageView = XUIViewsUtils.CreateB4XImageView
	Preview.ResizeMode = "FILL"
	Parent.AddView(Preview.mBase, Left, Top, Size, Size)

	Dim PickButton As Button
	#If B4i
	PickButton.Initialize("MediaImagePick", PickButton.STYLE_SYSTEM)
	#Else
	PickButton.Initialize("MediaImagePick")
	#End If
	PickButton.Text = "Choose image..."
	Parent.AddView(PickButton, Left + Size + 12dip, Top + Size / 2 - 20dip, Width - Size - 12dip, 40dip)

	Dim Handle As Map
	Handle.Initialize
	Handle.Put("preview", Preview)
	Handle.Put("button", PickButton)
	Handle.Put("id", Definition.Get("id"))
	Dim Value As String = "" & Args.Get("value")
	Handle.Put("value", Value)
	If Value <> "" Then
		Handle.Put("dir", PathParent(Value))
		Handle.Put("file", PathName(Value))
	End If
	PickButton.Tag = Handle
	MediaImage_ApplyTheme(Handle)
	MediaImage_Load(Handle)
	Return Handle
End Sub

' Re-applied from _Refresh too, which the library fires on value *and* theme changes.
Private Sub MediaImage_ApplyTheme (Handle As Map)
	Dim T As PrefsTheme = Theme
	Dim Preview As B4XImageView = Handle.Get("preview")
	Preview.mBackgroundColor = T.InputBackgroundColor
	Preview.CornersRadius = 8
	Dim PickButton As Button = Handle.Get("button")
	#If B4J
	PickButton.Style = "-fx-background-color: " & ThemeCss(T.SecondaryButtonBackgroundColor) & "; -fx-text-fill: " & ThemeCss(T.SecondaryButtonTextColor) & "; -fx-background-radius: 4;"
	#Else
	PickButton.As(B4XView).TextColor = T.SecondaryButtonTextColor
	PickButton.As(B4XView).SetColorAndBorder(T.SecondaryButtonBackgroundColor, 0, 0, 4dip)
	#End If
End Sub

Private Sub MediaImage_Load (Handle As Map)
	Dim Preview As B4XImageView = Handle.Get("preview")
	Dim Dir As String = Handle.GetDefault("dir", "")
	Dim FileName As String = Handle.GetDefault("file", "")
	If Dir <> "" And FileName <> "" And File.Exists(Dir, FileName) Then
		Preview.Load(Dir, FileName)
	Else
		Preview.Clear
	End If
End Sub

' File.GetParent/GetName are not available on every platform, so split the path
' ourselves (B4J hands MediaChooser results back as a full path).
Private Sub PathName (Path As String) As String
	Dim P As String = Path
	#If B4J
	P = P.Replace(Chr(92), "/")
	#End If
	Dim Index As Int = P.LastIndexOf("/")
	If Index = -1 Then Return P
	Return P.SubString(Index + 1)
End Sub

Private Sub PathParent (Path As String) As String
	Dim P As String = Path
	#If B4J
	P = P.Replace(Chr(92), "/")
	#End If
	Dim Index As Int = P.LastIndexOf("/")
	If Index = -1 Then Return ""
	Return P.SubString2(0, Index)
End Sub

' Shared theme source for the spike widgets: B4J uses the facade's live theme,
' while B4A/B4i use a light theme so they match the hosted form.
Private Sub Theme As PrefsTheme
	#If B4J
	Return Facade.GetTheme
	#Else
	If DemoTheme.IsInitialized = False Then DemoTheme.Initialize(False)
	Return DemoTheme
	#End If
End Sub

Private Sub MediaImage_Read (Handle As Object, Definition As Map) As Object
	Dim H As Map = Handle
	Return H.Get("value")
End Sub

Private Sub MediaImage_Validate (Value As Object, Definition As Map) As String
	Return ""
End Sub

Private Sub MediaImage_Refresh (Handle As Object, Args As Map)
	Dim H As Map = Handle
	Dim Value As String = "" & Args.Get("value")
	H.Put("value", Value)
	If Value <> "" Then
		H.Put("dir", PathParent(Value))
		H.Put("file", PathName(Value))
	End If
	MediaImage_ApplyTheme(H)
	MediaImage_Load(H)
End Sub

Private Sub MediaImage_Dispose (Handle As Object)
	Dim H As Map = Handle
	Dim Preview As B4XImageView = H.Get("preview")
	Preview.mBase.RemoveViewFromParent
	Dim PickButton As Button = H.Get("button")
	Dim ButtonView As B4XView = PickButton
	ButtonView.RemoveViewFromParent
End Sub

' XUI Views control driven purely from code: B4XFloatTextField only exposes
' DesignerCreateView, so we feed it a base panel and a throwaway label.
Private Sub XuiText_Create (Args As Map) As Object
	Dim Parent As B4XView = Args.Get("parent")
	#If B4J
	Dim Left As Double = Args.Get("left")
	Dim Top As Double = Args.Get("top")
	Dim Width As Double = Args.Get("width")
	Dim Height As Double = Args.Get("height")
	#Else
	Dim Left As Int = Args.Get("left")
	Dim Top As Int = Args.Get("top")
	Dim Width As Int = Args.Get("width")
	Dim Height As Int = Args.Get("height")
	#End If

	Dim T As PrefsTheme = Theme

	Dim Base As B4XView = xui.CreatePanel("")
	Parent.AddView(Base, Left, Top, Width, Height)

	Dim Lbl As Label
	Lbl.Initialize("")
	Dim LblView As B4XView = Lbl
	LblView.TextColor = T.TextColor

	Dim Props As Map = CreateMap("HintColor": T.AccentColor, "NonFocusedHintColor": T.SecondaryTextColor, "Hint": "Nickname", "ShowRevealButton": False)
	Dim Field As B4XFloatTextField
	Field.Initialize(Me, "XuiField")
	Field.DesignerCreateView(Base, Lbl, Props)
	Field.Text = "" & Args.Get("value")

	Dim Handle As Map
	Handle.Initialize
	Handle.Put("base", Base)
	Handle.Put("field", Field)
	XuiText_ApplyTheme(Handle)
	Return Handle
End Sub

' Re-applied from _Refresh too, so the field follows live theme changes. B4XFloatTextField
' leaves its text field at the platform default, so we paint it with the theme's input
' colors; B4J needs CSS (.Style) the same way the library's own inputs do.
Private Sub XuiText_ApplyTheme (Handle As Map)
	Dim T As PrefsTheme = Theme
	Dim Field As B4XFloatTextField = Handle.Get("field")
	Field.HintColor = T.AccentColor
	Field.NonFocusedHintColor = T.SecondaryTextColor
	Field.Update
	#If B4J
	Dim Tf As TextField = Field.TextField
	Tf.Style = "-fx-control-inner-background: " & ThemeCss(T.InputBackgroundColor) & "; -fx-background-color: " & ThemeCss(T.InputBackgroundColor) & "; -fx-text-fill: " & ThemeCss(T.TextColor) & "; -fx-prompt-text-fill: " & ThemeCss(T.SecondaryTextColor) & "; -fx-accent: " & ThemeCss(T.AccentColor) & "; -fx-focus-color: " & ThemeCss(T.AccentColor) & "; -fx-border-color: " & ThemeCss(T.InputBorderColor) & "; -fx-border-radius: 4; -fx-background-radius: 4;"
	#Else
	Field.TextField.TextColor = T.TextColor
	Field.TextField.SetColorAndBorder(T.InputBackgroundColor, 1dip, T.InputBorderColor, 4dip)
	#End If
	If Field.lblClear.IsInitialized Then Field.lblClear.TextColor = T.TextColor
	If Field.lblV.IsInitialized Then Field.lblV.TextColor = T.TextColor
End Sub

Private Sub XuiText_Read (Handle As Object, Definition As Map) As Object
	Dim H As Map = Handle
	Dim Field As B4XFloatTextField = H.Get("field")
	Return Field.Text
End Sub

Private Sub XuiText_Validate (Value As Object, Definition As Map) As String
	Return ""
End Sub

Private Sub XuiText_Refresh (Handle As Object, Args As Map)
	Dim H As Map = Handle
	Dim Field As B4XFloatTextField = H.Get("field")
	Field.Text = "" & Args.Get("value")
	XuiText_ApplyTheme(H)
End Sub

Private Sub XuiText_Dispose (Handle As Object)
	Dim H As Map = Handle
	Dim Base As B4XView = H.Get("base")
	Base.RemoveViewFromParent
End Sub

' MediaChooser is created on first use: on B4J it needs a data folder before
' Initialize (XUI.SetDataFolder), which the shared page only sets here.
Private Sub EnsureMediaChooser
	If MediaChooser1.IsInitialized Then Return
	#If B4J
	xui.SetDataFolder("B4XPagesDemo")
	#End If
	MediaChooser1.Initialize(Me, "MediaChooser")
End Sub

Private Sub MediaImagePick_Click
	Dim Btn As B4XView = Sender
	Dim Handle As Map = Btn.Tag
	EnsureMediaChooser
	Wait For (MediaChooser1.ChooseImage(Btn)) Complete (Result As MediaChooserResult)
	If Result.Success = False Then Return
	Dim Dir As String = Result.MediaDir
	Dim FileName As String = Result.MediaFile
	#If B4J
	If FileName = "" Then
		FileName = PathName(Dir)
		Dir = PathParent(Dir)
	End If
	#End If
	Handle.Put("dir", Dir)
	Handle.Put("file", FileName)
	Handle.Put("value", File.Combine(Dir, FileName))
	MediaImage_Load(Handle)
	Log("MediaChooser picked: " & File.Combine(Dir, FileName))
End Sub

#If B4A
' Builds the hidden modal overlay used by the "Open preferences dialog" button.
' It mirrors the B4J dialog presentation alongside the inline hosted form: a dark
' scrim over the page, a white card with the same form the renderer paints, and
' Save/Cancel buttons (the B4A renderer has no built-in chrome).
Private Sub CreateDialog
	DialogOverlay = xui.CreatePanel("dialogOverlay")
	DialogOverlay.Color = Colors.ARGB(150, 0, 0, 0)
	Root.AddView(DialogOverlay, 0, 0, Root.Width, Root.Height)

	DialogCard = xui.CreatePanel("dialogCard")
	DialogCard.Color = Colors.White
	DialogOverlay.AddView(DialogCard, 0, 0, 100dip, 100dip)

	DialogTitle.Initialize("")
	DialogTitle.Text = "Preferences"
	DialogTitle.TextSize = 20
	DialogTitle.TextColor = Colors.DarkGray
	DialogCard.AddView(DialogTitle, 0, 0, 100dip, 40dip)

	DialogHost = xui.CreatePanel("dialogHost")
	DialogCard.AddView(DialogHost, 0, 0, 100dip, 100dip)

	DialogSaveButton.Initialize("DialogSaveButton")
	DialogSaveButton.Text = "Save"
	DialogCard.AddView(DialogSaveButton, 0, 0, 140dip, 48dip)

	DialogCancelButton.Initialize("DialogCancelButton")
	DialogCancelButton.Text = "Cancel"
	DialogCard.AddView(DialogCancelButton, 0, 0, 140dip, 48dip)

	DialogOverlay.Visible = False
	LayoutDialog
End Sub

' Empty handlers keep taps on the scrim/card from reaching the page behind them.
Private Sub dialogOverlay_Click
End Sub

Private Sub dialogCard_Click
End Sub

Private Sub LayoutDialog
	If DialogOverlay = Null Then Return
	Dim Pad As Int = 16dip
	Dim TitleHeight As Int = 44dip
	Dim ButtonHeight As Int = 48dip
	Dim CardWidth As Int = Min(560dip, Root.Width - 40dip)
	Dim CardHeight As Int = Min(640dip, Root.Height - 60dip)
	Dim CardLeft As Int = (Root.Width - CardWidth) / 2
	Dim CardTop As Int = (Root.Height - CardHeight) / 2
	DialogOverlay.SetLayoutAnimated(0, 0, 0, Root.Width, Root.Height)
	DialogCard.SetLayoutAnimated(0, CardLeft, CardTop, CardWidth, CardHeight)
	' Card children use card-relative coordinates (the card already sits at CardLeft/CardTop).
	DialogTitle.SetLayoutAnimated(0, Pad, Pad, CardWidth - Pad * 2, TitleHeight)
	Dim HostTop As Int = Pad + TitleHeight
	Dim HostHeight As Int = CardHeight - Pad * 3 - TitleHeight - ButtonHeight
	DialogHost.SetLayoutAnimated(0, Pad, HostTop, CardWidth - Pad * 2, HostHeight)
	Dim ButtonWidth As Int = 140dip
	Dim ButtonTop As Int = CardHeight - Pad - ButtonHeight
	DialogCancelButton.SetLayoutAnimated(0, CardWidth - Pad - ButtonWidth, ButtonTop, ButtonWidth, ButtonHeight)
	DialogSaveButton.SetLayoutAnimated(0, CardWidth - Pad - ButtonWidth * 2 - 12dip, ButtonTop, ButtonWidth, ButtonHeight)
End Sub

Private Sub OpenDialogButton_Click
	If DialogOpen Then Return
	DialogRenderer.Initialize(Me, "Prefs", Model, Controller, Localization)
	DialogRenderer.RegisterCustomRenderer("RatingStars", Me, "Rating")
	DialogRenderer.RegisterCustomRenderer("MediaImage", Me, "MediaImage")
	DialogRenderer.RegisterCustomRenderer("XuiText", Me, "XuiText")
	DialogOpen = True
	LayoutDialog
	DialogRenderer.Render(DialogHost)
	DialogOverlay.Visible = True
	DialogOverlay.BringToFront
End Sub

Private Sub DialogSaveButton_Click
	If DialogRenderer.Save Then
		CommitValues
		HideDialog
	End If
End Sub

Private Sub DialogCancelButton_Click
	DialogRenderer.Cancel
	HideDialog
End Sub

Private Sub HideDialog
	DialogOverlay.Visible = False
	DialogRenderer.Dispose
	DialogOpen = False
	Renderer.Render(PageHost)
End Sub
#End If
