B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=10.7
@EndOfDesignText@
' Holds committed and draft values independently of any JavaFX controls.
Sub Class_Globals
	Private Model As PrefsModel
	Private Committed As Map
	Private Draft As Map
	Private HasDraft As Boolean
	Private Store As PrefsStore
	Private StoreEnabled As Boolean
	Public LastError As String
End Sub

Public Sub Initialize(Definition As PrefsModel)
	Model = Definition
	Committed.Initialize
	Draft.Initialize
	HasDraft = False
	For Each Id As String In Model.GetPreferenceIds
		Dim Pref As Map = Model.GetPreference(Id)
		If Pref.Get("type") <> "label" And Pref.Get("type") <> "action" Then Committed.Put(Id, CopyValue(Pref.Get("defaultValue")))
	Next
End Sub

Public Sub SetValue(Id As String, Value As Object) As Boolean
	LastError = ValidateValue(Id, Value)
	If LastError <> "" Then Return False
	Committed.Put(Id, CopyValue(Value))
	If HasDraft Then Draft.Put(Id, CopyValue(Value))
	PersistIfConfigured
	Return True
End Sub

Public Sub GetValue(Id As String) As Object
	If Committed.ContainsKey(Id) Then Return CopyValue(Committed.Get(Id))
	Return Null
End Sub

Public Sub GetValues As Map
	Return CopyMap(Committed)
End Sub

Public Sub GetDefaultValue(Id As String) As Object
	Dim Pref As Map = Model.GetPreference(Id)
	If Pref.IsInitialized = False Then Return Null
	If Pref.Get("type") = "label" Or Pref.Get("type") = "action" Then Return Null
	Return CopyValue(Pref.Get("defaultValue"))
End Sub

Public Sub ResetToDefaults
	For Each Id As String In Model.GetPreferenceIds
		Dim Pref As Map = Model.GetPreference(Id)
		If Pref.Get("type") <> "label" And Pref.Get("type") <> "action" Then Committed.Put(Id, CopyValue(Pref.Get("defaultValue")))
	Next
	If HasDraft Then Draft = CopyMap(Committed)
	PersistIfConfigured
End Sub

Public Sub ResetPreference(Id As String)
	Dim Pref As Map = Model.GetPreference(Id)
	If Pref.IsInitialized = False Then Return
	If Pref.Get("type") = "label" Or Pref.Get("type") = "action" Then Return
	Committed.Put(Id, CopyValue(Pref.Get("defaultValue")))
	If HasDraft Then Draft.Put(Id, CopyValue(Pref.Get("defaultValue")))
	PersistIfConfigured
End Sub

Public Sub ResetDraftToDefaults
	If HasDraft = False Then BeginDraft
	For Each Id As String In Model.GetPreferenceIds
		Dim Pref As Map = Model.GetPreference(Id)
		If Pref.Get("type") <> "label" And Pref.Get("type") <> "action" Then Draft.Put(Id, CopyValue(Pref.Get("defaultValue")))
	Next
End Sub

Public Sub BeginDraft
	Draft = CopyMap(Committed)
	HasDraft = True
End Sub

Public Sub SetDraftValue(Id As String, Value As Object) As Boolean
	If HasDraft = False Then BeginDraft
	LastError = ValidateValue(Id, Value)
	If LastError <> "" Then Return False
	Draft.Put(Id, CopyValue(Value))
	Return True
End Sub

Public Sub GetDraftValues As Map
	If HasDraft = False Then BeginDraft
	Return CopyMap(Draft)
End Sub

Public Sub ValidateDraft As String
	If HasDraft = False Then BeginDraft
	For Each Id As String In Model.GetPreferenceIds
		Dim Pref As Map = Model.GetPreference(Id)
		If Pref.Get("type") <> "label" And Pref.Get("type") <> "action" Then
			If Draft.ContainsKey(Id) = False Then Return "Missing draft value for " & Id
			Dim ErrorText As String = ValidateValue(Id, Draft.Get(Id))
			If ErrorText <> "" Then Return ErrorText
		End If
	Next
	Return ""
End Sub

Public Sub CommitDraft
	Committed = CopyMap(Draft)
	HasDraft = False
	PersistIfConfigured
End Sub

Public Sub SetStore(S As PrefsStore)
	Store = S
	StoreEnabled = True
End Sub

Public Sub GetStore As PrefsStore
	Return Store
End Sub

Private Sub PersistIfConfigured
	If StoreEnabled Then Store.Save(Committed)
End Sub

' Applies stored values for known value preferences. Unknown keys and invalid values are skipped.
' Returns the number of applied values.
Public Sub ApplyValues(NewValues As Map) As Int
	Dim Applied As Int = 0
	For Each Key As String In NewValues.Keys
		Dim Pref As Map = Model.GetPreference(Key)
		If Pref.IsInitialized = False Then Continue
		If Pref.Get("type") = "label" Or Pref.Get("type") = "action" Then Continue
		Dim Candidate As Object = NewValues.Get(Key)
		If ValidateValue(Key, Candidate) = "" Then
			Committed.Put(Key, CopyValue(Candidate))
			Applied = Applied + 1
		End If
	Next
	If HasDraft Then Draft = CopyMap(Committed)
	Return Applied
End Sub

Public Sub CancelDraft
	Draft.Clear
	HasDraft = False
End Sub

Public Sub ValidateValue(Id As String, Value As Object) As String
	Dim Pref As Map = Model.GetPreference(Id)
	If Pref.IsInitialized = False Then Return "Unknown preference id: " & Id
	Dim TypeName As String = Pref.Get("type")
	Select TypeName
		Case "label", "action"
			Return "Preference " & Id & " does not store a value."
		Case "text", "multiline", "password"
			If IsStringObject(Value) = False Then Return "Preference " & Id & " must be text."
			Dim TextValue As String = Value
			If Pref.ContainsKey("required") Then
				Dim RequiredValue As Boolean = Pref.Get("required")
				If RequiredValue And TextValue.Length = 0 Then Return "Preference " & Id & " is required."
			End If
			If Pref.ContainsKey("minLength") Then
				Dim MinimumLength As Int = Pref.Get("minLength")
				If TextValue.Length < MinimumLength Then Return "Preference " & Id & " must contain at least " & MinimumLength & " characters."
			End If
			If Pref.ContainsKey("maxLength") Then
				Dim MaximumLength As Int = Pref.Get("maxLength")
				If TextValue.Length > MaximumLength Then Return "Preference " & Id & " must contain no more than " & MaximumLength & " characters."
			End If
		Case "number", "slider"
			If IsNumberObject(Value) = False Then Return "Preference " & Id & " must be a number."
			Dim Options As Map
			Options.Initialize
			If Pref.ContainsKey("options") Then Options = Pref.Get("options")
			Dim NumericValue As Double = Value
			If Options.ContainsKey("min") Then
				Dim Minimum As Double = Options.Get("min")
				If NumericValue < Minimum Then Return "Preference " & Id & " must be at least " & Minimum & "."
			End If
			If Options.ContainsKey("max") Then
				Dim Maximum As Double = Options.Get("max")
				If NumericValue > Maximum Then Return "Preference " & Id & " must be at most " & Maximum & "."
			End If
		Case "switch", "checkbox"
			If IsBooleanObject(Value) = False Then Return "Preference " & Id & " must be true or false."
		Case "choice"
			If IsStringObject(Value) = False Then Return "Preference " & Id & " must be a choice value."
			Dim Options As Map = Pref.Get("options")
			Dim Items As List = Options.Get("items")
			Dim Found As Boolean = False
			Dim Candidate As String = Value
			For Each Item As Map In Items
				Dim ChoiceValue As String = Item.Get("value")
				If ChoiceValue = Candidate Then Found = True
			Next
			If Found = False Then Return "Preference " & Id & " has an invalid choice value."
		Case "multichoice"
			If IsListObject(Value) = False Then Return "Preference " & Id & " must be a list of choice values."
			Dim MultiOptions As Map = Pref.Get("options")
			Dim MultiItems As List = MultiOptions.Get("items")
			Dim MultiValues As List = Value
			Dim SelectedValues As Map
			SelectedValues.Initialize
			For Each ChoiceObject As Object In MultiValues
				If IsStringObject(ChoiceObject) = False Then Return "Preference " & Id & " choices must be strings."
				Dim Candidate As String = ChoiceObject
				If SelectedValues.ContainsKey(Candidate) Then Return "Preference " & Id & " contains a duplicate choice value."
				SelectedValues.Put(Candidate, True)
				Dim FoundChoice As Boolean = False
				For Each MultiItem As Map In MultiItems
					Dim MultiValue As String = MultiItem.Get("value")
					If MultiValue = Candidate Then FoundChoice = True
				Next
				If FoundChoice = False Then Return "Preference " & Id & " contains an unknown choice value."
			Next
		Case "date"
			If IsStringObject(Value) = False Then Return "Preference " & Id & " must be an ISO yyyy-MM-dd date string."
			Dim DateValue As String = Value
			If Pref.ContainsKey("required") Then
				Dim RequiredDate As Boolean = Pref.Get("required")
				If RequiredDate And DateValue.Length = 0 Then Return "Preference " & Id & " is required."
			End If
			If DateValue <> "" And IsIsoDate(DateValue) = False Then Return "Preference " & Id & " must be a valid ISO yyyy-MM-dd date."
		Case "time"
			If IsStringObject(Value) = False Then Return "Preference " & Id & " must be a 24-hour HH:mm string."
			Dim TimeValue As String = Value
			If Pref.ContainsKey("required") Then
				Dim RequiredTime As Boolean = Pref.Get("required")
				If RequiredTime And TimeValue.Length = 0 Then Return "Preference " & Id & " is required."
			End If
			If TimeValue <> "" And IsValidTime(TimeValue) = False Then Return "Preference " & Id & " must be valid 24-hour HH:mm."
		Case "datetime"
			If IsStringObject(Value) = False Then Return "Preference " & Id & " must be an ISO yyyy-MM-dd'T'HH:mm string."
			Dim DateTimeValue As String = Value
			If Pref.ContainsKey("required") Then
				Dim RequiredDateTime As Boolean = Pref.Get("required")
				If RequiredDateTime And DateTimeValue.Length = 0 Then Return "Preference " & Id & " is required."
			End If
			If DateTimeValue <> "" And IsValidDateTime(DateTimeValue) = False Then Return "Preference " & Id & " must be valid yyyy-MM-dd'T'HH:mm."
	End Select
	Return ""
End Sub

Private Sub CopyMap(Source As Map) As Map
	Dim Result As Map
	Result.Initialize
	For Each Key As String In Source.Keys
		Result.Put(Key, CopyValue(Source.Get(Key)))
	Next
	Return Result
End Sub

Private Sub CopyValue(Value As Object) As Object
	If IsListObject(Value) Then
		Dim SourceList As List = Value
		Dim ResultList As List
		ResultList.Initialize
		For Each Item As Object In SourceList
			ResultList.Add(Item)
		Next
		Return ResultList
	End If
	Return Value
End Sub

Private Sub IsStringObject(Value As Object) As Boolean
	If Value Is String Then Return True
	Return False
End Sub

Private Sub IsNumberObject(Value As Object) As Boolean
	If Value Is Double Then Return True
	If Value Is Int Then Return True
	If Value Is Long Then Return True
	If Value Is Float Then Return True
	Return False
End Sub

Private Sub IsBooleanObject(Value As Object) As Boolean
	If Value Is Boolean Then Return True
	Return False
End Sub

Private Sub IsListObject(Value As Object) As Boolean
	If Value Is List Then Return True
	Return False
End Sub

Private Sub IsIsoDate(Value As String) As Boolean
	Dim PreviousFormat As String = DateTime.DateFormat
	DateTime.DateFormat = "yyyy-MM-dd"
	Try
		Dim Ticks As Long = DateTime.DateParse(Value)
		Dim Normalized As String = DateTime.Date(Ticks)
		DateTime.DateFormat = PreviousFormat
		Return Normalized = Value
	Catch
		DateTime.DateFormat = PreviousFormat
		Return False
	End Try
End Sub

Private Sub IsValidTime(Value As String) As Boolean
	If Value.Length <> 5 Or Value.SubString2(2, 3) <> ":" Then Return False
	Dim HoursText As String = Value.SubString2(0, 2)
	Dim MinutesText As String = Value.SubString2(3, 5)
	If IsAsciiDigits(HoursText) = False Or IsAsciiDigits(MinutesText) = False Then Return False
	Dim Hours As Int = HoursText
	Dim Minutes As Int = MinutesText
	Return Hours >= 0 And Hours <= 23 And Minutes >= 0 And Minutes <= 59
End Sub

Private Sub IsValidDateTime(Value As String) As Boolean
	If Value.Length <> 16 Or Value.SubString2(10, 11) <> "T" Then Return False
	If IsIsoDate(Value.SubString2(0, 10)) = False Then Return False
	Return IsValidTime(Value.SubString2(11, 16))
End Sub

Private Sub IsAsciiDigits(Value As String) As Boolean
	If Value.Length = 0 Then Return False
	For I = 0 To Value.Length - 1
		Dim Code As Int = Asc(Value.SubString2(I, I + 1))
		If Code < 48 Or Code > 57 Then Return False
	Next
	Return True
End Sub
