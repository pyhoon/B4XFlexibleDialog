B4J=true
Group=Classes
ModulesStructureVersion=1
Type=Class
Version=10.7
@EndOfDesignText@
' Cross-platform preferences dialog. Values are read into controller draft state
' before commit. Presentation and controls are platform specific:
'   B4J  - a JavaFX modal window (ShowAndWait) with JavaFX controls.
'   B4A  - a full-screen overlay built on top of the owner Activity with native
'          Android controls.
'   B4i  - not implemented yet (returns False); the shared call sites still compile.
' Custom preferences go through renderers registered with RegisterCustomRenderer,
' following the same create/read/validate/refresh/dispose lifecycle everywhere.
Sub Class_Globals
	#If B4J
	Private fx As JFX
	Private OwnerForm As Form
	Private DialogForm As Form
	Private DialogScroll As ScrollPane
	#Else If B4A
	Private OwnerForm As Activity
	Private OverlayPanel As Panel
	Private Card As Panel
	Private Form As ScrollView
	Private TitleLabel As Label
	Private FilePicker As ContentChooser
	Private OverlayHost As B4XView
	Private CardWidth As Int
	Private CardHeight As Int
	Private PendingFileId As String
	Private PendingCopy As Boolean
	Private PendingDirId As String
	#Else
	Private OwnerForm As Page
	#End If
	#If B4J
	Private ContentPane As B4XView
	#End If
	Private Controller As PrefsController
	Private Model As PrefsModel
	Private Localization As PrefsLocalization
	Private Theme As PrefsTheme
	#If B4J
	Private FileProvider As PrefsFileProvider
	#End If
	Private CustomRenderers As Map
	Private CustomHandles As Map
	Private BuildError As String
	Private Callback As Object
	Private EventPrefix As String
	Private Controls As Map
	Private ControlTypes As Map
	Private TitleLabels As Map
	Private SectionLabels As Map
	Private SliderLabels As Map
	Private SliderMin As Map
	Private SliderMax As Map
	Private MultiValues As Map
	Private ActionButtons As Map
	Private BrowseButtons As Map
	Private ClearButtons As Map
	Private StatusLabel As Label
	Private SaveButton As Button
	Private CancelButton As Button
	Private ResetButton As Button
	Private LanguageButton As Button
	Private ThemeButton As Button
	Private Saved As Boolean
	Private RowTop As Int
	#If B4J
	Private ContentWidth As Int
	Private InputLeft As Int
	#End If
End Sub

Public Sub Initialize (Owner As Object, ValueController As PrefsController, Definition As PrefsModel, L10n As PrefsLocalization, UiTheme As PrefsTheme, Provider As PrefsFileProvider, Renderers As Map, Target As Object, TargetEvent As String)
	OwnerForm = Owner
	Controller = ValueController
	Model = Definition
	Localization = L10n
	Theme = UiTheme
	#If B4J
	FileProvider = Provider
	#End If
	CustomRenderers = Renderers
	Callback = Target
	EventPrefix = TargetEvent
End Sub

' B4A only: hosts the overlay in a caller-owned view (for example a B4XPages
' page root) instead of the raw Activity. This is required when the platform
' title bar is drawn as an overlay on top of the Activity, otherwise the top of
' the dialog is hidden behind it. Ignored on B4J and B4i.
Public Sub SetOverlayHost (Host As B4XView)
	#If B4A
	OverlayHost = Host
	#End If
End Sub

' Shows the dialog. On B4J this blocks until the window closes and returns whether
' the draft was committed. On B4A it builds an overlay and returns immediately;
' the Saved result is delivered through the _DialogClosed event instead.
Public Sub Show As Boolean
	Controller.BeginDraft
	Controls.Initialize
	ControlTypes.Initialize
	TitleLabels.Initialize
	SectionLabels.Initialize
	SliderLabels.Initialize
	SliderMin.Initialize
	SliderMax.Initialize
	MultiValues.Initialize
	ActionButtons.Initialize
	BrowseButtons.Initialize
	ClearButtons.Initialize
	CustomHandles.Initialize
	BuildError = ""
	Saved = False
	RowTop = 18
	#If B4J
	ContentWidth = 760
	InputLeft = 240
	#End If
	#If B4J
	Return ShowB4J
	#Else If B4A
	Return ShowB4A
	#Else
	Log("PrefsDialog is not implemented on this platform.")
	Controller.CancelDraft
	Return False
	#End If
End Sub

#If B4J
Private Sub ShowB4J As Boolean
	Dim PreferenceCount As Int = Model.GetPreferenceIds.Size
	Dim SectionCount As Int = Model.GetSections.Size
	Dim MultilineCount As Int = 0
	Dim MultichoiceCount As Int = 0
	For Each Id As String In Model.GetPreferenceIds
		Dim Preference As Map = Model.GetPreference(Id)
		If Preference.Get("type") = "multiline" Then MultilineCount = MultilineCount + 1
		If Preference.Get("type") = "multichoice" Then MultichoiceCount = MultichoiceCount + 1
	Next
	Dim Height As Int = Min(600, Max(380, 220 + PreferenceCount * 56 + SectionCount * 36 + MultilineCount * 52 + MultichoiceCount * 62))
	DialogForm.Initialize("dlg", ContentWidth + 40, Height)
	DialogForm.Title = Localization.Text(Model.GetTitleKey)
	DialogForm.SetOwner(OwnerForm)
	DialogForm.Resizable = True
	DialogForm.Stylesheets.Add(File.GetUri(File.DirAssets, "prefs.css"))
	DialogForm.RootPane.StyleClasses.Add("prefs-surface")
	ApplyTheme
	Dim InnerPane As Pane
	InnerPane.Initialize("dlg")
	ContentPane = InnerPane
	DialogScroll.Initialize("dlg")
	DialogScroll.FitToWidth = True
	DialogScroll.InnerNode = ContentPane
	DialogScroll.Style = "-fx-background-color: transparent; -fx-background: transparent;"
	DialogForm.RootPane.AddNode(DialogScroll, 0, 0, -1, Height - 92)
	DialogForm.RootPane.SetAnchors(DialogScroll, 0, 0, 0, 92)
	For Each Section As Map In Model.GetSections
		Dim SectionTitle As Label
		SectionTitle.Initialize("")
		SectionTitle.Text = Localization.Text(Section.Get("titleKey"))
		SectionTitle.TextColor = fx.Colors.From32Bit(Theme.SecondaryTextColor)
		ContentPane.AddView(SectionTitle, 24, RowTop, ContentWidth - 48, 28)
		SectionLabels.Put(Section.Get("id"), SectionTitle)
		RowTop = RowTop + Theme.SectionSpacing + 12
		Dim Items As List = Section.Get("preferences")
		For Each Pref As Map In Items
			AddPreference(Pref)
		Next
		RowTop = RowTop + 6
	Next
	ContentPane.As(Pane).PrefWidth = ContentWidth
	ContentPane.As(Pane).PrefHeight = RowTop + 20
	StatusLabel.Initialize("")
	StatusLabel.TextColor = fx.Colors.From32Bit(Theme.ErrorTextColor)
	DialogForm.RootPane.AddNode(StatusLabel, 34, Height - 90, ContentWidth - 30, 24)
	DialogForm.RootPane.SetAnchors(StatusLabel, 34, -1, -1, 66)
	LanguageButton.Initialize("dlg")
	LanguageButton.Text = Localization.Text("ui.language")
	LanguageButton.TextColor = fx.Colors.From32Bit(Theme.AccentColor)
	DialogForm.RootPane.AddNode(LanguageButton, 30, Height - 60, 110, 34)
	DialogForm.RootPane.SetAnchors(LanguageButton, 30, -1, -1, 26)
	ThemeButton.Initialize("dlg")
	ThemeButton.Text = Localization.Text("ui.theme")
	ThemeButton.TextColor = fx.Colors.From32Bit(Theme.AccentColor)
	DialogForm.RootPane.AddNode(ThemeButton, 146, Height - 60, 100, 34)
	DialogForm.RootPane.SetAnchors(ThemeButton, 146, -1, -1, 26)
	ResetButton.Initialize("dlg")
	ResetButton.Text = Localization.Text("ui.reset")
	DialogForm.RootPane.AddNode(ResetButton, 390, Height - 60, 90, 34)
	DialogForm.RootPane.SetAnchors(ResetButton, 390, -1, -1, 26)
	CancelButton.Initialize("dlg")
	CancelButton.Text = Localization.Text("ui.cancel")
	DialogForm.RootPane.AddNode(CancelButton, 500, Height - 60, 90, 34)
	DialogForm.RootPane.SetAnchors(CancelButton, 500, -1, -1, 26)
	SaveButton.Initialize("dlg")
	SaveButton.Text = Localization.Text("ui.save")
	DialogForm.RootPane.AddNode(SaveButton, 610, Height - 60, 110, 34)
	DialogForm.RootPane.SetAnchors(SaveButton, 610, -1, -1, 26)
	RefreshButtons
	If BuildError <> "" Then
		StatusLabel.Text = BuildError
		StatusLabel.TextColor = fx.Colors.From32Bit(Theme.ErrorTextColor)
	End If
	DialogForm.ShowAndWait
	If Saved = False Then Controller.CancelDraft
	DisposeCustomHandles
	Return Saved
End Sub
#End If

#If B4A
Private Sub ShowB4A As Boolean
	FilePicker.Initialize("prefscc")
	PendingFileId = ""
	PendingCopy = False
	PendingDirId = ""
	OverlayPanel.Initialize("")
	OverlayPanel.Color = Colors.ARGB(150, 0, 0, 0)
	' Buttons carry a Material elevation; raise the overlay above them so it is
	' not painted underneath elevated siblings.
	OverlayPanel.Elevation = 100dip
	' %x/%y are not usable in a code-only class (no designer layout sets the
	' module reference size), so derive the overlay from its host. Prefer the
	' caller-supplied host (already inset below the title bar); fall back to the
	' Activity when none was provided.
	Dim ViewWidth As Int
	Dim ViewHeight As Int
	If OverlayHost.IsInitialized Then
		ViewWidth = OverlayHost.Width
		ViewHeight = OverlayHost.Height
		OverlayHost.AddView(OverlayPanel, 0, 0, ViewWidth, ViewHeight)
		Dim OverlayView As B4XView = OverlayPanel
		OverlayView.BringToFront
	Else
		ViewWidth = OwnerForm.Width
		ViewHeight = OwnerForm.Height
		OwnerForm.AddView(OverlayPanel, 0, 0, ViewWidth, ViewHeight)
	End If
	Dim CardLeft As Int = 20dip
	Dim CardTop As Int = 30dip
	CardWidth = ViewWidth - 2 * CardLeft
	CardHeight = ViewHeight - 2 * CardTop
	Card.Initialize("")
	OverlayPanel.AddView(Card, CardLeft, CardTop, CardWidth, CardHeight)
	Card.Color = Theme.BackgroundColor
	TitleLabel.Initialize("")
	TitleLabel.Text = Localization.Text(Model.GetTitleKey)
	TitleLabel.TextSize = 20
	TitleLabel.TextColor = Theme.TextColor
	Card.AddView(TitleLabel, 16dip, 12dip, CardWidth - 32dip, 40dip)
	Dim ButtonHeight As Int = 52dip
	Dim FormTop As Int = 60dip
	Form.Initialize(100dip)
	Card.AddView(Form, 0, FormTop, CardWidth, CardHeight - FormTop - ButtonHeight - 12dip)
	Dim InnerWidth As Int = CardWidth - 32dip
	For Each Section As Object In Model.GetSections
		Dim SectionMap As Map = Section
		Dim SectionTitle As Label
		SectionTitle.Initialize("")
		SectionTitle.Text = Localization.Text(SectionMap.Get("titleKey"))
		SectionTitle.TextSize = 18
		SectionTitle.TextColor = Theme.SecondaryTextColor
		Form.Panel.AddView(SectionTitle, 16dip, RowTop, InnerWidth, 28dip)
		SectionLabels.Put(SectionMap.Get("id"), SectionTitle)
		RowTop = RowTop + 36dip
		Dim Items As List = SectionMap.Get("preferences")
		For Each PrefObject As Object In Items
			Dim Pref As Map = PrefObject
			AddPreference(Pref)
		Next
		RowTop = RowTop + 8dip
	Next
	StatusLabel.Initialize("")
	StatusLabel.Text = BuildError
	StatusLabel.TextSize = 14
	StatusLabel.TextColor = Theme.ErrorTextColor
	Form.Panel.AddView(StatusLabel, 16dip, RowTop, InnerWidth, 30dip)
	RowTop = RowTop + 38dip
	Form.Panel.Height = RowTop
	Dim ButtonTop As Int = CardHeight - ButtonHeight - 8dip
	LanguageButton.Initialize("dlg")
	LanguageButton.Tag = "language"
	Card.AddView(LanguageButton, 12dip, ButtonTop, 120dip, ButtonHeight - 8dip)
	ThemeButton.Initialize("dlg")
	ThemeButton.Tag = "theme"
	Card.AddView(ThemeButton, 140dip, ButtonTop, 120dip, ButtonHeight - 8dip)
	ResetButton.Initialize("dlg")
	ResetButton.Tag = "reset"
	Card.AddView(ResetButton, CardWidth - 12dip - 96dip - 8dip - 96dip - 8dip - 120dip, ButtonTop, 120dip, ButtonHeight - 8dip)
	CancelButton.Initialize("dlg")
	CancelButton.Tag = "cancel"
	Card.AddView(CancelButton, CardWidth - 12dip - 96dip - 8dip - 96dip, ButtonTop, 96dip, ButtonHeight - 8dip)
	SaveButton.Initialize("dlg")
	SaveButton.Tag = "save"
	Card.AddView(SaveButton, CardWidth - 12dip - 96dip, ButtonTop, 96dip, ButtonHeight - 8dip)
	RefreshButtons
	ApplyThemeB4A
	Return True
End Sub
#End If

Private Sub AddPreference (Pref As Map)
	Dim Id As String = Pref.Get("id")
	Dim TypeName As String = Pref.Get("type")
	#If B4J
	If TypeName = "label" Then
		Dim InfoLabel As Label
		InfoLabel.Initialize("")
		Dim InfoKey As String = Pref.Get("titleKey")
		If Pref.ContainsKey("descriptionKey") Then InfoKey = Pref.Get("descriptionKey")
		InfoLabel.Text = Localization.Text(InfoKey)
		InfoLabel.TextColor = fx.Colors.From32Bit(Theme.SecondaryTextColor)
		ContentPane.AddView(InfoLabel, 34, RowTop + 4, ContentWidth - 60, 30)
		TitleLabels.Put(Id, InfoLabel)
	Else If TypeName = "action" Then
		Dim ActionButton As Button
		ActionButton.Initialize("prefsAction")
		ActionButton.Tag = Id
		ActionButton.Text = Localization.Text(Pref.Get("titleKey"))
		ActionButton.Style = "-fx-background-color: " & ColorCss(Theme.AccentColor) & "; -fx-text-fill: " & ColorCss(Theme.PrimaryButtonTextColor) & ";"
		ContentPane.AddView(ActionButton, InputLeft, RowTop, 260, 34)
		ActionButtons.Put(Id, ActionButton)
	Else If TypeName = "switch" Or TypeName = "checkbox" Then
		Dim Check As CheckBox
		Check.Initialize("dlg")
		Check.Text = Localization.Text(Pref.Get("titleKey"))
		Check.TextColor = fx.Colors.From32Bit(Theme.TextColor)
		Check.Style = "-fx-accent: " & ColorCss(Theme.AccentColor) & "; -fx-focus-color: " & ColorCss(Theme.AccentColor) & ";"
		Check.Checked = Controller.GetValue(Id)
		ContentPane.AddView(Check, 34, RowTop, ContentWidth - 80, 34)
		Controls.Put(Id, Check)
		TitleLabels.Put(Id, Check)
	Else
		Dim Title As Label
		Title.Initialize("")
		Title.Text = Localization.Text(Pref.Get("titleKey"))
		Title.TextColor = fx.Colors.From32Bit(Theme.TextColor)
		ContentPane.AddView(Title, 34, RowTop + 4, 240, 28)
		TitleLabels.Put(Id, Title)
		If TypeName = "text" Or TypeName = "number" Or TypeName = "password" Or TypeName = "time" Or TypeName = "datetime" Then
			Dim Input As TextField
			If TypeName = "password" Then
				Input.InitializePassword("dlg")
			Else
				Input.Initialize("dlg")
			End If
			Input.Text = "" & Controller.GetValue(Id)
			If TypeName = "time" Then Input.PromptText = Localization.Text("format.time")
			If TypeName = "datetime" Then Input.PromptText = Localization.Text("format.datetime")
			Input.Style = InputCss
			ContentPane.AddView(Input, InputLeft, RowTop, ContentWidth - 40 - InputLeft, 34)
			Controls.Put(Id, Input)
		Else If TypeName = "multiline" Then
			Dim MultilineInput As TextArea
			MultilineInput.Initialize("dlg")
			MultilineInput.Text = "" & Controller.GetValue(Id)
			MultilineInput.WrapText = True
			MultilineInput.Style = InputCss
			ContentPane.AddView(MultilineInput, InputLeft, RowTop, ContentWidth - 40 - InputLeft, 76)
			Controls.Put(Id, MultilineInput)
			RowTop = RowTop + 42
		Else If TypeName = "multichoice" Then
			Dim Multi As ListView
			Multi.Initialize("")
			Multi.MultipleSelection = True
			Multi.Style = InputCss
			Dim PrefOptions As Map = Pref.Get("options")
			Dim MultiItems As List = PrefOptions.Get("items")
			Dim SelectedIndices As List
			SelectedIndices.Initialize
			Dim SelectedValues As List = Controller.GetValue(Id)
			For I = 0 To MultiItems.Size - 1
				Dim Item As Map = MultiItems.Get(I)
				Multi.Items.Add(Localization.Text(Item.Get("titleKey")))
				Dim ItemValue As String = Item.Get("value")
				For Each SelectedValueObject As Object In SelectedValues
					Dim SelectedValue As String = SelectedValueObject
					If SelectedValue = ItemValue Then SelectedIndices.Add(I)
				Next
			Next
			Multi.SetSelectedIndices(SelectedIndices)
			ContentPane.AddView(Multi, InputLeft, RowTop, ContentWidth - 40 - InputLeft, 90)
			Controls.Put(Id, Multi)
			RowTop = RowTop + 56
		Else If TypeName = "date" Then
			Dim DateInput As DatePicker
			DateInput.Initialize("")
			DateInput.DateFormat = "yyyy-MM-dd"
			DateInput.DateTicks = IsoToTicks(Controller.GetValue(Id))
			DateInput.Style = InputCss
			ContentPane.AddView(DateInput, InputLeft, RowTop, 260, 34)
			Controls.Put(Id, DateInput)
		Else If TypeName = "slider" Then
			Dim ValueSlider As Slider
			ValueSlider.Initialize("dlg")
			ValueSlider.Tag = Id
			Dim SliderOptions As Map
			SliderOptions.Initialize
			If Pref.ContainsKey("options") Then SliderOptions = Pref.Get("options")
			If SliderOptions.ContainsKey("min") Then ValueSlider.MinValue = SliderOptions.Get("min") Else ValueSlider.MinValue = 0
			If SliderOptions.ContainsKey("max") Then ValueSlider.MaxValue = SliderOptions.Get("max") Else ValueSlider.MaxValue = 100
			ValueSlider.Value = Controller.GetValue(Id)
			ValueSlider.Style = "-fx-accent: " & ColorCss(Theme.AccentColor) & ";"
			ContentPane.AddView(ValueSlider, InputLeft, RowTop, 380, 34)
			Controls.Put(Id, ValueSlider)
			Dim SliderValueLabel As Label
			SliderValueLabel.Initialize("")
			SliderValueLabel.Text = "" & ValueSlider.Value
			SliderValueLabel.TextColor = fx.Colors.From32Bit(Theme.TextColor)
			ContentPane.AddView(SliderValueLabel, InputLeft + 390, RowTop + 4, 70, 28)
			SliderLabels.Put(Id, SliderValueLabel)
		Else If TypeName = "choice" Then
			Dim Choice As ComboBox
			Choice.Initialize("dlg")
			Choice.Style = InputCss
			Dim PrefOptions As Map = Pref.Get("options")
			Dim ChoiceItems As List = PrefOptions.Get("items")
			Dim Selected As Int = -1
			For I = 0 To ChoiceItems.Size - 1
				Dim Item As Map = ChoiceItems.Get(I)
				Choice.Items.Add(Localization.Text(Item.Get("titleKey")))
				If Item.Get("value") = Controller.GetValue(Id) Then Selected = I
			Next
			Choice.SelectedIndex = Selected
			ContentPane.AddView(Choice, InputLeft, RowTop, ContentWidth - 40 - InputLeft, 34)
			Controls.Put(Id, Choice)
		Else If TypeName = "file" Or TypeName = "directory" Then
			Dim PathField As TextField
			PathField.Initialize("dlg")
			PathField.Text = "" & Controller.GetValue(Id)
			PathField.Style = InputCss
			ContentPane.AddView(PathField, InputLeft, RowTop, ContentWidth - 40 - InputLeft - 184, 34)
			Controls.Put(Id, PathField)
			Dim BrowseButton As Button
			BrowseButton.Initialize("dlg")
			BrowseButton.Text = Localization.Text("ui.browse")
			BrowseButton.Tag = "browse|" & Id
			BrowseButton.Style = SecondaryButtonCss
			ContentPane.AddView(BrowseButton, ContentWidth - 40 - 176, RowTop, 84, 34)
			BrowseButtons.Put(Id, BrowseButton)
			If HasAllowClear(Pref) Then
				Dim ClearButton As Button
				ClearButton.Initialize("dlg")
				ClearButton.Text = Localization.Text("ui.clear")
				ClearButton.Tag = "clear|" & Id
				ClearButton.Style = SecondaryButtonCss
				ContentPane.AddView(ClearButton, ContentWidth - 40 - 84, RowTop, 84, 34)
				ClearButtons.Put(Id, ClearButton)
			End If
		Else If TypeName = "custom" Then
			AddCustomPreference(Pref)
		End If
	End If
	#Else If B4A
	Dim InnerWidth As Int = CardWidth - 32dip
	If TypeName = "label" Then
		Dim InfoKey As String = Pref.Get("titleKey")
		If Pref.ContainsKey("descriptionKey") Then InfoKey = Pref.Get("descriptionKey")
		Dim InfoLabel As Label
		InfoLabel.Initialize("")
		InfoLabel.Text = Localization.Text(InfoKey)
		InfoLabel.TextSize = 14
		InfoLabel.TextColor = Theme.SecondaryTextColor
		Form.Panel.AddView(InfoLabel, 16dip, RowTop, InnerWidth, 30dip)
		TitleLabels.Put(Id, InfoLabel)
		RowTop = RowTop + 38dip
	Else If TypeName = "action" Then
		Dim ActionButton As Button
		ActionButton.Initialize("prefsAction")
		ActionButton.Tag = Id
		ActionButton.Text = Localization.Text(Pref.Get("titleKey"))
		ActionButton.TextSize = 16
		Form.Panel.AddView(ActionButton, 16dip, RowTop, InnerWidth, 52dip)
		ActionButtons.Put(Id, ActionButton)
		RowTop = RowTop + 60dip
	Else If TypeName = "switch" Or TypeName = "checkbox" Then
		Dim Check As CheckBox
		Check.Initialize("")
		Check.Text = Localization.Text(Pref.Get("titleKey"))
		Check.TextSize = 16
		Check.Checked = Controller.GetValue(Id)
		Form.Panel.AddView(Check, 16dip, RowTop, InnerWidth, 52dip)
		Controls.Put(Id, Check)
		TitleLabels.Put(Id, Check)
		RowTop = RowTop + 60dip
	Else
		Dim Title As Label
		Title.Initialize("")
		Title.Text = Localization.Text(Pref.Get("titleKey"))
		Title.TextSize = 16
		Form.Panel.AddView(Title, 16dip, RowTop, InnerWidth, 26dip)
		TitleLabels.Put(Id, Title)
		RowTop = RowTop + 30dip
		If TypeName = "text" Or TypeName = "number" Or TypeName = "password" Or TypeName = "time" Or TypeName = "datetime" Then
			Dim Input As EditText
			Input.Initialize("")
			Input.TextSize = 16
			Input.SingleLine = True
			If TypeName = "password" Then Input.PasswordMode = True
			If TypeName = "number" Then Input.InputType = Input.INPUT_TYPE_DECIMAL_NUMBERS
			If TypeName = "time" Then Input.Hint = Localization.Text("format.time")
			If TypeName = "datetime" Then Input.Hint = Localization.Text("format.datetime")
			Input.Text = "" & Controller.GetValue(Id)
			Form.Panel.AddView(Input, 16dip, RowTop, InnerWidth, 52dip)
			Controls.Put(Id, Input)
			RowTop = RowTop + 60dip
		Else If TypeName = "multiline" Then
			Dim MultilineInput As EditText
			MultilineInput.Initialize("")
			MultilineInput.TextSize = 16
			MultilineInput.SingleLine = False
			MultilineInput.Text = "" & Controller.GetValue(Id)
			Form.Panel.AddView(MultilineInput, 16dip, RowTop, InnerWidth, 120dip)
			Controls.Put(Id, MultilineInput)
			RowTop = RowTop + 128dip
		Else If TypeName = "multichoice" Then
			Dim MultiOptions As Map = Pref.Get("options")
			Dim MultiItems As List = MultiOptions.Get("items")
			Dim SelectedValues As List = Controller.GetValue(Id)
			Dim Checks As List
			Checks.Initialize
			Dim ItemValues As List
			ItemValues.Initialize
			For I = 0 To MultiItems.Size - 1
				Dim MultiItem As Map = MultiItems.Get(I)
				Dim Box As CheckBox
				Box.Initialize("")
				Box.Text = Localization.Text(MultiItem.Get("titleKey"))
				Box.TextSize = 16
				Dim ItemValue As String = MultiItem.Get("value")
				ItemValues.Add(ItemValue)
				For Each SelectedObject As Object In SelectedValues
					Dim SelectedValue As String = SelectedObject
					If ItemValue = SelectedValue Then Box.Checked = True
				Next
				Form.Panel.AddView(Box, 16dip, RowTop, InnerWidth, 44dip)
				RowTop = RowTop + 48dip
				Checks.Add(Box)
			Next
			Controls.Put(Id, Checks)
			MultiValues.Put(Id, ItemValues)
			RowTop = RowTop + 8dip
		Else If TypeName = "date" Then
			Dim DateInput As EditText
			DateInput.Initialize("")
			DateInput.TextSize = 16
			DateInput.SingleLine = True
			DateInput.Hint = "yyyy-MM-dd"
			DateInput.Text = "" & Controller.GetValue(Id)
			Form.Panel.AddView(DateInput, 16dip, RowTop, InnerWidth, 52dip)
			Controls.Put(Id, DateInput)
			RowTop = RowTop + 60dip
		Else If TypeName = "choice" Then
			Dim PrefOptions As Map = Pref.Get("options")
			Dim ChoiceItems As List = PrefOptions.Get("items")
			Dim Selector As Spinner
			Selector.Initialize("")
			Dim Selected As Int = -1
			For I = 0 To ChoiceItems.Size - 1
				Dim Item As Map = ChoiceItems.Get(I)
				Selector.Add(Localization.Text(Item.Get("titleKey")))
				If Item.Get("value") = Controller.GetValue(Id) Then Selected = I
			Next
			Selector.SelectedIndex = Selected
			Form.Panel.AddView(Selector, 16dip, RowTop, InnerWidth, 52dip)
			Controls.Put(Id, Selector)
			RowTop = RowTop + 60dip
		Else If TypeName = "slider" Then
			Dim SliderOptions As Map
			SliderOptions.Initialize
			If Pref.ContainsKey("options") Then SliderOptions = Pref.Get("options")
			Dim Minimum As Double = 0
			Dim Maximum As Double = 100
			If SliderOptions.ContainsKey("min") Then Minimum = SliderOptions.Get("min")
			If SliderOptions.ContainsKey("max") Then Maximum = SliderOptions.Get("max")
			SliderMin.Put(Id, Minimum)
			SliderMax.Put(Id, Maximum)
			Dim Bar As SeekBar
			Bar.Initialize("prefsseek")
			Bar.Tag = Id
			Bar.Max = 1000
			Bar.Value = SliderToPosition(Controller.GetValue(Id), Minimum, Maximum)
			Form.Panel.AddView(Bar, 16dip, RowTop, InnerWidth - 80dip, 52dip)
			Dim ValueLabel As Label
			ValueLabel.Initialize("")
			ValueLabel.TextSize = 14
			ValueLabel.Text = Controller.GetValue(Id)
			Form.Panel.AddView(ValueLabel, 16dip + InnerWidth - 74dip, RowTop + 12dip, 70dip, 28dip)
			SliderLabels.Put(Id, ValueLabel)
			Controls.Put(Id, Bar)
			RowTop = RowTop + 60dip
		Else If TypeName = "file" Or TypeName = "directory" Then
			Dim PathField As EditText
			PathField.Initialize("")
			PathField.TextSize = 14
			PathField.SingleLine = True
			PathField.Enabled = False
			PathField.Text = "" & Controller.GetValue(Id)
			Form.Panel.AddView(PathField, 16dip, RowTop, InnerWidth - 130dip, 52dip)
			Controls.Put(Id, PathField)
			Dim BrowseButton As Button
			BrowseButton.Initialize("prefsbrowse")
			BrowseButton.Tag = Id
			BrowseButton.Text = Localization.Text("ui.browse")
			BrowseButton.TextSize = 16
			Form.Panel.AddView(BrowseButton, 16dip + InnerWidth - 120dip, RowTop, 120dip, 52dip)
			BrowseButtons.Put(Id, BrowseButton)
			RowTop = RowTop + 60dip
		Else If TypeName = "custom" Then
			AddCustomPreference(Pref)
		End If
	End If
	#End If
	ControlTypes.Put(Id, TypeName)
	#If B4J
	RowTop = RowTop + Theme.RowSpacing + 30
	#End If
End Sub

Private Sub AddCustomPreference (Pref As Map)
	Dim Id As String = Pref.Get("id")
	Dim Entry As Map = CustomEntry(Pref)
	If Entry = Null Then
		BuildError = "No custom renderer registered for preference " & Id
		Log(BuildError)
		Dim ErrorLabel As Label
		ErrorLabel.Initialize("")
		ErrorLabel.Text = BuildError
		#If B4J
		ErrorLabel.TextColor = fx.Colors.From32Bit(Theme.ErrorTextColor)
		ContentPane.AddView(ErrorLabel, InputLeft, RowTop, ContentWidth - 40 - InputLeft, 34)
		#Else If B4A
		ErrorLabel.TextSize = 14
		ErrorLabel.TextColor = Theme.ErrorTextColor
		Dim InnerWidth As Int = CardWidth - 32dip
		Form.Panel.AddView(ErrorLabel, 16dip, RowTop, InnerWidth, 52dip)
		RowTop = RowTop + 60dip
		#End If
		Return
	End If
	Dim CustomHeight As Int = 56
	If Pref.ContainsKey("options") Then
		Dim CustomOptions As Map = Pref.Get("options")
		If CustomOptions.ContainsKey("height") Then CustomHeight = CustomOptions.Get("height")
	End If
	#If B4A
	If CustomHeight < 44 Then CustomHeight = 44
	CustomHeight = DipToCurrent(CustomHeight)
	#Else
	If CustomHeight < 34 Then CustomHeight = 34
	#End If
	Dim Args As Map
	Args.Initialize
	#If B4J
	Args.Put("parent", ContentPane)
	Args.Put("left", InputLeft)
	Args.Put("top", RowTop)
	Args.Put("width", ContentWidth - 40 - InputLeft)
	#Else If B4A
	Args.Put("parent", Form.Panel)
	Args.Put("left", 16dip)
	Args.Put("top", RowTop)
	Args.Put("width", CardWidth - 32dip)
	#End If
	Args.Put("height", CustomHeight)
	Args.Put("definition", Pref)
	Args.Put("value", Controller.GetValue(Id))
	Dim Target As Object = Entry.Get("target")
	Dim EventName As String = Entry.Get("event")
	Dim Handle As Object = CallSub2(Target, EventName & "_Create", Args)
	CustomHandles.Put(Id, Handle)
	Controls.Put(Id, Handle)
	#If B4J
	RowTop = RowTop + CustomHeight - 34
	#Else If B4A
	RowTop = RowTop + CustomHeight + 8dip
	#End If
End Sub

Private Sub CustomEntry(Pref As Map) As Map
	If Pref.ContainsKey("options") = False Then Return Null
	Dim Options As Map = Pref.Get("options")
	If Options.ContainsKey("renderer") = False Then Return Null
	Dim Name As String = Options.Get("renderer")
	If CustomRenderers.ContainsKey(Name) = False Then Return Null
	Return CustomRenderers.Get(Name)
End Sub

Private Sub DisposeCustomHandles
	For Each Id As String In CustomHandles.Keys
		Dim Pref As Map = Model.GetPreference(Id)
		Dim Entry As Map = CustomEntry(Pref)
		If Entry <> Null Then
			CallSub2(Entry.Get("target"), Entry.Get("event") & "_Dispose", CustomHandles.Get(Id))
		End If
	Next
	CustomHandles.Clear
End Sub

Private Sub ReadCustom(Id As String) As Object
	Dim Pref As Map = Model.GetPreference(Id)
	Dim Entry As Map = CustomEntry(Pref)
	Return CallSub3(Entry.Get("target"), Entry.Get("event") & "_Read", CustomHandles.Get(Id), Pref)
End Sub

Private Sub RefreshCustom(Id As String, Value As Object)
	Dim Pref As Map = Model.GetPreference(Id)
	Dim Entry As Map = CustomEntry(Pref)
	If Entry = Null Then Return
	Dim Args As Map
	Args.Initialize
	Args.Put("definition", Pref)
	Args.Put("value", Value)
	CallSub3(Entry.Get("target"), Entry.Get("event") & "_Refresh", CustomHandles.Get(Id), Args)
End Sub

#If B4J
Private Sub HasAllowClear(Pref As Map) As Boolean
	If Pref.ContainsKey("options") = False Then Return False
	Dim Options As Map = Pref.Get("options")
	If Options.ContainsKey("allowClear") = False Then Return False
	Dim Value As Boolean = Options.Get("allowClear")
	Return Value
End Sub

Private Sub HasCopyToAppStorage(Pref As Map) As Boolean
	If Pref.ContainsKey("options") = False Then Return False
	Dim Options As Map = Pref.Get("options")
	If Options.ContainsKey("copyToAppStorage") = False Then Return False
	Dim Value As Boolean = Options.Get("copyToAppStorage")
	Return Value
End Sub

Private Sub BuildProviderOptions(Pref As Map) As Map
	Dim Source As Map
	Source.Initialize
	If Pref.ContainsKey("options") Then Source = Pref.Get("options")
	Dim Result As Map
	Result.Initialize
	For Each Key As String In Source.Keys
		Result.Put(Key, Source.Get(Key))
	Next
	Result.Put("title", Localization.Text(Pref.Get("titleKey")))
	Return Result
End Sub
#End If

' Reads every control into the draft, validates, and commits on success.
' Returns True when the values were committed.
Public Sub SaveDraft As Boolean
	If BuildError <> "" Then
		SetStatus(BuildError)
		#If B4J
		StatusLabel.Text = BuildError
		#End If
		Return False
	End If
	For Each Id As String In Controls.Keys
		Dim TypeName As String = ControlTypes.Get(Id)
		Dim Value As Object
		#If B4J
		Select TypeName
			Case "file", "directory"
				Dim PathField As TextField = Controls.Get(Id)
				Value = PathField.Text
			Case "text", "password", "number", "time", "datetime"
				Dim Input As TextField = Controls.Get(Id)
				If TypeName = "number" Then
					If IsNumber(Input.Text) = False Then
						StatusLabel.Text = Localization.Text("validation.number") & " (" & Id & ")"
						StatusLabel.TextColor = fx.Colors.From32Bit(Theme.ErrorTextColor)
						Return False
					End If
					Dim NumberValue As Double = Input.Text
					Value = NumberValue
				Else
					Value = Input.Text
				End If
			Case "multiline"
				Dim MultilineInput As TextArea = Controls.Get(Id)
				Value = MultilineInput.Text
			Case "switch", "checkbox"
				Dim Check As CheckBox = Controls.Get(Id)
				Value = Check.Checked
			Case "multichoice"
				Dim Multi As ListView = Controls.Get(Id)
				Dim SelectedIndices As List = Multi.GetSelectedIndices
				Dim MultiPref As Map = Model.GetPreference(Id)
				Dim MultiOptions As Map = MultiPref.Get("options")
				Dim MultiItems As List = MultiOptions.Get("items")
				Dim SelectedValues As List
				SelectedValues.Initialize
				For Each SelectedIndex As Int In SelectedIndices
					Dim SelectedItem As Map = MultiItems.Get(SelectedIndex)
					SelectedValues.Add(SelectedItem.Get("value"))
				Next
				Value = SelectedValues
			Case "date"
				Dim DateInput As DatePicker = Controls.Get(Id)
				Value = TicksToIso(DateInput.DateTicks)
			Case "slider"
				Dim ValueSlider As Slider = Controls.Get(Id)
				Value = ValueSlider.Value
			Case "choice"
				Dim Choice As ComboBox = Controls.Get(Id)
				If Choice.SelectedIndex < 0 Then
					StatusLabel.Text = Localization.Text("validation.choice") & " (" & Id & ")"
					StatusLabel.TextColor = fx.Colors.From32Bit(Theme.ErrorTextColor)
					Return False
				End If
				Dim Pref As Map = Model.GetPreference(Id)
				Dim PrefOptions As Map = Pref.Get("options")
				Dim Items As List = PrefOptions.Get("items")
				Dim SelectedItem As Map = Items.Get(Choice.SelectedIndex)
				Value = SelectedItem.Get("value")
			Case "custom"
				Value = ReadCustom(Id)
				Dim CustomPref As Map = Model.GetPreference(Id)
				Dim Entry As Map = CustomEntry(CustomPref)
				Dim ValidationError As String = CallSub3(Entry.Get("target"), Entry.Get("event") & "_Validate", Value, CustomPref)
				If ValidationError <> "" Then
					StatusLabel.Text = ValidationError & " (" & Id & ")"
					StatusLabel.TextColor = fx.Colors.From32Bit(Theme.ErrorTextColor)
					Return False
				End If
		End Select
		#Else If B4A
		Select TypeName
			Case "text", "multiline", "password", "number", "date", "time", "datetime"
				Dim Input As EditText = Controls.Get(Id)
				If TypeName = "number" Then
					If IsNumber(Input.Text) = False Then
						SetStatus(Localization.Text("validation.number") & " (" & Id & ")")
						Return False
					End If
					Dim NumberValue As Double = Input.Text
					Value = NumberValue
				Else
					Value = Input.Text
				End If
			Case "switch", "checkbox"
				Dim Check As CheckBox = Controls.Get(Id)
				Value = Check.Checked
			Case "choice"
				Dim Selector As Spinner = Controls.Get(Id)
				If Selector.SelectedIndex < 0 Then
					SetStatus(Localization.Text("validation.choice") & " (" & Id & ")")
					Return False
				End If
				Dim Pref As Map = Model.GetPreference(Id)
				Dim PrefOptions As Map = Pref.Get("options")
				Dim ChoiceItems As List = PrefOptions.Get("items")
				Dim SelectedItem As Map = ChoiceItems.Get(Selector.SelectedIndex)
				Value = SelectedItem.Get("value")
			Case "multichoice"
				Dim Checks As List = Controls.Get(Id)
				Dim ItemValues As List = MultiValues.Get(Id)
				Dim Selected As List
				Selected.Initialize
				For I = 0 To Checks.Size - 1
					Dim Box As CheckBox = Checks.Get(I)
					If Box.Checked Then Selected.Add(ItemValues.Get(I))
				Next
				Value = Selected
			Case "slider"
				Dim Bar As SeekBar = Controls.Get(Id)
				Dim Minimum As Double = SliderMin.Get(Id)
				Dim Maximum As Double = SliderMax.Get(Id)
				Value = Minimum + (Maximum - Minimum) * (Bar.Value / 1000)
			Case "file", "directory"
				Dim PathField As EditText = Controls.Get(Id)
				Value = PathField.Text
			Case "custom"
				Value = ReadCustom(Id)
				Dim CustomPref As Map = Model.GetPreference(Id)
				Dim Entry As Map = CustomEntry(CustomPref)
				Dim ValidationError As String = CallSub3(Entry.Get("target"), Entry.Get("event") & "_Validate", Value, CustomPref)
				If ValidationError <> "" Then
					SetStatus(ValidationError & " (" & Id & ")")
					Return False
				End If
		End Select
		#End If
		If Controller.SetDraftValue(Id, Value) = False Then
			SetStatus(Controller.LastError)
			#If B4J
			StatusLabel.Text = Controller.LastError
			#End If
			Return False
		End If
	Next
	Dim Validation As String = Controller.ValidateDraft
	If Validation <> "" Then
		SetStatus(Validation)
		#If B4J
		StatusLabel.Text = Validation
		#End If
		Return False
	End If
	Dim DraftValues As Map = Controller.GetDraftValues
	If CallSub2(Callback, EventPrefix & "_BeforeSave", DraftValues) = False Then Return False
	Controller.CommitDraft
	Saved = True
	CallSub2(Callback, EventPrefix & "_AfterSave", Controller.GetValues)
	Return True
End Sub

Private Sub ResetDraft
	Controller.ResetDraftToDefaults
	For Each Id As String In Controls.Keys
		SetControlValue(Id, ControlTypes.Get(Id), Controller.GetDraftValues.Get(Id))
	Next
	SetStatus(Localization.Text("ui.reset_done"))
End Sub

Private Sub SetControlValue (Id As String, TypeName As String, Value As Object)
	#If B4J
	Select TypeName
		Case "text", "password", "number", "time", "datetime", "file", "directory"
			Dim Input As TextField = Controls.Get(Id)
			Input.Text = "" & Value
		Case "multiline"
			Dim MultilineInput As TextArea = Controls.Get(Id)
			MultilineInput.Text = "" & Value
		Case "switch", "checkbox"
			Dim Check As CheckBox = Controls.Get(Id)
			Check.Checked = Value
		Case "date"
			Dim DateInput As DatePicker = Controls.Get(Id)
			DateInput.DateTicks = IsoToTicks(Value)
		Case "slider"
			Dim ValueSlider As Slider = Controls.Get(Id)
			ValueSlider.Value = Value
			Dim SliderValueLabel As Label = SliderLabels.Get(Id)
			SliderValueLabel.Text = "" & ValueSlider.Value
		Case "choice"
			Dim Choice As ComboBox = Controls.Get(Id)
			Dim Pref As Map = Model.GetPreference(Id)
			Dim Options As Map = Pref.Get("options")
			Dim Items As List = Options.Get("items")
			Dim SelectedValue As String = Value
			Choice.SelectedIndex = -1
			For I = 0 To Items.Size - 1
				Dim Item As Map = Items.Get(I)
				Dim ItemValue As String = Item.Get("value")
				If ItemValue = SelectedValue Then Choice.SelectedIndex = I
			Next
		Case "multichoice"
			Dim Multi As ListView = Controls.Get(Id)
			Dim SelectedValues As List = Value
			Dim Pref As Map = Model.GetPreference(Id)
			Dim Options As Map = Pref.Get("options")
			Dim Items As List = Options.Get("items")
			Dim SelectedIndices As List
			SelectedIndices.Initialize
			For I = 0 To Items.Size - 1
				Dim Item As Map = Items.Get(I)
				Dim ItemValue As String = Item.Get("value")
				For Each SelectedObject As Object In SelectedValues
					Dim SelectedValue As String = SelectedObject
					If ItemValue = SelectedValue Then SelectedIndices.Add(I)
				Next
			Next
			Multi.SetSelectedIndices(SelectedIndices)
		Case "custom"
			RefreshCustom(Id, Value)
	End Select
	#Else If B4A
	Select TypeName
		Case "text", "multiline", "password", "number", "date", "time", "datetime", "file", "directory"
			Dim Input As EditText = Controls.Get(Id)
			Input.Text = "" & Value
		Case "switch", "checkbox"
			Dim Check As CheckBox = Controls.Get(Id)
			Check.Checked = Value
		Case "choice"
			Dim Selector As Spinner = Controls.Get(Id)
			Dim Pref As Map = Model.GetPreference(Id)
			Dim Options As Map = Pref.Get("options")
			Dim Items As List = Options.Get("items")
			Dim SelectedValue As String = Value
			Selector.SelectedIndex = -1
			For I = 0 To Items.Size - 1
				Dim Item As Map = Items.Get(I)
				Dim ItemValue As String = Item.Get("value")
				If ItemValue = SelectedValue Then Selector.SelectedIndex = I
			Next
		Case "multichoice"
			Dim Checks As List = Controls.Get(Id)
			Dim ItemValues As List = MultiValues.Get(Id)
			Dim SelectedValues As List = Value
			For I = 0 To Checks.Size - 1
				Dim Box As CheckBox = Checks.Get(I)
				Box.Checked = False
				For Each SelectedObject As Object In SelectedValues
					Dim SelectedValue As String = SelectedObject
					If SelectedValue = ItemValues.Get(I) Then Box.Checked = True
				Next
			Next
		Case "slider"
			Dim Bar As SeekBar = Controls.Get(Id)
			Dim Minimum As Double = SliderMin.Get(Id)
			Dim Maximum As Double = SliderMax.Get(Id)
			Bar.Value = SliderToPosition(Value, Minimum, Maximum)
			Dim ValueLabel As Label = SliderLabels.Get(Id)
			ValueLabel.Text = "" & Value
		Case "custom"
			RefreshCustom(Id, Value)
	End Select
	#End If
End Sub

Private Sub SetStatus (Message As String)
	StatusLabel.Text = Message
	#If B4J
	StatusLabel.TextColor = fx.Colors.From32Bit(Theme.ErrorTextColor)
	#Else If B4A
	StatusLabel.TextColor = Colors.Red
	#End If
End Sub

#If B4J
Private Sub dlg_Click
	Dim Source As Object = Sender
	If Source Is Button Then
		Dim B As Button = Source
		If B.Tag <> Null Then
			Dim Tag As String = B.Tag
			If Tag.StartsWith("browse|") Then
				BrowseFile(Tag.SubString(7))
				Return
			Else If Tag.StartsWith("clear|") Then
				ClearFile(Tag.SubString(6))
				Return
			End If
		End If
		If B.Text = Localization.Text("ui.save") Then
			If SaveDraft Then DialogForm.Close
		End If
		If B.Text = Localization.Text("ui.cancel") Then DialogForm.Close
		If B.Text = Localization.Text("ui.reset") Then ResetDraft
		If B.Text = Localization.Text("ui.language") Then Language_Click
		If B.Text = Localization.Text("ui.theme") Then Theme_Click
	End If
End Sub

Private Sub BrowseFile(Id As String)
	Dim Pref As Map = Model.GetPreference(Id)
	Dim TypeName As String = Pref.Get("type")
	Dim Options As Map = BuildProviderOptions(Pref)
	Dim Result As PrefsFileResult
	If TypeName = "directory" Then
		Result = FileProvider.SelectDirectory(Options)
	Else
		Result = FileProvider.SelectFile(Options)
	End If
	If Result.Success Then
		Dim Stored As String = Result.Locator
		If TypeName = "file" And HasCopyToAppStorage(Pref) Then
			Dim Copied As String = FileProvider.CopyToAppStorage(Result.Path, "")
			If Copied <> "" Then Stored = Copied
		End If
		Dim Field As TextField = Controls.Get(Id)
		Field.Text = Stored
		StatusLabel.Text = ""
	Else If Result.Cancelled Then
		' Keep the existing value.
	Else
		StatusLabel.Text = Result.Message
		StatusLabel.TextColor = fx.Colors.From32Bit(Theme.ErrorTextColor)
	End If
End Sub

Private Sub ClearFile(Id As String)
	Dim Field As TextField = Controls.Get(Id)
	Field.Text = ""
End Sub

Private Sub Language_Click
	Localization.ToggleLanguage
	DialogForm.Title = Localization.Text(Model.GetTitleKey)
	RefreshLocalization
End Sub

Private Sub RefreshLocalization
	Dim Sections As List = Model.GetSections
	For Each Section As Map In Sections
		Dim SectionControl As Label = SectionLabels.Get(Section.Get("id"))
		SectionControl.Text = Localization.Text(Section.Get("titleKey"))
		Dim Preferences As List = Section.Get("preferences")
		For Each Pref As Map In Preferences
			Dim Id As String = Pref.Get("id")
			If Pref.Get("type") = "switch" Or Pref.Get("type") = "checkbox" Then
				Dim Check As CheckBox = Controls.Get(Id)
				Check.Text = Localization.Text(Pref.Get("titleKey"))
			Else If Pref.Get("type") = "label" Then
				Dim InfoLabel As Label = TitleLabels.Get(Id)
				Dim InfoKey As String = Pref.Get("titleKey")
				If Pref.ContainsKey("descriptionKey") Then InfoKey = Pref.Get("descriptionKey")
				InfoLabel.Text = Localization.Text(InfoKey)
			Else If Pref.Get("type") = "action" Then
				Dim ActionButton As Button = ActionButtons.Get(Id)
				ActionButton.Text = Localization.Text(Pref.Get("titleKey"))
			Else
				Dim Title As Label = TitleLabels.Get(Id)
				Title.Text = Localization.Text(Pref.Get("titleKey"))
			End If
			If Pref.Get("type") = "custom" Then
				RefreshCustom(Id, ReadCustom(Id))
			Else If Pref.Get("type") = "choice" Then
				Dim Choice As ComboBox = Controls.Get(Id)
				Dim SelectedIndex As Int = Choice.SelectedIndex
				Choice.Items.Clear
				Dim PrefOptions As Map = Pref.Get("options")
				Dim ChoiceItems As List = PrefOptions.Get("items")
				For Each Item As Map In ChoiceItems
					Choice.Items.Add(Localization.Text(Item.Get("titleKey")))
				Next
				Choice.SelectedIndex = SelectedIndex
			Else If Pref.Get("type") = "multichoice" Then
				Dim Multi As ListView = Controls.Get(Id)
				Dim SelectedIndices As List = Multi.GetSelectedIndices
				Multi.Items.Clear
				Dim PrefOptions As Map = Pref.Get("options")
				Dim MultiItems As List = PrefOptions.Get("items")
				For Each Item As Map In MultiItems
					Multi.Items.Add(Localization.Text(Item.Get("titleKey")))
				Next
				Multi.SetSelectedIndices(SelectedIndices)
			End If
		Next
	Next
	RefreshFileButtons
	RefreshButtons
End Sub

Private Sub RefreshFileButtons
	For Each ButtonId As String In BrowseButtons.Keys
		Dim BrowseButton As Button = BrowseButtons.Get(ButtonId)
		BrowseButton.Text = Localization.Text("ui.browse")
		BrowseButton.Style = SecondaryButtonCss
	Next
	For Each ButtonId As String In ClearButtons.Keys
		Dim ClearButton As Button = ClearButtons.Get(ButtonId)
		ClearButton.Text = Localization.Text("ui.clear")
		ClearButton.Style = SecondaryButtonCss
	Next
End Sub

Private Sub Theme_Click
	Theme.Toggle
	ApplyTheme
	For Each Id As String In TitleLabels.Keys
		Dim Node As Object = TitleLabels.Get(Id)
		If Node Is Label Then
			Dim Title As Label = Node
			Title.TextColor = fx.Colors.From32Bit(Theme.TextColor)
		Else If Node Is CheckBox Then
			Dim Check As CheckBox = Node
			Check.TextColor = fx.Colors.From32Bit(Theme.TextColor)
			Check.Style = "-fx-accent: " & ColorCss(Theme.AccentColor) & "; -fx-focus-color: " & ColorCss(Theme.AccentColor) & ";"
		End If
	Next
	For Each Id As String In SectionLabels.Keys
		Dim SectionTitle As Label = SectionLabels.Get(Id)
		SectionTitle.TextColor = fx.Colors.From32Bit(Theme.SecondaryTextColor)
	Next
	For Each Id As String In Controls.Keys
		Dim TypeName As String = ControlTypes.Get(Id)
		If TypeName = "text" Or TypeName = "number" Or TypeName = "password" Or TypeName = "time" Or TypeName = "datetime" Then
			Dim Input As TextField = Controls.Get(Id)
			Input.Style = InputCss
		Else If TypeName = "file" Or TypeName = "directory" Then
			Dim PathField As TextField = Controls.Get(Id)
			PathField.Style = InputCss
		Else If TypeName = "multiline" Then
			Dim MultilineInput As TextArea = Controls.Get(Id)
			MultilineInput.Style = InputCss
		Else If TypeName = "choice" Then
			Dim Choice As ComboBox = Controls.Get(Id)
			Choice.Style = InputCss
		Else If TypeName = "multichoice" Then
			Dim Multi As ListView = Controls.Get(Id)
			Multi.Style = InputCss
		Else If TypeName = "date" Then
			Dim DateInput As DatePicker = Controls.Get(Id)
			DateInput.Style = InputCss
		Else If TypeName = "slider" Then
			Dim ValueSlider As Slider = Controls.Get(Id)
			ValueSlider.Style = "-fx-accent: " & ColorCss(Theme.AccentColor) & ";"
			Dim SliderValueLabel As Label = SliderLabels.Get(Id)
			SliderValueLabel.TextColor = fx.Colors.From32Bit(Theme.TextColor)
		Else If TypeName = "custom" Then
			RefreshCustom(Id, ReadCustom(Id))
		End If
	Next
	For Each Id As String In ActionButtons.Keys
		Dim ActionButton As Button = ActionButtons.Get(Id)
		ActionButton.Style = "-fx-background-color: " & ColorCss(Theme.AccentColor) & "; -fx-text-fill: " & ColorCss(Theme.PrimaryButtonTextColor) & ";"
	Next
	RefreshFileButtons
	RefreshButtons
End Sub

Private Sub prefsAction_Click
	Dim ActionButton As Button = Sender
	Dim PreferenceId As String = ActionButton.Tag
	CallSub2(Callback, EventPrefix & "_Action", PreferenceId)
End Sub

Private Sub dlg_ValueChange(Value As Double)
	Dim ValueSlider As Slider = Sender
	Dim Id As String = ValueSlider.Tag
	If SliderLabels.ContainsKey(Id) = False Then Return
	Dim SliderValueLabel As Label = SliderLabels.Get(Id)
	SliderValueLabel.Text = "" & Value
End Sub

Private Sub ApplyTheme
	DialogForm.BackColor = fx.Colors.From32Bit(Theme.BackgroundColor)
	DialogForm.RootPane.Style = "-fx-background-color: " & ColorCss(Theme.BackgroundColor) & "; -prefs-input-bg: " & ColorCss(Theme.InputBackgroundColor) & "; -prefs-input-text: " & ColorCss(Theme.TextColor) & "; -prefs-input-border: " & ColorCss(Theme.InputBorderColor) & "; -prefs-accent: " & ColorCss(Theme.AccentColor) & "; -prefs-checkmark-text: " & ColorCss(Theme.PrimaryButtonTextColor) & ";"
End Sub

Private Sub RefreshButtons
	SaveButton.Text = Localization.Text("ui.save")
	CancelButton.Text = Localization.Text("ui.cancel")
	ResetButton.Text = Localization.Text("ui.reset")
	LanguageButton.Text = Localization.Text("ui.language")
	ThemeButton.Text = Localization.Text("ui.theme")
	SaveButton.TextColor = fx.Colors.From32Bit(Theme.PrimaryButtonTextColor)
	SaveButton.Style = "-fx-background-color: " & ColorCss(Theme.AccentColor) & "; -fx-text-fill: " & ColorCss(Theme.PrimaryButtonTextColor) & "; -fx-font-weight: bold; -fx-background-radius: 4;"
	CancelButton.TextColor = fx.Colors.From32Bit(Theme.SecondaryButtonTextColor)
	CancelButton.Style = SecondaryButtonCss
	ResetButton.TextColor = fx.Colors.From32Bit(Theme.SecondaryButtonTextColor)
	ResetButton.Style = SecondaryButtonCss
	LanguageButton.TextColor = fx.Colors.From32Bit(Theme.SecondaryButtonTextColor)
	LanguageButton.Style = SecondaryButtonCss
	ThemeButton.TextColor = fx.Colors.From32Bit(Theme.SecondaryButtonTextColor)
	ThemeButton.Style = SecondaryButtonCss
End Sub

Private Sub InputCss As String
	Return "-fx-control-inner-background: " & ColorCss(Theme.InputBackgroundColor) & "; -fx-background-color: " & ColorCss(Theme.InputBackgroundColor) & "; -fx-text-fill: " & ColorCss(Theme.TextColor) & "; -fx-prompt-text-fill: " & ColorCss(Theme.SecondaryTextColor) & "; -fx-accent: " & ColorCss(Theme.AccentColor) & "; -fx-focus-color: " & ColorCss(Theme.AccentColor) & "; -fx-faint-focus-color: transparent; -fx-border-color: " & ColorCss(Theme.InputBorderColor) & "; -fx-border-radius: 4; -fx-background-radius: 4;"
End Sub

Private Sub SecondaryButtonCss As String
	Return "-fx-background-color: " & ColorCss(Theme.SecondaryButtonBackgroundColor) & "; -fx-text-fill: " & ColorCss(Theme.SecondaryButtonTextColor) & "; -fx-background-radius: 4;"
End Sub

Private Sub ColorCss(Color As Int) As String
	Dim R As Int = Bit.And(Bit.ShiftRight(Color, 16), 255)
	Dim G As Int = Bit.And(Bit.ShiftRight(Color, 8), 255)
	Dim B As Int = Bit.And(Color, 255)
	Return "rgb(" & R & "," & G & "," & B & ")"
End Sub

Private Sub IsoToTicks(Value As String) As Long
	If Value = "" Then Return 0
	Dim PreviousFormat As String = DateTime.DateFormat
	DateTime.DateFormat = "yyyy-MM-dd"
	Try
		Dim Result As Long = DateTime.DateParse(Value)
		DateTime.DateFormat = PreviousFormat
		Return Result
	Catch
		DateTime.DateFormat = PreviousFormat
		Return 0
	End Try
End Sub

Private Sub TicksToIso(Ticks As Long) As String
	If Ticks = 0 Then Return ""
	Dim PreviousFormat As String = DateTime.DateFormat
	DateTime.DateFormat = "yyyy-MM-dd"
	Dim Result As String = DateTime.Date(Ticks)
	DateTime.DateFormat = PreviousFormat
	Return Result
End Sub
#End If

#If B4A
Private Sub dlg_Click
	Dim Source As Object = Sender
	If Source Is Button Then
		Dim B As Button = Source
		Dim Action As String = "" & B.Tag
		If Action = "save" Then
			If SaveDraft Then CloseOverlay
		Else If Action = "cancel" Then
			Controller.CancelDraft
			CloseOverlay
		Else If Action = "reset" Then
			ResetDraft
		Else If Action = "language" Then
			Language_Click
		Else If Action = "theme" Then
			Theme_Click
		End If
	End If
End Sub

Private Sub Language_Click
	Localization.ToggleLanguage
	TitleLabel.Text = Localization.Text(Model.GetTitleKey)
	Dim Sections As List = Model.GetSections
	For Each Section As Map In Sections
		Dim SectionControl As Label = SectionLabels.Get(Section.Get("id"))
		SectionControl.Text = Localization.Text(Section.Get("titleKey"))
		Dim Preferences As List = Section.Get("preferences")
		For Each Pref As Map In Preferences
			Dim Id As String = Pref.Get("id")
			If Pref.Get("type") = "switch" Or Pref.Get("type") = "checkbox" Then
				Dim Check As CheckBox = Controls.Get(Id)
				Check.Text = Localization.Text(Pref.Get("titleKey"))
			Else If Pref.Get("type") = "label" Then
				Dim InfoLabel As Label = TitleLabels.Get(Id)
				Dim InfoKey As String = Pref.Get("titleKey")
				If Pref.ContainsKey("descriptionKey") Then InfoKey = Pref.Get("descriptionKey")
				InfoLabel.Text = Localization.Text(InfoKey)
			Else If Pref.Get("type") = "action" Then
				Dim ActionButton As Button = ActionButtons.Get(Id)
				ActionButton.Text = Localization.Text(Pref.Get("titleKey"))
			Else
				Dim Title As Label = TitleLabels.Get(Id)
				Title.Text = Localization.Text(Pref.Get("titleKey"))
			End If
			If Pref.Get("type") = "custom" Then
				RefreshCustom(Id, ReadCustom(Id))
			Else If Pref.Get("type") = "choice" Then
				Dim Selector As Spinner = Controls.Get(Id)
				Dim SelectedIndex As Int = Selector.SelectedIndex
				Selector.Clear
				Dim PrefOptions As Map = Pref.Get("options")
				Dim ChoiceItems As List = PrefOptions.Get("items")
				For Each Item As Map In ChoiceItems
					Selector.Add(Localization.Text(Item.Get("titleKey")))
				Next
				Selector.SelectedIndex = SelectedIndex
			End If
		Next
	Next
	RefreshFileButtons
	RefreshButtons
	ApplyThemeB4A
End Sub

Private Sub Theme_Click
	Theme.Toggle
	ApplyThemeB4A
	For Each Id As String In Controls.Keys
		Dim TypeName As String = ControlTypes.Get(Id)
		If TypeName = "custom" Then RefreshCustom(Id, ReadCustom(Id))
	Next
	RefreshFileButtons
End Sub

Private Sub ApplyThemeB4A
	Card.Color = Theme.BackgroundColor
	Dim FormPanel As B4XView = Form.Panel
	FormPanel.Color = Theme.BackgroundColor
	TitleLabel.TextColor = Theme.TextColor
	StatusLabel.TextColor = Theme.ErrorTextColor
	For Each SectionId As String In SectionLabels.Keys
		Dim SectionTitle As Label = SectionLabels.Get(SectionId)
		SectionTitle.TextColor = Theme.SecondaryTextColor
	Next
	For Each Id As String In TitleLabels.Keys
		Dim Node As Object = TitleLabels.Get(Id)
		Dim TitleView As B4XView = Node
		If ControlTypes.Get(Id) = "label" Then
			TitleView.TextColor = Theme.SecondaryTextColor
		Else
			TitleView.TextColor = Theme.TextColor
		End If
	Next
	For Each Id As String In Controls.Keys
		Dim TypeName As String = ControlTypes.Get(Id)
		If TypeName = "text" Or TypeName = "number" Or TypeName = "password" Or TypeName = "time" Or TypeName = "datetime" Or TypeName = "multiline" Or TypeName = "date" Or TypeName = "file" Or TypeName = "directory" Then
			Dim Input As EditText = Controls.Get(Id)
			Input.TextColor = Theme.TextColor
		Else If TypeName = "switch" Or TypeName = "checkbox" Then
			Dim Check As CheckBox = Controls.Get(Id)
			Check.TextColor = Theme.TextColor
		Else If TypeName = "multichoice" Then
			Dim Checks As List = Controls.Get(Id)
			For Each CheckObject As Object In Checks
				Dim ItemCheck As CheckBox = CheckObject
				ItemCheck.TextColor = Theme.TextColor
			Next
		Else If TypeName = "choice" Then
			Dim Selector As Spinner = Controls.Get(Id)
			Selector.TextColor = Theme.TextColor
		End If
	Next
	For Each Id As String In SliderLabels.Keys
		Dim SliderValue As Label = SliderLabels.Get(Id)
		SliderValue.TextColor = Theme.TextColor
	Next
	For Each Id As String In ActionButtons.Keys
		Dim ActionButton As Button = ActionButtons.Get(Id)
		StyleSecondaryButton(ActionButton)
	Next
	For Each Id As String In BrowseButtons.Keys
		Dim BrowseButton As Button = BrowseButtons.Get(Id)
		StyleSecondaryButton(BrowseButton)
	Next
	For Each Id As String In ClearButtons.Keys
		Dim ClearButton As Button = ClearButtons.Get(Id)
		StyleSecondaryButton(ClearButton)
	Next
	StyleSecondaryButton(LanguageButton)
	StyleSecondaryButton(ThemeButton)
	StyleSecondaryButton(ResetButton)
	StyleSecondaryButton(CancelButton)
	StylePrimaryButton(SaveButton)
End Sub

Private Sub StyleSecondaryButton (B As Button)
	B.TextColor = Theme.SecondaryButtonTextColor
	Dim V As B4XView = B
	V.SetColorAndBorder(Theme.SecondaryButtonBackgroundColor, 0, 0, 4dip)
End Sub

Private Sub StylePrimaryButton (B As Button)
	B.TextColor = Theme.PrimaryButtonTextColor
	Dim V As B4XView = B
	V.SetColorAndBorder(Theme.AccentColor, 0, 0, 4dip)
End Sub

Private Sub RefreshFileButtons
	For Each ButtonId As String In BrowseButtons.Keys
		Dim BrowseButton As Button = BrowseButtons.Get(ButtonId)
		BrowseButton.Text = Localization.Text("ui.browse")
	Next
End Sub

Private Sub RefreshButtons
	SaveButton.Text = Localization.Text("ui.save")
	CancelButton.Text = Localization.Text("ui.cancel")
	ResetButton.Text = Localization.Text("ui.reset")
	LanguageButton.Text = Localization.Text("ui.language")
	ThemeButton.Text = Localization.Text("ui.theme")
End Sub

Private Sub prefsAction_Click
	Dim ActionButton As Button = Sender
	Dim PreferenceId As String = ActionButton.Tag
	CallSub2(Callback, EventPrefix & "_Action", PreferenceId)
End Sub

Private Sub prefsseek_ValueChanged(Value As Int, UserChanged As Boolean)
	Dim Bar As SeekBar = Sender
	Dim Id As String = Bar.Tag
	If SliderLabels.ContainsKey(Id) = False Then Return
	Dim Minimum As Double = SliderMin.Get(Id)
	Dim Maximum As Double = SliderMax.Get(Id)
	Dim Shown As Double = Minimum + (Maximum - Minimum) * (Value / 1000)
	Dim ValueLabel As Label = SliderLabels.Get(Id)
	ValueLabel.Text = Shown
End Sub

Private Sub prefsbrowse_Click
	Dim Source As Button = Sender
	Dim Id As String = Source.Tag
	Dim Pref As Map = Model.GetPreference(Id)
	If Pref.Get("type") = "directory" Then
		PendingDirId = Id
		CallSub2(Callback, EventPrefix & "_BrowseDirectory", Id)
		Return
	End If
	Dim Options As Map
	Options.Initialize
	If Pref.ContainsKey("options") Then Options = Pref.Get("options")
	PendingFileId = Id
	PendingCopy = False
	If Options.ContainsKey("copyToAppStorage") Then PendingCopy = Options.Get("copyToAppStorage")
	FilePicker.Show(MimeForOptions(Options), Localization.Text(Pref.Get("titleKey")))
End Sub

' Called by the host activity after an Android directory pick completes.
' Stores the tree URI in the pending field; Save commits it like any value.
Public Sub SetDirectoryValue(Uri As String)
	If PendingDirId = "" Then Return
	Dim Field As EditText = Controls.Get(PendingDirId)
	Field.Text = Uri
	PendingDirId = ""
End Sub

Private Sub prefscc_Result(Success As Boolean, Dir As String, FileName As String)
	If PendingFileId = "" Then Return
	Dim Id As String = PendingFileId
	PendingFileId = ""
	If Success = False Then Return
	Try
		Dim Stored As String = Dir
		If FileName <> "" Then Stored = File.Combine(Dir, FileName)
		If PendingCopy Then
			If File.Exists(File.DirInternal, "prefs-files") = False Then File.MakeDir(File.DirInternal, "prefs-files")
			Dim TargetDir As String = File.Combine(File.DirInternal, "prefs-files")
			Dim TargetName As String = TargetFileName(FileName, Id)
			Dim In As InputStream = File.OpenInput(Dir, FileName)
			Dim Out As OutputStream = File.OpenOutput(TargetDir, TargetName, False)
			File.Copy2(In, Out)
			In.Close
			Out.Close
			Stored = File.Combine(TargetDir, TargetName)
		End If
		Dim Field As EditText = Controls.Get(Id)
		Field.Text = Stored
		StatusLabel.Text = ""
	Catch
		Log("File copy failed: " & LastException.Message)
		SetStatus("Could not store the selected file.")
	End Try
End Sub

Private Sub TargetFileName(FileName As String, Id As String) As String
	Dim Name As String = FileName
	Dim Slash As Int = Name.LastIndexOf("/")
	If Slash > -1 Then Name = Name.SubString(Slash + 1)
	Name = Name.Replace(":", "_")
	If Name = "" Then Name = Id
	If Name.IndexOf(".") = -1 Then
		Dim Extension As String = FirstAllowedExtension(Id)
		If Extension <> "" Then
			Name = Name & "." & Extension
		Else
			Name = Name & ".bin"
		End If
	End If
	Return Name
End Sub

Private Sub FirstAllowedExtension(Id As String) As String
	Dim Pref As Map = Model.GetPreference(Id)
	If Pref.ContainsKey("options") = False Then Return ""
	Dim Options As Map = Pref.Get("options")
	If Options.ContainsKey("extensions") = False Then Return ""
	Dim Extensions As List = Options.Get("extensions")
	If Extensions.Size = 0 Then Return ""
	Dim First As String = Extensions.Get(0)
	Return First.ToLowerCase
End Sub

Private Sub MimeForOptions(Options As Map) As String
	If Options.ContainsKey("extensions") = False Then Return "*/*"
	Dim Extensions As List = Options.Get("extensions")
	If Extensions.Size = 0 Then Return "*/*"
	For Each ExtensionObject As Object In Extensions
		Dim Extension As String = ExtensionObject
		If IsImageExtension(Extension) = False Then Return "*/*"
	Next
	Return "image/*"
End Sub

Private Sub IsImageExtension(Extension As String) As Boolean
	Dim Lower As String = Extension.ToLowerCase
	Return Lower = "png" Or Lower = "jpg" Or Lower = "jpeg" Or Lower = "gif" Or Lower = "webp" Or Lower = "bmp"
End Sub

Private Sub CloseOverlay
	DisposeCustomHandles
	Dim Overlay As B4XView = OverlayPanel
	Overlay.RemoveViewFromParent
	CallSub2(Callback, EventPrefix & "_DialogClosed", Saved)
End Sub

Private Sub SliderToPosition(Value As Object, Minimum As Double, Maximum As Double) As Int
	Dim NumericValue As Double = Value
	If Maximum = Minimum Then Return 0
	Dim Position As Int = (NumericValue - Minimum) / (Maximum - Minimum) * 1000
	If Position < 0 Then Position = 0
	If Position > 1000 Then Position = 1000
	Return Position
End Sub
#End If
