B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=10.7
@EndOfDesignText@
' Embedded B4J page. Owns one ScrollPane child; never clears the caller's container.
Sub Class_Globals
	Private fx As JFX
	Private Container As AnchorPane
	Private Scroll As ScrollPane
	Private Content As Pane
	Private Controller As PrefsController
	Private Model As PrefsModel
	Private Localization As PrefsLocalization
	Private Theme As PrefsTheme
	Private FileProvider As PrefsFileProvider
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
	Private InputLeft As Int
	Private IsDisposed As Boolean
End Sub

Public Sub Initialize(TargetContainer As AnchorPane, ValueController As PrefsController, Definition As PrefsModel, L10n As PrefsLocalization, UiTheme As PrefsTheme, Provider As PrefsFileProvider, Renderers As Map, Target As Object, TargetEvent As String)
	Container = TargetContainer
	Controller = ValueController
	Model = Definition
	Localization = L10n
	Theme = UiTheme
	FileProvider = Provider
	CustomRenderers = Renderers
	Callback = Target
	EventPrefix = TargetEvent
	IsDisposed = False
	Controller.BeginDraft
	BuildPage
End Sub

Private Sub BuildPage
	Controls.Initialize
	ControlTypes.Initialize
	TitleLabels.Initialize
	SectionLabels.Initialize
	SliderLabels.Initialize
	ActionButtons.Initialize
	BrowseButtons.Initialize
	ClearButtons.Initialize
	CustomHandles.Initialize
	BuildError = ""
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
	Dim Sections As List = Model.GetSections
	For Each Section As Map In Sections
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

Private Sub AddPreference(Pref As Map)
	Dim Id As String = Pref.Get("id")
	Dim TypeName As String = Pref.Get("type")
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
	ControlTypes.Put(Id, TypeName)
	RowTop = RowTop + Theme.RowSpacing + 32
End Sub

' Builds a custom preference through its registered renderer. See PrefsDialog
' for the lifecycle contract; behavior here is identical.
Private Sub AddCustomPreference(Pref As Map)
	Dim Id As String = Pref.Get("id")
	Dim Entry As Map = CustomEntry(Pref)
	If Entry = Null Then
		BuildError = "No custom renderer registered for preference " & Id
		LogError(BuildError)
		Dim ErrorLabel As Label
		ErrorLabel.Initialize("")
		ErrorLabel.Text = BuildError
		ErrorLabel.TextColor = fx.Colors.From32Bit(Theme.ErrorTextColor)
		Content.AddNode(ErrorLabel, InputLeft, RowTop, ContentWidth - 40 - InputLeft, 34)
		Return
	End If
	Dim CustomHeight As Int = 56
	If Pref.ContainsKey("options") Then
		Dim CustomOptions As Map = Pref.Get("options")
		If CustomOptions.ContainsKey("height") Then CustomHeight = CustomOptions.Get("height")
	End If
	If CustomHeight < 34 Then CustomHeight = 34
	Dim Args As Map
	Args.Initialize
	Args.Put("parent", Content)
	Args.Put("left", InputLeft)
	Args.Put("top", RowTop)
	Args.Put("width", ContentWidth - 40 - InputLeft)
	Args.Put("height", CustomHeight)
	Args.Put("definition", Pref)
	Args.Put("value", Controller.GetValue(Id))
	Dim Target As Object = Entry.Get("target")
	Dim EventName As String = Entry.Get("event")
	Dim Handle As Object = CallSub2(Target, EventName & "_Create", Args)
	CustomHandles.Put(Id, Handle)
	Controls.Put(Id, Handle)
	RowTop = RowTop + CustomHeight - 34
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

Public Sub RefreshValues
	If IsDisposed Then Return
	Controller.CancelDraft
	Controller.BeginDraft
	For Each Id As String In Controls.Keys
		UpdateControl(Id, Controller.GetValue(Id))
	Next
	StatusLabel.Text = ""
End Sub

Public Sub RefreshValue(Id As String, Value As Object)
	If IsDisposed Or Controls.ContainsKey(Id) = False Then Return
	UpdateControl(Id, Value)
End Sub

Private Sub UpdateControl(Id As String, Value As Object)
	Dim TypeName As String = ControlTypes.Get(Id)
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
End Sub

Public Sub RefreshLocalization
	If IsDisposed Then Return
	PageTitle.Text = Localization.Text(Model.GetTitleKey)
	Dim Sections As List = Model.GetSections
	For Each Section As Map In Sections
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
			Else If Pref.Get("type") = "slider" Then
				Dim SliderValueLabel As Label = SliderLabels.Get(Id)
				SliderValueLabel.TextColor = fx.Colors.From32Bit(Theme.TextColor)
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
	For Each ButtonId As String In ClearButtons.Keys
		Dim ClearButton As Button = ClearButtons.Get(ButtonId)
		ClearButton.Text = Localization.Text("ui.clear")
	Next
End Sub

Public Sub RefreshTheme
	If IsDisposed Then Return
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
End Sub

Public Sub SetTheme(Value As PrefsTheme)
	Theme = Value
	RefreshTheme
End Sub

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

Private Sub pageSave_Click
	Save_Click
End Sub

Private Sub pageCancel_Click
	Cancel_Click
End Sub

Private Sub pageReset_Click
	Controller.ResetDraftToDefaults
	For Each Id As String In Controls.Keys
		UpdateControl(Id, Controller.GetDraftValues.Get(Id))
	Next
	StatusLabel.Text = Localization.Text("ui.reset_done")
	StatusLabel.TextColor = fx.Colors.From32Bit(Theme.SecondaryTextColor)
End Sub

Private Sub pageAction_Click
	Dim ActionButton As Button = Sender
	Dim PreferenceId As String = ActionButton.Tag
	CallSub2(Callback, EventPrefix & "_Action", PreferenceId)
End Sub

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

Private Sub Save_Click
	If BuildError <> "" Then
		StatusLabel.Text = BuildError
		StatusLabel.TextColor = fx.Colors.From32Bit(Theme.ErrorTextColor)
		Return
	End If
	For Each Id As String In Controls.Keys
		Dim TypeName As String = ControlTypes.Get(Id)
		Dim Value As Object
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
						Return
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
					StatusLabel.TextColor = fx.Colors.From32Bit(Theme.ErrorTextColor)
					Return
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
					StatusLabel.TextColor = fx.Colors.From32Bit(Theme.ErrorTextColor)
					Return
				End If
		End Select
		If Controller.SetDraftValue(Id, Value) = False Then
			StatusLabel.Text = Controller.LastError
			StatusLabel.TextColor = fx.Colors.From32Bit(Theme.ErrorTextColor)
			Return
		End If
	Next
	Dim Validation As String = Controller.ValidateDraft
	If Validation <> "" Then
		StatusLabel.Text = Validation
		StatusLabel.TextColor = fx.Colors.From32Bit(Theme.ErrorTextColor)
		Return
	End If
	If CallSub2(Callback, EventPrefix & "_BeforeSave", Controller.GetDraftValues) = False Then Return
	Controller.CommitDraft
	CallSub2(Callback, EventPrefix & "_AfterSave", Controller.GetValues)
	Controller.BeginDraft
	StatusLabel.Text = Localization.Text("ui.saved")
	StatusLabel.TextColor = fx.Colors.From32Bit(Theme.SecondaryTextColor)
End Sub

Private Sub Cancel_Click
	Controller.CancelDraft
	Controller.BeginDraft
	For Each Id As String In Controls.Keys
		UpdateControl(Id, Controller.GetValue(Id))
	Next
	StatusLabel.Text = Localization.Text("ui.cancelled")
	StatusLabel.TextColor = fx.Colors.From32Bit(Theme.SecondaryTextColor)
End Sub

Public Sub Dispose
	If IsDisposed Then Return
	Controller.CancelDraft
	DisposeCustomHandles
	Scroll.RemoveNodeFromParent
	IsDisposed = True
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
