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
	Public LastError As String
End Sub

Public Sub Initialize(Definition As PrefsModel)
	Model = Definition
	Committed.Initialize
	Draft.Initialize
	HasDraft = False
	For Each Id As String In Model.GetPreferenceIds
		Dim Pref As Map = Model.GetPreference(Id)
		Committed.Put(Id, Pref.Get("defaultValue"))
	Next
End Sub

Public Sub SetValue(Id As String, Value As Object) As Boolean
	LastError = ValidateValue(Id, Value)
	If LastError <> "" Then Return False
	Committed.Put(Id, Value)
	Return True
End Sub

Public Sub GetValue(Id As String) As Object
	If Committed.ContainsKey(Id) Then Return Committed.Get(Id)
	Return Null
End Sub

Public Sub GetValues As Map
	Return CopyMap(Committed)
End Sub

Public Sub BeginDraft
	Draft = CopyMap(Committed)
	HasDraft = True
End Sub

Public Sub SetDraftValue(Id As String, Value As Object) As Boolean
	If HasDraft = False Then BeginDraft
	LastError = ValidateValue(Id, Value)
	If LastError <> "" Then Return False
	Draft.Put(Id, Value)
	Return True
End Sub

Public Sub GetDraftValues As Map
	If HasDraft = False Then BeginDraft
	Return CopyMap(Draft)
End Sub

Public Sub ValidateDraft As String
	If HasDraft = False Then BeginDraft
	For Each Id As String In Model.GetPreferenceIds
		If Draft.ContainsKey(Id) = False Then Return "Missing draft value for " & Id
		Dim ErrorText As String = ValidateValue(Id, Draft.Get(Id))
		If ErrorText <> "" Then Return ErrorText
	Next
	Return ""
End Sub

Public Sub CommitDraft
	Committed = CopyMap(Draft)
	HasDraft = False
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
		Case "text"
			If IsStringObject(Value) = False Then Return "Preference " & Id & " must be text."
		Case "number"
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
		Case "switch"
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
	End Select
	Return ""
End Sub

Private Sub CopyMap(Source As Map) As Map
	Dim Result As Map
	Result.Initialize
	For Each Key As String In Source.Keys
		Result.Put(Key, Source.Get(Key))
	Next
	Return Result
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
