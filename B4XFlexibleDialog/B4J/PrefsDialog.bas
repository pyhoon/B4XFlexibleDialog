B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=10.7
@EndOfDesignText@
' B4J modal view. All values are read into controller draft state before commit.
Sub Class_Globals
	Private fx As JFX
	Private DialogForm As Form
	Private DialogScroll As ScrollPane
	Private ContentPane As Pane
	Private OwnerForm As Form
	Private Controller As PrefsController
	Private Model As PrefsModel
	Private Localization As PrefsLocalization
	Private Theme As PrefsTheme
	Private Callback As Object
	Private EventPrefix As String
	Private Controls As Map
	Private ControlTypes As Map
	Private TitleLabels As Map
	Private SectionLabels As Map
	Private SliderLabels As Map
	Private ActionButtons As Map
	Private StatusLabel As Label
	Private SaveButton As Button
	Private CancelButton As Button
	Private LanguageButton As Button
	Private ThemeButton As Button
	Private Saved As Boolean
	Private RowTop As Int
End Sub

Public Sub Initialize(Owner As Form, ValueController As PrefsController, Definition As PrefsModel, L10n As PrefsLocalization, UiTheme As PrefsTheme, Target As Object, TargetEvent As String)
	OwnerForm = Owner
	Controller = ValueController
	Model = Definition
	Localization = L10n
	Theme = UiTheme
	Callback = Target
	EventPrefix = TargetEvent
End Sub

Public Sub Show As Boolean
	Controller.BeginDraft
	Controls.Initialize
	ControlTypes.Initialize
	TitleLabels.Initialize
	SectionLabels.Initialize
	SliderLabels.Initialize
	ActionButtons.Initialize
	Saved = False
	RowTop = 18
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
	DialogForm.Initialize("dlg", 650, Height)
	DialogForm.Title = Localization.Text(Model.GetTitleKey)
	DialogForm.SetOwner(OwnerForm)
	DialogForm.Resizable = True
	DialogForm.Stylesheets.Add(File.GetUri(File.DirAssets, "prefs.css"))
	DialogForm.RootPane.StyleClasses.Add("prefs-surface")
	ApplyTheme
	ContentPane.Initialize("dlg")
	DialogScroll.Initialize("dlg")
	DialogScroll.FitToWidth = True
	DialogScroll.InnerNode = ContentPane
	DialogScroll.Style = "-fx-background-color: transparent; -fx-background: transparent;"
	DialogForm.RootPane.AddNode(DialogScroll, 0, 0, -1, Height - 140)
	DialogForm.RootPane.SetAnchors(DialogScroll, 0, 0, 0, 140)
	Dim SectionList As List = Model.GetSections
	For Each Section As Map In SectionList
		Dim SectionTitle As Label
		SectionTitle.Initialize("")
		SectionTitle.Text = Localization.Text(Section.Get("titleKey"))
		SectionTitle.TextColor = fx.Colors.From32Bit(Theme.SecondaryTextColor)
		ContentPane.AddNode(SectionTitle, 24, RowTop, 590, 28)
		SectionLabels.Put(Section.Get("id"), SectionTitle)
		RowTop = RowTop + Theme.SectionSpacing + 12
		Dim Items As List = Section.Get("preferences")
		For Each Pref As Map In Items
			AddPreference(Pref)
		Next
		RowTop = RowTop + 6
	Next
	ContentPane.PrefWidth = 620
	ContentPane.PrefHeight = RowTop + 20
	StatusLabel.Initialize("")
	StatusLabel.TextColor = fx.Colors.From32Bit(Theme.ErrorTextColor)
	DialogForm.RootPane.AddNode(StatusLabel, 24, Height - 105, 590, 24)
	LanguageButton.Initialize("dlg")
	LanguageButton.Text = Localization.Text("ui.language")
	LanguageButton.TextColor = fx.Colors.From32Bit(Theme.AccentColor)
	DialogForm.RootPane.AddNode(LanguageButton, 24, Height - 68, 110, 34)
	ThemeButton.Initialize("dlg")
	ThemeButton.Text = Localization.Text("ui.theme")
	ThemeButton.TextColor = fx.Colors.From32Bit(Theme.AccentColor)
	DialogForm.RootPane.AddNode(ThemeButton, 140, Height - 68, 100, 34)
	CancelButton.Initialize("dlg")
	CancelButton.Text = Localization.Text("ui.cancel")
	DialogForm.RootPane.AddNode(CancelButton, 400, Height - 68, 90, 34)
	SaveButton.Initialize("dlg")
	SaveButton.Text = Localization.Text("ui.save")
	DialogForm.RootPane.AddNode(SaveButton, 500, Height - 68, 100, 34)
	RefreshButtons
	DialogForm.ShowAndWait
	If Saved = False Then Controller.CancelDraft
	Return Saved
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
		InfoLabel.TextColor = fx.Colors.From32Bit(Theme.SecondaryTextColor)
		ContentPane.AddNode(InfoLabel, 34, RowTop + 4, 560, 30)
		TitleLabels.Put(Id, InfoLabel)
	Else If TypeName = "action" Then
		Dim ActionButton As Button
		ActionButton.Initialize("prefsAction")
		ActionButton.Tag = Id
		ActionButton.Text = Localization.Text(Pref.Get("titleKey"))
		ActionButton.Style = "-fx-background-color: " & ColorCss(Theme.AccentColor) & "; -fx-text-fill: " & ColorCss(Theme.PrimaryButtonTextColor) & ";"
		ContentPane.AddNode(ActionButton, 290, RowTop, 220, 34)
		ActionButtons.Put(Id, ActionButton)
	Else If TypeName = "switch" Or TypeName = "checkbox" Then
		Dim Check As CheckBox
		Check.Initialize("dlg")
		Check.Text = Localization.Text(Pref.Get("titleKey"))
		Check.TextColor = fx.Colors.From32Bit(Theme.TextColor)
		Check.Style = "-fx-accent: " & ColorCss(Theme.AccentColor) & "; -fx-focus-color: " & ColorCss(Theme.AccentColor) & ";"
		Check.Checked = Controller.GetValue(Id)
		ContentPane.AddNode(Check, 34, RowTop, 560, 34)
		Controls.Put(Id, Check)
		TitleLabels.Put(Id, Check)
	Else
		Dim Title As Label
		Title.Initialize("")
		Title.Text = Localization.Text(Pref.Get("titleKey"))
		Title.TextColor = fx.Colors.From32Bit(Theme.TextColor)
		ContentPane.AddNode(Title, 34, RowTop + 4, 240, 28)
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
			ContentPane.AddNode(Input, 290, RowTop, 300, 34)
			Controls.Put(Id, Input)
		Else If TypeName = "multiline" Then
			Dim MultilineInput As TextArea
			MultilineInput.Initialize("dlg")
			MultilineInput.Text = "" & Controller.GetValue(Id)
			MultilineInput.WrapText = True
			MultilineInput.Style = InputCss
			ContentPane.AddNode(MultilineInput, 290, RowTop, 300, 76)
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
			ContentPane.AddNode(Multi, 290, RowTop, 300, 90)
			Controls.Put(Id, Multi)
			RowTop = RowTop + 56
		Else If TypeName = "date" Then
			Dim DateInput As DatePicker
			DateInput.Initialize("")
			DateInput.DateFormat = "yyyy-MM-dd"
			DateInput.DateTicks = IsoToTicks(Controller.GetValue(Id))
			DateInput.Style = InputCss
			ContentPane.AddNode(DateInput, 290, RowTop, 220, 34)
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
			ContentPane.AddNode(ValueSlider, 290, RowTop, 240, 34)
			Controls.Put(Id, ValueSlider)
			Dim SliderValueLabel As Label
			SliderValueLabel.Initialize("")
			SliderValueLabel.Text = "" & ValueSlider.Value
			SliderValueLabel.TextColor = fx.Colors.From32Bit(Theme.TextColor)
			ContentPane.AddNode(SliderValueLabel, 540, RowTop + 4, 60, 28)
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
			ContentPane.AddNode(Choice, 290, RowTop, 300, 34)
			Controls.Put(Id, Choice)
		End If
	End If
	ControlTypes.Put(Id, TypeName)
	RowTop = RowTop + Theme.RowSpacing + 30
End Sub

Private Sub dlg_Click
	Dim Source As Object = Sender
	If Source Is Button Then
		Dim B As Button = Source
		If B.Text = Localization.Text("ui.save") Then Save_Click
		If B.Text = Localization.Text("ui.cancel") Then DialogForm.Close
		If B.Text = Localization.Text("ui.language") Then Language_Click
		If B.Text = Localization.Text("ui.theme") Then Theme_Click
	End If
End Sub

Private Sub Save_Click
	For Each Id As String In Controls.Keys
		Dim TypeName As String = ControlTypes.Get(Id)
		Dim Value As Object
		Select TypeName
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
					Return
				End If
				Dim Pref As Map = Model.GetPreference(Id)
				Dim PrefOptions As Map = Pref.Get("options")
				Dim Items As List = PrefOptions.Get("items")
				Dim SelectedItem As Map = Items.Get(Choice.SelectedIndex)
				Value = SelectedItem.Get("value")
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
	Dim DraftValues As Map = Controller.GetDraftValues
	Dim Accepted As Boolean = True
	Accepted = CallSub2(Callback, EventPrefix & "_BeforeSave", DraftValues)
	If Accepted = False Then Return
	Controller.CommitDraft
	Saved = True
	CallSub2(Callback, EventPrefix & "_AfterSave", Controller.GetValues)
	DialogForm.Close
End Sub

Private Sub Language_Click
	Localization.ToggleLanguage
	DialogForm.Title = Localization.Text(Model.GetTitleKey)
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
			If Pref.Get("type") = "choice" Then
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
	RefreshButtons
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
		End If
	Next
	For Each Id As String In ActionButtons.Keys
		Dim ActionButton As Button = ActionButtons.Get(Id)
		ActionButton.Style = "-fx-background-color: " & ColorCss(Theme.AccentColor) & "; -fx-text-fill: " & ColorCss(Theme.PrimaryButtonTextColor) & ";"
	Next
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
	LanguageButton.Text = Localization.Text("ui.language")
	ThemeButton.Text = Localization.Text("ui.theme")
	SaveButton.TextColor = fx.Colors.From32Bit(Theme.PrimaryButtonTextColor)
	SaveButton.Style = "-fx-background-color: " & ColorCss(Theme.AccentColor) & "; -fx-text-fill: " & ColorCss(Theme.PrimaryButtonTextColor) & "; -fx-font-weight: bold; -fx-background-radius: 4;"
	CancelButton.TextColor = fx.Colors.From32Bit(Theme.SecondaryButtonTextColor)
	CancelButton.Style = SecondaryButtonCss
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
