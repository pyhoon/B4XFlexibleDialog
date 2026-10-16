B4A=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=14.2
@EndOfDesignText@
' Renders a preference definition into a B4A Panel using a ScrollView.
' Value state, validation and Save/Cancel semantics come from the shared
' PrefsController. The host activity owns navigation and the container:
' call Render(Container) to build, Save to commit, Cancel to discard.
' File preferences open a ContentChooser and store the selected content path,
' optionally copying into File.DirInternal/prefs-files. Directory picking is
' not implemented yet; those preferences render their current value read-only.
Sub Class_Globals
	Private Model As PrefsModel
	Private Controller As PrefsController
	Private Localization As PrefsLocalization
	Private Callback As Object
	Private EventPrefix As String
	Private Form As ScrollView
	Private Controls As Map
	Private ControlTypes As Map
	Private ChoiceItems As Map
	Private MultiChecks As Map
	Private MultiValues As Map
	Private SliderLabels As Map
	Private SliderMin As Map
	Private SliderMax As Map
	Private StatusLabel As Label
	Private FilePicker As ContentChooser
	Private PendingFileId As String
	Private PendingCopy As Boolean
	Private PendingDirId As String
	Private RowTop As Int
End Sub

Public Sub Initialize(Target As Object, EventName As String, Definition As PrefsModel, ValueController As PrefsController, L10n As PrefsLocalization)
	Callback = Target
	EventPrefix = EventName
	Model = Definition
	Controller = ValueController
	Localization = L10n
	FilePicker.Initialize("prefscc")
	PendingFileId = ""
	PendingCopy = False
	PendingDirId = ""
End Sub

' Builds the form inside Parent, replacing any previous content.
Public Sub Render(Parent As Panel)
	Controller.BeginDraft
	Controls.Initialize
	ControlTypes.Initialize
	ChoiceItems.Initialize
	MultiChecks.Initialize
	MultiValues.Initialize
	SliderLabels.Initialize
	SliderMin.Initialize
	SliderMax.Initialize
	Parent.RemoveAllViews
	RowTop = 8dip
	Form.Initialize(100dip)
	Parent.AddView(Form, 0, 0, Parent.Width, Parent.Height)
	Dim ContentWidth As Int = Parent.Width - 32dip
	For Each Section As Object In Model.GetSections
		Dim SectionMap As Map = Section
		Dim SectionTitle As Label
		SectionTitle.Initialize("")
		SectionTitle.Text = Localization.Text(SectionMap.Get("titleKey"))
		SectionTitle.TextSize = 18
		SectionTitle.TextColor = Colors.DarkGray
		Form.Panel.AddView(SectionTitle, 16dip, RowTop, ContentWidth, 28dip)
		RowTop = RowTop + 36dip
		Dim Items As List = SectionMap.Get("preferences")
		For Each PrefObject As Object In Items
			Dim Pref As Map = PrefObject
			AddPreference(Pref, ContentWidth)
		Next
		RowTop = RowTop + 8dip
	Next
	StatusLabel.Initialize("")
	StatusLabel.Text = ""
	StatusLabel.TextSize = 14
	StatusLabel.TextColor = Colors.Red
	Form.Panel.AddView(StatusLabel, 16dip, RowTop, ContentWidth, 30dip)
	RowTop = RowTop + 38dip
	Form.Panel.Height = RowTop
End Sub

Private Sub AddPreference(Pref As Map, ContentWidth As Int)
	Dim Id As String = Pref.Get("id")
	Dim TypeName As String = Pref.Get("type")
	If TypeName = "label" Then
		Dim InfoKey As String = Pref.Get("titleKey")
		If Pref.ContainsKey("descriptionKey") Then InfoKey = Pref.Get("descriptionKey")
		Dim InfoLabel As Label
		InfoLabel.Initialize("")
		InfoLabel.Text = Localization.Text(InfoKey)
		InfoLabel.TextSize = 14
		InfoLabel.TextColor = Colors.Gray
		Form.Panel.AddView(InfoLabel, 16dip, RowTop, ContentWidth, 30dip)
		RowTop = RowTop + 38dip
		Return
	End If
	If TypeName = "action" Then
		Dim ActionButton As Button
		ActionButton.Initialize("prefsaction")
		ActionButton.Tag = Id
		ActionButton.Text = Localization.Text(Pref.Get("titleKey"))
		ActionButton.TextSize = 16
		Form.Panel.AddView(ActionButton, 16dip, RowTop, ContentWidth, 52dip)
		RowTop = RowTop + 60dip
		Return
	End If
	If TypeName = "switch" Or TypeName = "checkbox" Then
		Dim Check As CheckBox
		Check.Initialize("")
		Check.Text = Localization.Text(Pref.Get("titleKey"))
		Check.TextSize = 16
		Check.Checked = Controller.GetValue(Id)
		Form.Panel.AddView(Check, 16dip, RowTop, ContentWidth, 52dip)
		Controls.Put(Id, Check)
		ControlTypes.Put(Id, TypeName)
		RowTop = RowTop + 60dip
		Return
	End If
	AddTitle(Pref, ContentWidth)
	If TypeName = "text" Or TypeName = "number" Then
		Dim Input As EditText
		Input.Initialize("")
		Input.TextSize = 16
		Input.SingleLine = True
		If TypeName = "number" Then Input.InputType = Input.INPUT_TYPE_DECIMAL_NUMBERS
		Input.Text = Controller.GetValue(Id)
		Form.Panel.AddView(Input, 16dip, RowTop, ContentWidth, 52dip)
		Controls.Put(Id, Input)
		RowTop = RowTop + 60dip
	Else If TypeName = "multiline" Then
		Dim Area As EditText
		Area.Initialize("")
		Area.TextSize = 16
		Area.SingleLine = False
		Area.Text = Controller.GetValue(Id)
		Form.Panel.AddView(Area, 16dip, RowTop, ContentWidth, 120dip)
		Controls.Put(Id, Area)
		RowTop = RowTop + 128dip
	Else If TypeName = "password" Then
		Dim Secret As EditText
		Secret.Initialize("")
		Secret.TextSize = 16
		Secret.SingleLine = True
		Secret.PasswordMode = True
		Secret.Text = Controller.GetValue(Id)
		Form.Panel.AddView(Secret, 16dip, RowTop, ContentWidth, 52dip)
		Controls.Put(Id, Secret)
		RowTop = RowTop + 60dip
	Else If TypeName = "choice" Then
		Dim Options As Map = Pref.Get("options")
		Dim Items As List = Options.Get("items")
		Dim Values As List
		Values.Initialize
		Dim Selector As Spinner
		Selector.Initialize("")
		Dim Selected As Int = -1
		For I = 0 To Items.Size - 1
			Dim Item As Map = Items.Get(I)
			Selector.Add(Localization.Text(Item.Get("titleKey")))
			Dim ItemValue As String = Item.Get("value")
			Values.Add(ItemValue)
			Dim CurrentValue As String = Controller.GetValue(Id)
			If ItemValue = CurrentValue Then Selected = I
		Next
		Selector.SelectedIndex = Selected
		Form.Panel.AddView(Selector, 16dip, RowTop, ContentWidth, 52dip)
		Controls.Put(Id, Selector)
		ChoiceItems.Put(Id, Values)
		RowTop = RowTop + 60dip
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
			Form.Panel.AddView(Box, 24dip, RowTop, ContentWidth - 8dip, 44dip)
			RowTop = RowTop + 48dip
			Checks.Add(Box)
		Next
		Controls.Put(Id, Checks)
		MultiValues.Put(Id, ItemValues)
		RowTop = RowTop + 8dip
	Else If TypeName = "date" Or TypeName = "time" Or TypeName = "datetime" Then
		Dim Moment As EditText
		Moment.Initialize("")
		Moment.TextSize = 16
		Moment.SingleLine = True
		If TypeName = "time" Then Moment.Hint = "HH:mm"
		If TypeName = "datetime" Then Moment.Hint = "yyyy-MM-ddTHH:mm"
		Moment.Text = Controller.GetValue(Id)
		Form.Panel.AddView(Moment, 16dip, RowTop, ContentWidth, 52dip)
		Controls.Put(Id, Moment)
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
		Form.Panel.AddView(Bar, 16dip, RowTop, ContentWidth - 90dip, 52dip)
		Dim ValueLabel As Label
		ValueLabel.Initialize("")
		ValueLabel.TextSize = 14
		ValueLabel.Text = Controller.GetValue(Id)
		Form.Panel.AddView(ValueLabel, 16dip + ContentWidth - 82dip, RowTop + 12dip, 74dip, 28dip)
		SliderLabels.Put(Id, ValueLabel)
		Controls.Put(Id, Bar)
		RowTop = RowTop + 60dip
	Else If TypeName = "file" Then
		Dim PathField As EditText
		PathField.Initialize("")
		PathField.TextSize = 14
		PathField.SingleLine = True
		PathField.Enabled = False
		PathField.Text = Controller.GetValue(Id)
		Form.Panel.AddView(PathField, 16dip, RowTop, ContentWidth - 110dip, 52dip)
		Controls.Put(Id, PathField)
		Dim BrowseButton As Button
		BrowseButton.Initialize("prefsbrowse")
		BrowseButton.Tag = Id
		BrowseButton.Text = Localization.Text("ui.browse")
		BrowseButton.TextSize = 16
		Form.Panel.AddView(BrowseButton, 16dip + ContentWidth - 94dip, RowTop, 94dip, 52dip)
		RowTop = RowTop + 60dip
	Else If TypeName = "directory" Then
		Dim DirField As EditText
		DirField.Initialize("")
		DirField.TextSize = 14
		DirField.SingleLine = True
		DirField.Enabled = False
		DirField.Text = Controller.GetValue(Id)
		Form.Panel.AddView(DirField, 16dip, RowTop, ContentWidth - 110dip, 52dip)
		Controls.Put(Id, DirField)
		Dim DirBrowse As Button
		DirBrowse.Initialize("prefsbrowsedir")
		DirBrowse.Tag = Id
		DirBrowse.Text = Localization.Text("ui.browse")
		DirBrowse.TextSize = 16
		Form.Panel.AddView(DirBrowse, 16dip + ContentWidth - 94dip, RowTop, 94dip, 52dip)
		RowTop = RowTop + 60dip
	End If
	ControlTypes.Put(Id, TypeName)
End Sub

Private Sub prefsbrowsedir_Click
	Dim Source As Button = Sender
	PendingDirId = Source.Tag
	CallSub2(Callback, EventPrefix & "_BrowseDirectory", PendingDirId)
End Sub

' Called by the host activity after an Android directory pick completes.
' Stores the tree URI in the pending field; Save commits it like any value.
Public Sub SetDirectoryValue(Uri As String)
	If PendingDirId = "" Then Return
	Dim Field As EditText = Controls.Get(PendingDirId)
	Field.Text = Uri
	PendingDirId = ""
End Sub

Private Sub prefsbrowse_Click
	Dim Source As Button = Sender
	Dim Id As String = Source.Tag
	Dim Pref As Map = Model.GetPreference(Id)
	Dim Options As Map
	Options.Initialize
	If Pref.ContainsKey("options") Then Options = Pref.Get("options")
	PendingFileId = Id
	PendingCopy = False
	If Options.ContainsKey("copyToAppStorage") Then PendingCopy = Options.Get("copyToAppStorage")
	FilePicker.Show(MimeForOptions(Options), Localization.Text(Pref.Get("titleKey")))
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
		ShowError("Could not store the selected file.")
	End Try
End Sub

' Builds a filesystem-safe target name. Content URIs carry no usable file
' name, so fall back to the preference id. When the name has no extension,
' append the first allowed extension (the picker was already MIME-filtered)
' so extension validation stays meaningful.
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

' Maps options.extensions to an Android MIME filter. Defaults to */* when
' the list is absent or contains non-image types.
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

Private Sub AddTitle(Pref As Map, ContentWidth As Int)
	Dim Title As Label
	Title.Initialize("")
	Title.Text = Localization.Text(Pref.Get("titleKey"))
	Title.TextSize = 16
	Form.Panel.AddView(Title, 16dip, RowTop, ContentWidth, 26dip)
	RowTop = RowTop + 30dip
End Sub

Private Sub prefsaction_Click
	Dim Source As Button = Sender
	CallSub2(Callback, EventPrefix & "_Action", Source.Tag)
End Sub

Private Sub prefsseek_ValueChanged(Value As Int, UserChanged As Boolean)
	Dim Bar As SeekBar = Sender
	Dim Id As String = Bar.Tag
	Dim Minimum As Double = SliderMin.Get(Id)
	Dim Maximum As Double = SliderMax.Get(Id)
	Dim Shown As Double = Minimum + (Maximum - Minimum) * (Value / 1000)
	Dim ValueLabel As Label = SliderLabels.Get(Id)
	ValueLabel.Text = Shown
End Sub

' Reads all controls into the draft, validates, and commits on success.
' Returns True when the values were committed.
Public Sub Save As Boolean
	For Each Id As String In Controls.Keys
		Dim TypeName As String = ControlTypes.Get(Id)
		Dim Value As Object
		Select TypeName
			Case "text", "multiline", "password", "number", "date", "time", "datetime"
				Dim Input As EditText = Controls.Get(Id)
				If TypeName = "number" Then
					If IsNumber(Input.Text) = False Then
						ShowError("Enter a valid number (" & Id & ")")
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
					ShowError("Select an option (" & Id & ")")
					Return False
				End If
				Dim Values As List = ChoiceItems.Get(Id)
				Value = Values.Get(Selector.SelectedIndex)
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
		End Select
		If Controller.SetDraftValue(Id, Value) = False Then
			ShowError(Controller.LastError)
			Return False
		End If
	Next
	Dim Validation As String = Controller.ValidateDraft
	If Validation <> "" Then
		ShowError(Validation)
		Return False
	End If
	If CallSub2(Callback, EventPrefix & "_BeforeSave", Controller.GetDraftValues) = False Then Return False
	Controller.CommitDraft
	CallSub2(Callback, EventPrefix & "_AfterSave", Controller.GetValues)
	Return True
End Sub

' Discards the current draft edits.
Public Sub Cancel
	Controller.CancelDraft
End Sub

Private Sub ShowError(Message As String)
	StatusLabel.Text = Message
End Sub

Private Sub SliderToPosition(Value As Object, Minimum As Double, Maximum As Double) As Int
	Dim NumericValue As Double = Value
	If Maximum = Minimum Then Return 0
	Dim Position As Int = (NumericValue - Minimum) / (Maximum - Minimum) * 1000
	If Position < 0 Then Position = 0
	If Position > 1000 Then Position = 1000
	Return Position
End Sub
