B4J=true
Group=Classes
ModulesStructureVersion=1
Type=Class
Version=10.7
@EndOfDesignText@
' Embedded cross-platform preferences page. It builds itself into a caller-owned
' container and never clears the caller's other children.
'   B4J - a JavaFX ScrollPane mounted on an AnchorPane.
'   B4A - a ScrollView built over the caller's B4XView (Panel) with native controls.
'   B4i - not implemented yet; the shared call sites still compile.
' Save/Cancel/Reset commit or discard the controller draft; the host reloads the
' page after Save and Cancel (see the demo B4XMainPage).
Sub Class_Globals
	#If B4J
	Private fx As JFX
	Private Container As AnchorPane
	Private Scroll As ScrollPane
	Private Content As Pane
	#Else If B4A
	Private Container As B4XView
	Private Scroll As ScrollView
	Private Content As B4XView
	#End If
	Private Controller As PrefsController
	Private Model As PrefsModel
	Private Localization As PrefsLocalization
	#If B4J
	Private Theme As PrefsTheme
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
	#If B4A
	Private PendingDirId As String
	#End If
	Private ActionButtons As Map
	Private BrowseButtons As Map
	Private ClearButtons As Map
	Private PageTitle As Label
	Private StatusLabel As Label
	Private SaveButton As Button
	Private CancelButton As Button
	Private ResetButton As Button
	Private RowTop As Int
	Private ContentWidth As Int
	#If B4J
	Private InputLeft As Int
	#End If
	Private IsDisposed As Boolean
End Sub

' TargetContainer is a B4XView so the page API stays platform-neutral; the
' layout underneath requires an AnchorPane on B4J and any panel on B4A.
Public Sub Initialize(TargetContainer As B4XView, ValueController As PrefsController, Definition As PrefsModel, L10n As PrefsLocalization, UiTheme As PrefsTheme, Provider As PrefsFileProvider, Renderers As Map, Target As Object, TargetEvent As String)
	Controller = ValueController
	Model = Definition
	Localization = L10n
	#If B4J
	Theme = UiTheme
	FileProvider = Provider
	#End If
	CustomRenderers = Renderers
	Callback = Target
	EventPrefix = TargetEvent
	IsDisposed = False
	Controller.BeginDraft
	#If B4J Or B4A
	Container = TargetContainer
	BuildPage
	#End If
End Sub

#If B4J
Private Sub BuildPage
	InitMaps
	RowTop = 18
	Content.Initialize("page")
	Content.StyleClasses.Add("prefs-surface")
	Content.PrefWidth = Max(740, Container.Width - 24)
	ContentWidth = Content.PrefWidth
	InputLeft = 240
	Scroll.Initialize("page")
	Scroll.StyleClasses.Add("prefs-surface")
	Scroll.FitToWidth = True
	Scroll.InnerNode = Content
	Scroll.Style = "-fx-background-color: transparent; -fx-background: transparent;"
	Container.AddNode(Scroll, 0, 0, -1, -1)
	Container.SetAnchors(Scroll, 0, 0, 0, 0)
	PageTitle.Initialize("")
	PageTitle.Text = Localization.Text(Model.GetTitleKey)
	PageTitle.TextColor = fx.Colors.From32Bit(Theme.TextColor)
	Content.AddNode(PageTitle, 24, RowTop, ContentWidth - 48, 34)
	RowTop = RowTop + 44
	For Each Section As Map In Model.GetSections
		Dim SectionTitle As Label
		SectionTitle.Initialize("")
		SectionTitle.Text = Localization.Text(Section.Get("titleKey"))
		SectionTitle.TextColor = fx.Colors.From32Bit(Theme.SecondaryTextColor)
		Content.AddNode(SectionTitle, 24, RowTop, ContentWidth - 48, 28)
		SectionLabels.Put(Section.Get("id"), SectionTitle)
		RowTop = RowTop + Theme.SectionSpacing + 10
		Dim Preferences As List = Section.Get("preferences")
		For Each Pref As Map In Preferences
			AddPreference(Pref)
		Next
		RowTop = RowTop + 8
	Next
	StatusLabel.Initialize("")
	StatusLabel.TextColor = fx.Colors.From32Bit(Theme.SecondaryTextColor)
	Content.AddNode(StatusLabel, 34, RowTop, ContentWidth - 30, 26)
	RowTop = RowTop + 34
	ResetButton.Initialize("pageReset")
	Content.AddNode(ResetButton, InputLeft, RowTop, 90, 36)
	CancelButton.Initialize("pageCancel")
	Content.AddNode(CancelButton, InputLeft + 110, RowTop, 90, 36)
	SaveButton.Initialize("pageSave")
	Content.AddNode(SaveButton, InputLeft + 220, RowTop, 110, 36)
	RowTop = RowTop + 52
	Content.PrefHeight = RowTop
	RefreshTheme
	RefreshLocalization
	If BuildError <> "" Then
		StatusLabel.Text = BuildError
		StatusLabel.TextColor = fx.Colors.From32Bit(Theme.ErrorTextColor)
	End If
End Sub
#End If

#If B4A
Private Sub BuildPage
	InitMaps
	RowTop = 12dip
	Dim W As Int = Container.Width
	Dim H As Int = Container.Height
	If W <= 0 Then W = 100%x
	If H <= 0 Then H = 100%y
	ContentWidth = W
	Scroll.Initialize(W)
	Container.AddView(Scroll, 0, 0, W, H)
	Content = Scroll.Panel
	Content.Color = Colors.White
	PageTitle.Initialize("")
	PageTitle.Text = Localization.Text(Model.GetTitleKey)
	PageTitle.TextSize = 22
	PageTitle.TextColor = Colors.DarkGray
	Content.AddView(PageTitle, 16dip, RowTop, W - 32dip, 44dip)
	RowTop = RowTop + 56dip
	For Each SectionObject As Object In Model.GetSections
		Dim SectionMap As Map = SectionObject
		Dim SectionTitle As Label
		SectionTitle.Initialize("")
		SectionTitle.Text = Localization.Text(SectionMap.Get("titleKey"))
		SectionTitle.TextSize = 16
		SectionTitle.TextColor = Colors.Gray
		Content.AddView(SectionTitle, 16dip, RowTop, W - 32dip, 30dip)
		SectionLabels.Put(SectionMap.Get("id"), SectionTitle)
		RowTop = RowTop + 38dip
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
	StatusLabel.TextColor = Colors.Red
	Content.AddView(StatusLabel, 16dip, RowTop, W - 32dip, 30dip)
	RowTop = RowTop + 38dip
	SaveButton.Initialize("pageSave")
	SaveButton.Text = Localization.Text("ui.save")
	SaveButton.TextSize = 16
	Content.AddView(SaveButton, 16dip, RowTop, (W - 40dip) / 2, 52dip)
	CancelButton.Initialize("pageCancel")
	CancelButton.Text = Localization.Text("ui.cancel")
	CancelButton.TextSize = 16
	Content.AddView(CancelButton, 24dip + (W - 40dip) / 2, RowTop, (W - 40dip) / 2, 52dip)
	RowTop = RowTop + 64dip
	ResetButton.Initialize("pageReset")
	ResetButton.Text = Localization.Text("ui.reset")
	ResetButton.TextSize = 16
	Content.AddView(ResetButton, 16dip, RowTop, W - 32dip, 48dip)
	RowTop = RowTop + 60dip
	Content.Height = RowTop
	If BuildError <> "" Then
		StatusLabel.Text = BuildError
	End If
End Sub
#End If

Private Sub InitMaps
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
End Sub

Private Sub AddPreference(Pref As Map)
	Dim Id As String = Pref.Get("id")
	Dim TypeName As String = Pref.Get("type")
	#If B4J
	If TypeName = "label" Then
		Dim InfoLabel As Label
		InfoLabel.Initialize("")
		Dim InfoKey As String = Pref.Get("titleKey")
		If Pref.ContainsKey("descriptionKey") Then InfoKey = Pref.Get("descriptionKey")
		InfoLabel.Text = Localization.Text(InfoKey)
		Content.AddNode(InfoLabel, 34, RowTop + 4, ContentWidth - 60, 30)
		TitleLabels.Put(Id, InfoLabel)
	Else If TypeName = "action" Then
		Dim ActionButton As Button
		ActionButton.Initialize("pageAction")
		ActionButton.Tag = Id
		ActionButton.Text = Localization.Text(Pref.Get("titleKey"))
		Content.AddNode(ActionButton, InputLeft, RowTop, 260, 36)
		ActionButtons.Put(Id, ActionButton)
	Else If TypeName = "switch" Or TypeName = "checkbox" Then
		Dim Check As CheckBox
		Check.Initialize("page")
		Check.Tag = Id
		Check.Checked = Controller.GetValue(Id)
		Content.AddNode(Check, 34, RowTop, ContentWidth - 80, 36)
		Controls.Put(Id, Check)
		TitleLabels.Put(Id, Check)
	Else
		Dim Title As Label
		Title.Initialize("")
		Content.AddNode(Title, 34, RowTop + 4, 240, 30)
		TitleLabels.Put(Id, Title)
		If TypeName = "text" Or TypeName = "number" Or TypeName = "password" Or TypeName = "time" Or TypeName = "datetime" Then
			Dim Input As TextField
			If TypeName = "password" Then
				Input.InitializePassword("page")
			Else
				Input.Initialize("page")
			End If
			Input.Tag = Id
			Input.Text = "" & Controller.GetValue(Id)
			If TypeName = "time" Then Input.PromptText = Localization.Text("format.time")
			If TypeName = "datetime" Then Input.PromptText = Localization.Text("format.datetime")
			Content.AddNode(Input, InputLeft, RowTop, ContentWidth - 40 - InputLeft, 36)
			Controls.Put(Id, Input)
		Else If TypeName = "multiline" Then
			Dim MultilineInput As TextArea
			MultilineInput.Initialize("page")
			MultilineInput.Tag = Id
			MultilineInput.Text = "" & Controller.GetValue(Id)
			MultilineInput.WrapText = True
			Content.AddNode(MultilineInput, InputLeft, RowTop, ContentWidth - 40 - InputLeft, 76)
			Controls.Put(Id, MultilineInput)
			RowTop = RowTop + 50
		Else If TypeName = "multichoice" Then
			Dim Multi As ListView
			Multi.Initialize("")
			Multi.MultipleSelection = True
			Multi.Tag = Id
			Dim MultiOptions As Map = Pref.Get("options")
			Dim MultiItems As List = MultiOptions.Get("items")
			Dim SelectedValues As List = Controller.GetValue(Id)
			Dim SelectedIndices As List
			SelectedIndices.Initialize
			For I = 0 To MultiItems.Size - 1
				Dim MultiItem As Map = MultiItems.Get(I)
				Multi.Items.Add(Localization.Text(MultiItem.Get("titleKey")))
				Dim MultiValue As String = MultiItem.Get("value")
				For Each SelectedObject As Object In SelectedValues
					Dim SelectedValue As String = SelectedObject
					If MultiValue = SelectedValue Then SelectedIndices.Add(I)
				Next
			Next
			Multi.SetSelectedIndices(SelectedIndices)
			Content.AddNode(Multi, InputLeft, RowTop, ContentWidth - 40 - InputLeft, 90)
			Controls.Put(Id, Multi)
			RowTop = RowTop + 56
		Else If TypeName = "date" Then
			Dim DateInput As DatePicker
			DateInput.Initialize("")
			DateInput.DateFormat = "yyyy-MM-dd"
			DateInput.DateTicks = IsoToTicks(Controller.GetValue(Id))
			Content.AddNode(DateInput, InputLeft, RowTop, 260, 36)
			Controls.Put(Id, DateInput)
		Else If TypeName = "slider" Then
			Dim ValueSlider As Slider
			ValueSlider.Initialize("page")
			ValueSlider.Tag = Id
			Dim SliderOptions As Map
			SliderOptions.Initialize
			If Pref.ContainsKey("options") Then SliderOptions = Pref.Get("options")
			If SliderOptions.ContainsKey("min") Then ValueSlider.MinValue = SliderOptions.Get("min") Else ValueSlider.MinValue = 0
			If SliderOptions.ContainsKey("max") Then ValueSlider.MaxValue = SliderOptions.Get("max") Else ValueSlider.MaxValue = 100
			Dim SliderValueLabel As Label
			SliderValueLabel.Initialize("")
			Content.AddNode(SliderValueLabel, InputLeft + 390, RowTop + 4, 70, 28)
			SliderLabels.Put(Id, SliderValueLabel)
			ValueSlider.Value = Controller.GetValue(Id)
			SliderValueLabel.Text = "" & ValueSlider.Value
			Content.AddNode(ValueSlider, InputLeft, RowTop, 380, 36)
			Controls.Put(Id, ValueSlider)
		Else If TypeName = "choice" Then
			Dim Choice As ComboBox
			Choice.Initialize("page")
			Choice.Tag = Id
			Dim Options As Map = Pref.Get("options")
			Dim Items As List = Options.Get("items")
			Dim SelectedIndex As Int = -1
			For I = 0 To Items.Size - 1
				Dim Item As Map = Items.Get(I)
				Choice.Items.Add(Localization.Text(Item.Get("titleKey")))
				Dim ItemValue As String = Item.Get("value")
				Dim CurrentValue As String = Controller.GetValue(Id)
				If ItemValue = CurrentValue Then SelectedIndex = I
			Next
			Choice.SelectedIndex = SelectedIndex
			Content.AddNode(Choice, InputLeft, RowTop, ContentWidth - 40 - InputLeft, 36)
			Controls.Put(Id, Choice)
		Else If TypeName = "file" Or TypeName = "directory" Then
			Dim PathField As TextField
			PathField.Initialize("page")
			PathField.Tag = Id
			PathField.Text = "" & Controller.GetValue(Id)
			Content.AddNode(PathField, InputLeft, RowTop, ContentWidth - 40 - InputLeft - 184, 36)
			Controls.Put(Id, PathField)
			Dim BrowseButton As Button
			BrowseButton.Initialize("pageBrowse")
			BrowseButton.Tag = Id
			BrowseButton.Text = Localization.Text("ui.browse")
			Content.AddNode(BrowseButton, ContentWidth - 40 - 176, RowTop, 84, 36)
			BrowseButtons.Put(Id, BrowseButton)
			If HasAllowClear(Pref) Then
				Dim ClearButton As Button
				ClearButton.Initialize("pageClear")
				ClearButton.Tag = Id
				ClearButton.Text = Localization.Text("ui.clear")
				Content.AddNode(ClearButton, ContentWidth - 40 - 84, RowTop, 84, 36)
				ClearButtons.Put(Id, ClearButton)
			End If
		Else If TypeName = "custom" Then
			AddCustomPreference(Pref)
		End If
	End If
	#Else If B4A
	Dim InnerWidth As Int = ContentWidth - 32dip
	If TypeName = "label" Then
		Dim InfoKey As String = Pref.Get("titleKey")
		If Pref.ContainsKey("descriptionKey") Then InfoKey = Pref.Get("descriptionKey")
		Dim InfoLabel As Label
		InfoLabel.Initialize("")
		InfoLabel.Text = Localization.Text(InfoKey)
		InfoLabel.TextSize = 14
		InfoLabel.TextColor = Colors.Gray
		Content.AddView(InfoLabel, 16dip, RowTop, InnerWidth, 30dip)
		TitleLabels.Put(Id, InfoLabel)
		RowTop = RowTop + 38dip
	Else If TypeName = "action" Then
		Dim ActionButton As Button
		ActionButton.Initialize("pageAction")
		ActionButton.Tag = Id
		ActionButton.Text = Localization.Text(Pref.Get("titleKey"))
		ActionButton.TextSize = 16
		Content.AddView(ActionButton, 16dip, RowTop, InnerWidth, 52dip)
		ActionButtons.Put(Id, ActionButton)
		RowTop = RowTop + 60dip
	Else If TypeName = "switch" Or TypeName = "checkbox" Then
		Dim Check As CheckBox
		Check.Initialize("")
		Check.Text = Localization.Text(Pref.Get("titleKey"))
		Check.TextSize = 16
		Check.Checked = Controller.GetValue(Id)
		Content.AddView(Check, 16dip, RowTop, InnerWidth, 52dip)
		Controls.Put(Id, Check)
		TitleLabels.Put(Id, Check)
		RowTop = RowTop + 60dip
	Else
		Dim Title As Label
		Title.Initialize("")
		Title.Text = Localization.Text(Pref.Get("titleKey"))
		Title.TextSize = 16
		Content.AddView(Title, 16dip, RowTop, InnerWidth, 26dip)
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
			Content.AddView(Input, 16dip, RowTop, InnerWidth, 52dip)
			Controls.Put(Id, Input)
			RowTop = RowTop + 60dip
		Else If TypeName = "multiline" Then
			Dim MultilineInput As EditText
			MultilineInput.Initialize("")
			MultilineInput.TextSize = 16
			MultilineInput.SingleLine = False
			MultilineInput.Text = "" & Controller.GetValue(Id)
			Content.AddView(MultilineInput, 16dip, RowTop, InnerWidth, 120dip)
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
				Content.AddView(Box, 16dip, RowTop, InnerWidth, 44dip)
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
			Content.AddView(DateInput, 16dip, RowTop, InnerWidth, 52dip)
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
			Content.AddView(Selector, 16dip, RowTop, InnerWidth, 52dip)
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
			Bar.Initialize("pageSeek")
			Bar.Tag = Id
			Bar.Max = 1000
			Bar.Value = SliderToPosition(Controller.GetValue(Id), Minimum, Maximum)
			Content.AddView(Bar, 16dip, RowTop, InnerWidth - 80dip, 52dip)
			Dim ValueLabel As Label
			ValueLabel.Initialize("")
			ValueLabel.TextSize = 14
			ValueLabel.Text = Controller.GetValue(Id)
			Content.AddView(ValueLabel, 16dip + InnerWidth - 74dip, RowTop + 12dip, 70dip, 28dip)
			SliderLabels.Put(Id, ValueLabel)
			Controls.Put(Id, Bar)
			RowTop = RowTop + 60dip
		Else If TypeName = "file" Or TypeName = "directory" Then
			Dim PathField As EditText
			PathField.Initialize("")
			PathField.TextSize = 14
			PathField.SingleLine = True
			PathField.Text = "" & Controller.GetValue(Id)
			Content.AddView(PathField, 16dip, RowTop, InnerWidth - 130dip, 52dip)
			Controls.Put(Id, PathField)
			Dim BrowseButton As Button
			BrowseButton.Initialize("pageBrowse")
			BrowseButton.Tag = Id
			BrowseButton.Text = Localization.Text("ui.browse")
			BrowseButton.TextSize = 16
			Content.AddView(BrowseButton, 16dip + InnerWidth - 120dip, RowTop, 120dip, 52dip)
			BrowseButtons.Put(Id, BrowseButton)
			RowTop = RowTop + 60dip
		Else If TypeName = "custom" Then
			AddCustomPreference(Pref)
		End If
	End If
	#End If
	ControlTypes.Put(Id, TypeName)
	#If B4J
	RowTop = RowTop + Theme.RowSpacing + 32
	#End If
End Sub

' Builds a custom preference through its registered renderer. See PrefsDialog
' for the lifecycle contract; behavior here is identical.
Private Sub AddCustomPreference(Pref As Map)
	Dim Id As String = Pref.Get("id")
	Dim Entry As Map = CustomEntry(Pref)
	If Entry = Null Then
		BuildError = "No custom renderer registered for preference " & Id
		#If B4J Or B4A
		Log(BuildError)
		#End If
		Dim ErrorLabel As Label
		ErrorLabel.Initialize("")
		ErrorLabel.Text = BuildError
		#If B4J
		ErrorLabel.TextColor = fx.Colors.From32Bit(Theme.ErrorTextColor)
		Content.AddNode(ErrorLabel, InputLeft, RowTop, ContentWidth - 40 - InputLeft, 34)
		#Else If B4A
		ErrorLabel.TextSize = 14
		ErrorLabel.TextColor = Colors.Red
		Content.AddView(ErrorLabel, 16dip, RowTop, ContentWidth - 32dip, 52dip)
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
	Args.Put("parent", Content)
	Args.Put("left", InputLeft)
	Args.Put("top", RowTop)
	Args.Put("width", ContentWidth - 40 - InputLeft)
	#Else If B4A
	Args.Put("parent", Content)
	Args.Put("left", 16dip)
	Args.Put("top", RowTop)
	Args.Put("width", ContentWidth - 32dip)
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

#If B4J
Private Sub pageBrowse_Click
	Dim BrowseButton As Button = Sender
	BrowseFile(BrowseButton.Tag)
End Sub

Private Sub pageClear_Click
	Dim ClearButton As Button = Sender
	ClearFile(ClearButton.Tag)
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
#End If

#If B4A
Private Sub pageBrowse_Click
	Dim BrowseButton As Button = Sender
	Dim Id As String = BrowseButton.Tag
	PendingDirId = Id
	CallSub2(Callback, EventPrefix & "_BrowseDirectory", Id)
End Sub

' Called by the host after a directory pick completes.
Public Sub SetDirectoryValue(Uri As String)
	If PendingDirId = "" Then Return
	Dim Field As EditText = Controls.Get(PendingDirId)
	Field.Text = Uri
	PendingDirId = ""
End Sub
#End If

Public Sub RefreshValues
	If IsDisposed Then Return
	Controller.CancelDraft
	Controller.BeginDraft
	For Each Id As String In Controls.Keys
		UpdateControl(Id, Controller.GetValue(Id))
	Next
	#If B4J Or B4A
	StatusLabel.Text = ""
	#End If
End Sub

Public Sub RefreshValue(Id As String, Value As Object)
	If IsDisposed Or Controls.ContainsKey(Id) = False Then Return
	UpdateControl(Id, Value)
End Sub

Private Sub UpdateControl(Id As String, Value As Object)
	Dim TypeName As String = ControlTypes.Get(Id)
	#If B4J
	Select TypeName
		Case "text", "number", "password", "time", "datetime", "file", "directory"
			Dim Input As TextField = Controls.Get(Id)
			Input.Text = "" & Value
		Case "multiline"
			Dim MultilineInput As TextArea = Controls.Get(Id)
			MultilineInput.Text = "" & Value
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
		Case "date"
			Dim DateInput As DatePicker = Controls.Get(Id)
			DateInput.DateTicks = IsoToTicks(Value)
		Case "slider"
			Dim ValueSlider As Slider = Controls.Get(Id)
			ValueSlider.Value = Value
			Dim SliderValueLabel As Label = SliderLabels.Get(Id)
			SliderValueLabel.Text = "" & ValueSlider.Value
		Case "switch", "checkbox"
			Dim Check As CheckBox = Controls.Get(Id)
			Check.Checked = Value
		Case "custom"
			RefreshCustom(Id, Value)
		Case "choice"
			Dim Choice As ComboBox = Controls.Get(Id)
			Dim Pref As Map = Model.GetPreference(Id)
			Dim Options As Map = Pref.Get("options")
			Dim Items As List = Options.Get("items")
			For I = 0 To Items.Size - 1
				Dim Item As Map = Items.Get(I)
				Dim ItemValue As String = Item.Get("value")
				Dim SelectedValue As String = Value
				If ItemValue = SelectedValue Then Choice.SelectedIndex = I
			Next
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

Public Sub RefreshLocalization
	If IsDisposed Then Return
	#If B4J Or B4A
	PageTitle.Text = Localization.Text(Model.GetTitleKey)
	For Each Section As Map In Model.GetSections
		Dim SectionTitle As Label = SectionLabels.Get(Section.Get("id"))
		SectionTitle.Text = Localization.Text(Section.Get("titleKey"))
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
			#If B4J
			Else If Pref.Get("type") = "choice" Then
				Dim Choice As ComboBox = Controls.Get(Id)
				Dim SelectedIndex As Int = Choice.SelectedIndex
				Choice.Items.Clear
				Dim Options As Map = Pref.Get("options")
				Dim Items As List = Options.Get("items")
				For Each Item As Map In Items
					Choice.Items.Add(Localization.Text(Item.Get("titleKey")))
				Next
				Choice.SelectedIndex = SelectedIndex
			Else If Pref.Get("type") = "multichoice" Then
				Dim Multi As ListView = Controls.Get(Id)
				Dim SelectedIndices As List = Multi.GetSelectedIndices
				Multi.Items.Clear
				Dim MultiOptions As Map = Pref.Get("options")
				Dim MultiItems As List = MultiOptions.Get("items")
				For Each Item As Map In MultiItems
					Multi.Items.Add(Localization.Text(Item.Get("titleKey")))
				Next
				Multi.SetSelectedIndices(SelectedIndices)
			#Else If B4A
			Else If Pref.Get("type") = "choice" Then
				Dim Selector As Spinner = Controls.Get(Id)
				Dim SelectedIndex As Int = Selector.SelectedIndex
				Selector.Clear
				Dim ChoiceOptions As Map = Pref.Get("options")
				Dim ChoiceItems As List = ChoiceOptions.Get("items")
				For Each Item As Map In ChoiceItems
					Selector.Add(Localization.Text(Item.Get("titleKey")))
				Next
				Selector.SelectedIndex = SelectedIndex
			#End If
			End If
		Next
	Next
	SaveButton.Text = Localization.Text("ui.save")
	CancelButton.Text = Localization.Text("ui.cancel")
	ResetButton.Text = Localization.Text("ui.reset")
	For Each ButtonId As String In BrowseButtons.Keys
		Dim BrowseButton As Button = BrowseButtons.Get(ButtonId)
		BrowseButton.Text = Localization.Text("ui.browse")
	Next
	#If B4J
	For Each ButtonId As String In ClearButtons.Keys
		Dim ClearButton As Button = ClearButtons.Get(ButtonId)
		ClearButton.Text = Localization.Text("ui.clear")
	Next
	#End If
	#End If
End Sub

Public Sub RefreshTheme
	If IsDisposed Then Return
	#If B4J
	ApplyTheme
	For Each Id As String In TitleLabels.Keys
		If ControlTypes.Get(Id) = "switch" Or ControlTypes.Get(Id) = "checkbox" Then
			Dim Check As CheckBox = Controls.Get(Id)
			Check.TextColor = fx.Colors.From32Bit(Theme.TextColor)
			Check.Style = CheckCss
		Else
			Dim Title As Label = TitleLabels.Get(Id)
			Title.TextColor = fx.Colors.From32Bit(Theme.TextColor)
		End If
	Next
	For Each Id As String In SectionLabels.Keys
		Dim SectionTitle As Label = SectionLabels.Get(Id)
		SectionTitle.TextColor = fx.Colors.From32Bit(Theme.SecondaryTextColor)
	Next
	For Each Id As String In Controls.Keys
		If ControlTypes.Get(Id) = "text" Or ControlTypes.Get(Id) = "number" Or ControlTypes.Get(Id) = "password" Or ControlTypes.Get(Id) = "time" Or ControlTypes.Get(Id) = "datetime" Then
			Dim Input As TextField = Controls.Get(Id)
			Input.Style = InputCss
		Else If ControlTypes.Get(Id) = "file" Or ControlTypes.Get(Id) = "directory" Then
			Dim PathField As TextField = Controls.Get(Id)
			PathField.Style = InputCss
		Else If ControlTypes.Get(Id) = "multiline" Then
			Dim MultilineInput As TextArea = Controls.Get(Id)
			MultilineInput.Style = InputCss
		Else If ControlTypes.Get(Id) = "choice" Then
			Dim Choice As ComboBox = Controls.Get(Id)
			Choice.Style = InputCss
		Else If ControlTypes.Get(Id) = "multichoice" Then
			Dim Multi As ListView = Controls.Get(Id)
			Multi.Style = InputCss
		Else If ControlTypes.Get(Id) = "date" Then
			Dim DateInput As DatePicker = Controls.Get(Id)
			DateInput.Style = InputCss
		Else If ControlTypes.Get(Id) = "slider" Then
			Dim ValueSlider As Slider = Controls.Get(Id)
			ValueSlider.Style = "-fx-accent: " & ColorCss(Theme.AccentColor) & ";"
			Dim SliderValueLabel As Label = SliderLabels.Get(Id)
			SliderValueLabel.TextColor = fx.Colors.From32Bit(Theme.TextColor)
		Else If ControlTypes.Get(Id) = "custom" Then
			RefreshCustom(Id, ReadCustom(Id))
		End If
	Next
	For Each Id As String In ActionButtons.Keys
		Dim ActionButton As Button = ActionButtons.Get(Id)
		ActionButton.Style = "-fx-background-color: " & ColorCss(Theme.AccentColor) & "; -fx-text-fill: " & ColorCss(Theme.PrimaryButtonTextColor) & ";"
	Next
	ApplyButtonStyles
	#Else If B4A
	For Each Id As String In Controls.Keys
		If ControlTypes.Get(Id) = "custom" Then RefreshCustom(Id, ReadCustom(Id))
	Next
	#End If
End Sub

Public Sub SetTheme(Value As PrefsTheme)
	#If B4J
	Theme = Value
	RefreshTheme
	#End If
End Sub

#If B4J
Private Sub ApplyTheme
	Content.Style = "-fx-background-color: " & ColorCss(Theme.BackgroundColor) & "; -prefs-input-bg: " & ColorCss(Theme.InputBackgroundColor) & "; -prefs-input-text: " & ColorCss(Theme.TextColor) & "; -prefs-input-border: " & ColorCss(Theme.InputBorderColor) & "; -prefs-accent: " & ColorCss(Theme.AccentColor) & "; -prefs-checkmark-text: " & ColorCss(Theme.PrimaryButtonTextColor) & ";"
	Scroll.Style = "-fx-background-color: " & ColorCss(Theme.BackgroundColor) & "; -fx-background: " & ColorCss(Theme.BackgroundColor) & "; -prefs-input-bg: " & ColorCss(Theme.InputBackgroundColor) & "; -prefs-input-text: " & ColorCss(Theme.TextColor) & "; -prefs-input-border: " & ColorCss(Theme.InputBorderColor) & "; -prefs-accent: " & ColorCss(Theme.AccentColor) & "; -prefs-checkmark-text: " & ColorCss(Theme.PrimaryButtonTextColor) & ";"
	PageTitle.TextColor = fx.Colors.From32Bit(Theme.TextColor)
	StatusLabel.TextColor = fx.Colors.From32Bit(Theme.SecondaryTextColor)
	ApplyButtonStyles
End Sub

Private Sub ApplyButtonStyles
	SaveButton.TextColor = fx.Colors.From32Bit(Theme.PrimaryButtonTextColor)
	SaveButton.Style = "-fx-background-color: " & ColorCss(Theme.AccentColor) & "; -fx-text-fill: " & ColorCss(Theme.PrimaryButtonTextColor) & "; -fx-font-weight: bold; -fx-background-radius: 4;"
	CancelButton.TextColor = fx.Colors.From32Bit(Theme.SecondaryButtonTextColor)
	CancelButton.Style = "-fx-background-color: " & ColorCss(Theme.SecondaryButtonBackgroundColor) & "; -fx-text-fill: " & ColorCss(Theme.SecondaryButtonTextColor) & "; -fx-background-radius: 4;"
	ResetButton.TextColor = fx.Colors.From32Bit(Theme.SecondaryButtonTextColor)
	ResetButton.Style = "-fx-background-color: " & ColorCss(Theme.SecondaryButtonBackgroundColor) & "; -fx-text-fill: " & ColorCss(Theme.SecondaryButtonTextColor) & "; -fx-background-radius: 4;"
	Dim SecondaryStyle As String = "-fx-background-color: " & ColorCss(Theme.SecondaryButtonBackgroundColor) & "; -fx-text-fill: " & ColorCss(Theme.SecondaryButtonTextColor) & "; -fx-background-radius: 4;"
	For Each ButtonId As String In BrowseButtons.Keys
		Dim BrowseButton As Button = BrowseButtons.Get(ButtonId)
		BrowseButton.Style = SecondaryStyle
	Next
	For Each ButtonId As String In ClearButtons.Keys
		Dim ClearButton As Button = ClearButtons.Get(ButtonId)
		ClearButton.Style = SecondaryStyle
	Next
End Sub

Private Sub InputCss As String
	Return "-fx-control-inner-background: " & ColorCss(Theme.InputBackgroundColor) & "; -fx-background-color: " & ColorCss(Theme.InputBackgroundColor) & "; -fx-text-fill: " & ColorCss(Theme.TextColor) & "; -fx-prompt-text-fill: " & ColorCss(Theme.SecondaryTextColor) & "; -fx-accent: " & ColorCss(Theme.AccentColor) & "; -fx-focus-color: " & ColorCss(Theme.AccentColor) & "; -fx-border-color: " & ColorCss(Theme.InputBorderColor) & "; -fx-border-radius: 4; -fx-background-radius: 4;"
End Sub

Private Sub CheckCss As String
	Return "-fx-text-fill: " & ColorCss(Theme.TextColor) & "; -fx-accent: " & ColorCss(Theme.AccentColor) & "; -fx-focus-color: " & ColorCss(Theme.AccentColor) & ";"
End Sub

Private Sub ColorCss(Color As Int) As String
	Dim R As Int = Bit.And(Bit.ShiftRight(Color, 16), 255)
	Dim G As Int = Bit.And(Bit.ShiftRight(Color, 8), 255)
	Dim B As Int = Bit.And(Color, 255)
	Return "rgb(" & R & "," & G & "," & B & ")"
End Sub
#End If

#If B4J
Private Sub pageSave_Click
	Save_Click
End Sub

Private Sub pageCancel_Click
	Cancel_Click
End Sub
#End If

#If B4A
Private Sub pageSave_Click
	If SaveDraft Then StatusLabel.Text = Localization.Text("ui.saved")
End Sub

Private Sub pageCancel_Click
	CancelDraft
	StatusLabel.Text = Localization.Text("ui.cancelled")
End Sub
#End If

Private Sub pageReset_Click
	ResetDraft
End Sub

#If B4A
Private Sub pageSeek_ValueChanged(Value As Int, UserChanged As Boolean)
	Dim Bar As SeekBar = Sender
	Dim Id As String = Bar.Tag
	If SliderLabels.ContainsKey(Id) = False Then Return
	Dim Minimum As Double = SliderMin.Get(Id)
	Dim Maximum As Double = SliderMax.Get(Id)
	Dim Shown As Double = Minimum + (Maximum - Minimum) * (Value / 1000)
	Dim ValueLabel As Label = SliderLabels.Get(Id)
	ValueLabel.Text = Shown
End Sub
#End If

Private Sub pageAction_Click
	Dim ActionButton As Button = Sender
	Dim PreferenceId As String = ActionButton.Tag
	CallSub2(Callback, EventPrefix & "_Action", PreferenceId)
End Sub

#If B4J
Private Sub page_Click
	' Preference controls use this event name but are read when Save is pressed.
End Sub

Private Sub page_ValueChange(Value As Double)
	Dim ValueSlider As Slider = Sender
	Dim Id As String = ValueSlider.Tag
	If SliderLabels.ContainsKey(Id) = False Then Return
	Dim SliderValueLabel As Label = SliderLabels.Get(Id)
	SliderValueLabel.Text = "" & Value
End Sub
#End If

#If B4J
Private Sub Save_Click
	If SaveDraft Then
		StatusLabel.Text = Localization.Text("ui.saved")
		StatusLabel.TextColor = fx.Colors.From32Bit(Theme.SecondaryTextColor)
	End If
End Sub

Private Sub Cancel_Click
	CancelDraft
	StatusLabel.Text = Localization.Text("ui.cancelled")
	StatusLabel.TextColor = fx.Colors.From32Bit(Theme.SecondaryTextColor)
End Sub
#End If

Private Sub ResetDraft
	Controller.ResetDraftToDefaults
	For Each Id As String In Controls.Keys
		UpdateControl(Id, Controller.GetDraftValues.Get(Id))
	Next
	#If B4J Or B4A
	StatusLabel.Text = Localization.Text("ui.reset_done")
	#End If
	#If B4J
	StatusLabel.TextColor = fx.Colors.From32Bit(Theme.SecondaryTextColor)
	#End If
End Sub

Private Sub CancelDraft
	Controller.CancelDraft
	Controller.BeginDraft
	For Each Id As String In Controls.Keys
		UpdateControl(Id, Controller.GetValue(Id))
	Next
End Sub

' Reads every control into the draft, validates and commits on success.
Private Sub SaveDraft As Boolean
	If BuildError <> "" Then
		#If B4J Or B4A
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
			Case "switch", "checkbox"
				Dim Check As CheckBox = Controls.Get(Id)
				Value = Check.Checked
			Case "choice"
				Dim Choice As ComboBox = Controls.Get(Id)
				If Choice.SelectedIndex < 0 Then
					StatusLabel.Text = Localization.Text("validation.choice") & " (" & Id & ")"
					Return False
				End If
				Dim Pref As Map = Model.GetPreference(Id)
				Dim Options As Map = Pref.Get("options")
				Dim Items As List = Options.Get("items")
				Dim SelectedItem As Map = Items.Get(Choice.SelectedIndex)
				Value = SelectedItem.Get("value")
			Case "custom"
				Value = ReadCustom(Id)
				Dim CustomPref As Map = Model.GetPreference(Id)
				Dim Entry As Map = CustomEntry(CustomPref)
				Dim ValidationError As String = CallSub3(Entry.Get("target"), Entry.Get("event") & "_Validate", Value, CustomPref)
				If ValidationError <> "" Then
					StatusLabel.Text = ValidationError & " (" & Id & ")"
					Return False
				End If
		End Select
		#Else If B4A
		Select TypeName
			Case "text", "multiline", "password", "number", "date", "time", "datetime"
				Dim Input As EditText = Controls.Get(Id)
				If TypeName = "number" Then
					If IsNumber(Input.Text) = False Then
						StatusLabel.Text = Localization.Text("validation.number") & " (" & Id & ")"
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
					StatusLabel.Text = Localization.Text("validation.choice") & " (" & Id & ")"
					Return False
				End If
				Dim Pref As Map = Model.GetPreference(Id)
				Dim Options As Map = Pref.Get("options")
				Dim Items As List = Options.Get("items")
				Dim SelectedItem As Map = Items.Get(Selector.SelectedIndex)
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
					StatusLabel.Text = ValidationError & " (" & Id & ")"
					Return False
				End If
		End Select
		#End If
		If Controller.SetDraftValue(Id, Value) = False Then
			#If B4J Or B4A
			StatusLabel.Text = Controller.LastError
			#End If
			Return False
		End If
	Next
	Dim Validation As String = Controller.ValidateDraft
	If Validation <> "" Then
		#If B4J Or B4A
		StatusLabel.Text = Validation
		#End If
		Return False
	End If
	If CallSub2(Callback, EventPrefix & "_BeforeSave", Controller.GetDraftValues) = False Then Return False
	Controller.CommitDraft
	CallSub2(Callback, EventPrefix & "_AfterSave", Controller.GetValues)
	Controller.BeginDraft
	Return True
End Sub

Public Sub Dispose
	If IsDisposed Then Return
	Controller.CancelDraft
	#If B4J Or B4A
	DisposeCustomHandles
	#End If
	#If B4J
	Scroll.RemoveNodeFromParent
	#Else If B4A
	Dim S As B4XView = Scroll
	S.RemoveViewFromParent
	#End If
	IsDisposed = True
End Sub

#If B4J
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
Private Sub SliderToPosition(Value As Object, Minimum As Double, Maximum As Double) As Int
	Dim NumericValue As Double = Value
	If Maximum = Minimum Then Return 0
	Dim Position As Int = (NumericValue - Minimum) / (Maximum - Minimum) * 1000
	If Position < 0 Then Position = 0
	If Position > 1000 Then Position = 1000
	Return Position
End Sub
#End If
