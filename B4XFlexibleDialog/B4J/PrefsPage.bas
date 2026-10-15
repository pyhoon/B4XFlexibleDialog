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
	Private Callback As Object
	Private EventPrefix As String
	Private Controls As Map
	Private ControlTypes As Map
	Private TitleLabels As Map
	Private SectionLabels As Map
	Private PageTitle As Label
	Private StatusLabel As Label
	Private SaveButton As Button
	Private CancelButton As Button
	Private RowTop As Int
	Private IsDisposed As Boolean
End Sub

Public Sub Initialize(TargetContainer As AnchorPane, ValueController As PrefsController, Definition As PrefsModel, L10n As PrefsLocalization, UiTheme As PrefsTheme, Target As Object, TargetEvent As String)
	Container = TargetContainer
	Controller = ValueController
	Model = Definition
	Localization = L10n
	Theme = UiTheme
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
	RowTop = 18
	Content.Initialize("page")
	Content.StyleClasses.Add("prefs-surface")
	Content.PrefWidth = Max(650, Container.Width - 24)
	Scroll.Initialize("page")
	Scroll.FitToWidth = True
	Scroll.InnerNode = Content
	Scroll.Style = "-fx-background-color: transparent; -fx-background: transparent;"
	Container.AddNode(Scroll, 0, 0, -1, -1)
	Container.SetAnchors(Scroll, 0, 0, 0, 0)
	PageTitle.Initialize("")
	PageTitle.Text = Localization.Text(Model.GetTitleKey)
	PageTitle.TextColor = fx.Colors.From32Bit(Theme.TextColor)
	Content.AddNode(PageTitle, 24, RowTop, 600, 34)
	RowTop = RowTop + 44
	Dim Sections As List = Model.GetSections
	For Each Section As Map In Sections
		Dim SectionTitle As Label
		SectionTitle.Initialize("")
		SectionTitle.Text = Localization.Text(Section.Get("titleKey"))
		SectionTitle.TextColor = fx.Colors.From32Bit(Theme.SecondaryTextColor)
		Content.AddNode(SectionTitle, 24, RowTop, 600, 28)
		SectionLabels.Put(Section.Get("id"), SectionTitle)
		RowTop = RowTop + Theme.SectionSpacing + 10
		Dim Preferences As List = Section.Get("preferences")
		For Each Pref As Map In Preferences
			AddPreference(Pref)
		Next
		RowTop = RowTop + 8
	Next
	StatusLabel.Initialize("")
	StatusLabel.TextColor = fx.Colors.From32Bit(16724787)
	Content.AddNode(StatusLabel, 24, RowTop, 600, 26)
	RowTop = RowTop + 38
	SaveButton.Initialize("page")
	SaveButton.Tag = "save"
	Content.AddNode(SaveButton, 24, RowTop, 110, 36)
	CancelButton.Initialize("page")
	CancelButton.Tag = "cancel"
	Content.AddNode(CancelButton, 144, RowTop, 110, 36)
	RowTop = RowTop + 56
	Content.PrefHeight = RowTop
	RefreshTheme
	RefreshLocalization
End Sub

Private Sub AddPreference(Pref As Map)
	Dim Id As String = Pref.Get("id")
	Dim TypeName As String = Pref.Get("type")
	If TypeName = "switch" Then
		Dim Check As CheckBox
		Check.Initialize("page")
		Check.Tag = Id
		Check.Checked = Controller.GetValue(Id)
		Content.AddNode(Check, 34, RowTop, 600, 36)
		Controls.Put(Id, Check)
		TitleLabels.Put(Id, Check)
	Else
		Dim Title As Label
		Title.Initialize("")
		Content.AddNode(Title, 34, RowTop + 4, 240, 30)
		TitleLabels.Put(Id, Title)
		If TypeName = "text" Or TypeName = "number" Then
			Dim Input As TextField
			Input.Initialize("page")
			Input.Tag = Id
			Input.Text = "" & Controller.GetValue(Id)
			Content.AddNode(Input, 290, RowTop, 320, 36)
			Controls.Put(Id, Input)
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
			Content.AddNode(Choice, 290, RowTop, 320, 36)
			Controls.Put(Id, Choice)
		End If
	End If
	ControlTypes.Put(Id, TypeName)
	RowTop = RowTop + Theme.RowSpacing + 32
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
		Case "text", "number"
			Dim Input As TextField = Controls.Get(Id)
			Input.Text = "" & Value
		Case "switch"
			Dim Check As CheckBox = Controls.Get(Id)
			Check.Checked = Value
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
			If Pref.Get("type") = "switch" Then
				Dim Check As CheckBox = Controls.Get(Id)
				Check.Text = Localization.Text(Pref.Get("titleKey"))
			Else
				Dim Title As Label = TitleLabels.Get(Id)
				Title.Text = Localization.Text(Pref.Get("titleKey"))
			End If
			If Pref.Get("type") = "choice" Then
				Dim Choice As ComboBox = Controls.Get(Id)
				Dim SelectedIndex As Int = Choice.SelectedIndex
				Choice.Items.Clear
				Dim Options As Map = Pref.Get("options")
				Dim Items As List = Options.Get("items")
				For Each Item As Map In Items
					Choice.Items.Add(Localization.Text(Item.Get("titleKey")))
				Next
				Choice.SelectedIndex = SelectedIndex
			End If
		Next
	Next
	SaveButton.Text = Localization.Text("ui.save")
	CancelButton.Text = Localization.Text("ui.cancel")
End Sub

Public Sub RefreshTheme
	If IsDisposed Then Return
	ApplyTheme
	For Each Id As String In TitleLabels.Keys
		If ControlTypes.Get(Id) = "switch" Then
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
		If ControlTypes.Get(Id) = "text" Or ControlTypes.Get(Id) = "number" Then
			Dim Input As TextField = Controls.Get(Id)
			Input.Style = InputCss
		Else If ControlTypes.Get(Id) = "choice" Then
			Dim Choice As ComboBox = Controls.Get(Id)
			Choice.Style = InputCss
		End If
	Next
	ApplyButtonStyles
End Sub

Private Sub ApplyTheme
	Content.Style = "-fx-background-color: " & ColorCss(Theme.BackgroundColor) & "; -prefs-input-bg: " & ColorCss(Theme.InputBackgroundColor) & "; -prefs-input-text: " & ColorCss(Theme.TextColor) & "; -prefs-input-border: " & ColorCss(Theme.InputBorderColor) & "; -prefs-accent: " & ColorCss(Theme.AccentColor) & "; -prefs-checkmark-text: " & ColorCss(Theme.PrimaryButtonTextColor) & ";"
	Scroll.Style = "-fx-background-color: " & ColorCss(Theme.BackgroundColor) & "; -fx-background: " & ColorCss(Theme.BackgroundColor) & ";"
	PageTitle.TextColor = fx.Colors.From32Bit(Theme.TextColor)
	StatusLabel.TextColor = fx.Colors.From32Bit(16724787)
	ApplyButtonStyles
End Sub

Private Sub ApplyButtonStyles
	SaveButton.TextColor = fx.Colors.From32Bit(Theme.PrimaryButtonTextColor)
	SaveButton.Style = "-fx-background-color: " & ColorCss(Theme.AccentColor) & "; -fx-text-fill: " & ColorCss(Theme.PrimaryButtonTextColor) & "; -fx-font-weight: bold; -fx-background-radius: 4;"
	CancelButton.TextColor = fx.Colors.From32Bit(Theme.SecondaryButtonTextColor)
	CancelButton.Style = "-fx-background-color: " & ColorCss(Theme.SecondaryButtonBackgroundColor) & "; -fx-text-fill: " & ColorCss(Theme.SecondaryButtonTextColor) & "; -fx-background-radius: 4;"
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

Private Sub page_Click
	Dim Source As Button = Sender
	If Source.Tag = "save" Then Save_Click
	If Source.Tag = "cancel" Then Cancel_Click
End Sub

Private Sub Save_Click
	For Each Id As String In Controls.Keys
		Dim TypeName As String = ControlTypes.Get(Id)
		Dim Value As Object
		Select TypeName
			Case "text", "number"
				Dim Input As TextField = Controls.Get(Id)
				If TypeName = "number" Then
					If IsNumber(Input.Text) = False Then
						StatusLabel.Text = Localization.Text("validation.number") & " (" & Id & ")"
						Return
					End If
					Dim NumberValue As Double = Input.Text
					Value = NumberValue
				Else
					Value = Input.Text
				End If
			Case "switch"
				Dim Check As CheckBox = Controls.Get(Id)
				Value = Check.Checked
			Case "choice"
				Dim Choice As ComboBox = Controls.Get(Id)
				If Choice.SelectedIndex < 0 Then
					StatusLabel.Text = Localization.Text("validation.choice") & " (" & Id & ")"
					Return
				End If
				Dim Pref As Map = Model.GetPreference(Id)
				Dim Options As Map = Pref.Get("options")
				Dim Items As List = Options.Get("items")
				Dim SelectedItem As Map = Items.Get(Choice.SelectedIndex)
				Value = SelectedItem.Get("value")
		End Select
		If Controller.SetDraftValue(Id, Value) = False Then
			StatusLabel.Text = Controller.LastError
			Return
		End If
	Next
	Dim Validation As String = Controller.ValidateDraft
	If Validation <> "" Then
		StatusLabel.Text = Validation
		Return
	End If
	If CallSub2(Callback, EventPrefix & "_BeforeSave", Controller.GetDraftValues) = False Then Return
	Controller.CommitDraft
	CallSub2(Callback, EventPrefix & "_AfterSave", Controller.GetValues)
	Controller.BeginDraft
	StatusLabel.Text = Localization.Text("ui.saved")
End Sub

Private Sub Cancel_Click
	Controller.CancelDraft
	Controller.BeginDraft
	For Each Id As String In Controls.Keys
		UpdateControl(Id, Controller.GetValue(Id))
	Next
	StatusLabel.Text = Localization.Text("ui.cancelled")
End Sub

Public Sub Dispose
	If IsDisposed Then Return
	Controller.CancelDraft
	Scroll.RemoveNodeFromParent
	IsDisposed = True
End Sub
