B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=10.7
@EndOfDesignText@
' JSON definition metadata. This class does not depend on JavaFX controls.
Sub Class_Globals
	Private Root As Map
	Private Preferences As Map
	Private Sections As List
	Public LastError As String
End Sub

Public Sub Initialize
	Root.Initialize
	Preferences.Initialize
	Sections.Initialize
	LastError = ""
End Sub

Public Sub LoadFromJson(JsonText As String) As Boolean
	LastError = ""
	Dim Parsed As Map
	Try
		Dim Parser As JSONParser
		Parser.Initialize(JsonText)
		Parsed = Parser.NextObject
	Catch
		Return Fail("Invalid JSON: " & LastException.Message)
	End Try
	If Parsed.ContainsKey("schemaVersion") = False Then Return Fail("schemaVersion is required.")
	If 1 <> Parsed.Get("schemaVersion") Then Return Fail("Unsupported schemaVersion; expected 1.")
	If Parsed.ContainsKey("id") = False Or IsValidId(Parsed.Get("id")) = False Then Return Fail("id is missing or invalid.")
	If Parsed.ContainsKey("sections") = False Or IsListObject(Parsed.Get("sections")) = False Then Return Fail("sections must be an array.")
	If Parsed.ContainsKey("titleKey") = False Then Parsed.Put("titleKey", Parsed.Get("id"))
	If IsStringObject(Parsed.Get("titleKey")) = False Then Return Fail("titleKey must be a string.")
	Dim NewSections As List = Parsed.Get("sections")
	Dim NewPreferences As Map
	NewPreferences.Initialize
	Dim SectionIds As Map
	SectionIds.Initialize
	For Each SectionObject As Object In NewSections
		If IsMapObject(SectionObject) = False Then Return Fail("Each sections entry must be an object.")
		Dim Section As Map = SectionObject
		If Section.ContainsKey("id") = False Or IsValidId(Section.Get("id")) = False Then Return Fail("Section id is missing or invalid.")
		Dim SectionId As String = Section.Get("id")
		If SectionIds.ContainsKey(SectionId) Then Return Fail("Duplicate section id: " & SectionId)
		SectionIds.Put(SectionId, True)
		If Section.ContainsKey("titleKey") = False Then Section.Put("titleKey", SectionId)
		If IsStringObject(Section.Get("titleKey")) = False Then Return Fail("Section " & SectionId & ": titleKey must be a string.")
		If Section.ContainsKey("preferences") = False Or IsListObject(Section.Get("preferences")) = False Then Return Fail("Section " & SectionId & ": preferences must be an array.")
		Dim Items As List = Section.Get("preferences")
		For Each PrefObject As Object In Items
			If IsMapObject(PrefObject) = False Then Return Fail("Section " & SectionId & " contains a non-object preference.")
			Dim Pref As Map = PrefObject
			If Pref.ContainsKey("id") = False Or IsValidId(Pref.Get("id")) = False Then Return Fail("Preference id is missing or invalid in section " & SectionId)
			Dim PrefId As String = Pref.Get("id")
			If NewPreferences.ContainsKey(PrefId) Then Return Fail("Duplicate preference id: " & PrefId)
			If Pref.ContainsKey("type") = False Or IsSupportedType(Pref.Get("type")) = False Then Return Fail("Preference " & PrefId & ": unsupported type; supported types are text, multiline, password, number, switch, checkbox, and choice.")
			If Pref.ContainsKey("titleKey") = False Or ("" & Pref.Get("titleKey")).Trim.Length = 0 Then Return Fail("Preference " & PrefId & ": titleKey is required.")
			If ValidatePreference(Pref) = False Then Return False
			NewPreferences.Put(PrefId, Pref)
		Next
	Next
	Root = Parsed
	Sections = NewSections
	Preferences = NewPreferences
	Return True
End Sub

Private Sub ValidatePreference(Pref As Map) As Boolean
	Dim Id As String = Pref.Get("id")
	Dim TypeName As String = Pref.Get("type")
	If Pref.ContainsKey("options") And IsMapObject(Pref.Get("options")) = False Then Return Fail("Preference " & Id & ": options must be an object.")
	Dim Options As Map
	Options.Initialize
	If Pref.ContainsKey("options") Then Options = Pref.Get("options")
	If Pref.ContainsKey("defaultValue") = False Then
		Select TypeName
			Case "text", "multiline", "password": Pref.Put("defaultValue", "")
			Case "number": Pref.Put("defaultValue", 0)
			Case "switch", "checkbox": Pref.Put("defaultValue", False)
			Case "choice": Return Fail("Preference " & Id & ": defaultValue is required for choice.")
			Case "multichoice"
				Dim EmptyChoices As List
				EmptyChoices.Initialize
				Pref.Put("defaultValue", EmptyChoices)
		End Select
	End If
	Dim Value As Object = Pref.Get("defaultValue")
	Select TypeName
		Case "text", "multiline", "password"
			If IsStringObject(Value) = False Then Return Fail("Preference " & Id & ": defaultValue must be a string.")
			If ValidateStringConstraints(Pref, Value) = False Then Return False
		Case "number"
			If IsNumberObject(Value) = False Then Return Fail("Preference " & Id & ": defaultValue must be a number.")
			If Options.ContainsKey("min") And IsNumberObject(Options.Get("min")) = False Then Return Fail("Preference " & Id & ": options.min must be a number.")
			If Options.ContainsKey("max") And IsNumberObject(Options.Get("max")) = False Then Return Fail("Preference " & Id & ": options.max must be a number.")
			Dim DefaultNumber As Double = Value
			If Options.ContainsKey("min") Then
				Dim Minimum As Double = Options.Get("min")
				If Options.ContainsKey("max") Then
					Dim Maximum As Double = Options.Get("max")
					If Minimum > Maximum Then Return Fail("Preference " & Id & ": options.min cannot exceed options.max.")
				End If
				If DefaultNumber < Minimum Then Return Fail("Preference " & Id & ": defaultValue is below options.min.")
			End If
			If Options.ContainsKey("max") Then
				Dim MaximumValue As Double = Options.Get("max")
				If DefaultNumber > MaximumValue Then Return Fail("Preference " & Id & ": defaultValue is above options.max.")
			End If
		Case "switch", "checkbox"
			If IsBooleanObject(Value) = False Then Return Fail("Preference " & Id & ": defaultValue must be true or false.")
		Case "choice"
			If IsStringObject(Value) = False Then Return Fail("Preference " & Id & ": choice defaultValue must be a string.")
			Dim ChoiceDefault As String = Value
			If ValidateChoiceItems(Pref, Options) = False Then Return False
			Dim ChoiceValues As List
			ChoiceValues.Initialize
			ChoiceValues.Add(ChoiceDefault)
			If ValidateChoiceValues(Pref, Options, ChoiceValues) = False Then Return False
		Case "multichoice"
			If IsListObject(Value) = False Then Return Fail("Preference " & Id & ": multichoice defaultValue must be an array of strings.")
			If ValidateChoiceItems(Pref, Options) = False Then Return False
			If ValidateChoiceValues(Pref, Options, Value) = False Then Return False
	End Select
	Return True
End Sub

Private Sub ValidateChoiceItems(Pref As Map, Options As Map) As Boolean
	Dim Id As String = Pref.Get("id")
	If Options.ContainsKey("items") = False Or IsListObject(Options.Get("items")) = False Then Return Fail("Preference " & Id & ": options.items must be an array.")
	Dim Items As List = Options.Get("items")
	If Items.Size = 0 Then Return Fail("Preference " & Id & ": options.items cannot be empty.")
	Dim ItemValues As Map
	ItemValues.Initialize
	For Each ItemObject As Object In Items
		If IsMapObject(ItemObject) = False Then Return Fail("Preference " & Id & ": each choice item must be an object.")
		Dim Item As Map = ItemObject
		If Item.ContainsKey("value") = False Or IsStringObject(Item.Get("value")) = False Then Return Fail("Preference " & Id & ": each choice item requires a string value.")
		If Item.ContainsKey("titleKey") = False Or ("" & Item.Get("titleKey")).Trim.Length = 0 Then Return Fail("Preference " & Id & ": each choice item requires titleKey.")
		Dim ItemValue As String = Item.Get("value")
		If ItemValues.ContainsKey(ItemValue) Then Return Fail("Preference " & Id & ": duplicate choice value " & ItemValue)
		ItemValues.Put(ItemValue, True)
	Next
	Return True
End Sub

Private Sub ValidateChoiceValues(Pref As Map, Options As Map, Values As List) As Boolean
	Dim Id As String = Pref.Get("id")
	Dim Items As List = Options.Get("items")
	Dim Seen As Map
	Seen.Initialize
	For Each ValueObject As Object In Values
		If IsStringObject(ValueObject) = False Then Return Fail("Preference " & Id & ": choice values must be strings.")
		Dim Value As String = ValueObject
		If Seen.ContainsKey(Value) Then Return Fail("Preference " & Id & ": duplicate selected value " & Value)
		Seen.Put(Value, True)
		Dim Found As Boolean = False
		For Each ItemObject As Object In Items
			Dim Item As Map = ItemObject
			Dim ItemValue As String = Item.Get("value")
			If Value = ItemValue Then Found = True
		Next
		If Found = False Then Return Fail("Preference " & Id & ": defaultValue contains unknown choice value " & Value)
	Next
	Return True
End Sub

Private Sub ValidateStringConstraints(Pref As Map, Value As String) As Boolean
	Dim Id As String = Pref.Get("id")
	If Pref.ContainsKey("required") And IsBooleanObject(Pref.Get("required")) = False Then Return Fail("Preference " & Id & ": required must be Boolean.")
	If Pref.ContainsKey("required") Then
		Dim RequiredValue As Boolean = Pref.Get("required")
		If RequiredValue And Value.Length = 0 Then Return Fail("Preference " & Id & ": required defaultValue cannot be empty.")
	End If
	If Pref.ContainsKey("minLength") And IsNumberObject(Pref.Get("minLength")) = False Then Return Fail("Preference " & Id & ": minLength must be an integer.")
	If Pref.ContainsKey("maxLength") And IsNumberObject(Pref.Get("maxLength")) = False Then Return Fail("Preference " & Id & ": maxLength must be an integer.")
	Dim Minimum As Int = 0
	Dim Maximum As Int = 2147483647
	If Pref.ContainsKey("minLength") Then
		Dim MinimumNumber As Double = Pref.Get("minLength")
		Minimum = MinimumNumber
		If Minimum <> MinimumNumber Then Return Fail("Preference " & Id & ": minLength must be an integer.")
		If Minimum < 0 Then Return Fail("Preference " & Id & ": minLength cannot be negative.")
	End If
	If Pref.ContainsKey("maxLength") Then
		Dim MaximumNumber As Double = Pref.Get("maxLength")
		Maximum = MaximumNumber
		If Maximum <> MaximumNumber Then Return Fail("Preference " & Id & ": maxLength must be an integer.")
		If Maximum < 0 Then Return Fail("Preference " & Id & ": maxLength cannot be negative.")
	End If
	If Minimum > Maximum Then Return Fail("Preference " & Id & ": minLength cannot exceed maxLength.")
	If Value.Length < Minimum Then Return Fail("Preference " & Id & ": defaultValue is shorter than minLength.")
	If Value.Length > Maximum Then Return Fail("Preference " & Id & ": defaultValue exceeds maxLength.")
	Return True
End Sub

Public Sub GetPreferenceIds As List
	Dim Result As List
	Result.Initialize
	For Each Id As String In Preferences.Keys
		Result.Add(Id)
	Next
	Return Result
End Sub

Public Sub GetSections As List
	Return Sections
End Sub

Public Sub GetPreference(Id As String) As Map
	If Preferences.ContainsKey(Id) Then Return Preferences.Get(Id)
	Return Null
End Sub

Public Sub GetDefinitionId As String
	If Root.ContainsKey("id") Then Return Root.Get("id")
	Return ""
End Sub

Public Sub GetTitleKey As String
	If Root.ContainsKey("titleKey") Then Return Root.Get("titleKey")
	Return ""
End Sub

Private Sub Fail(Message As String) As Boolean
	LastError = Message
	Return False
End Sub

Private Sub IsValidId(Value As Object) As Boolean
	If IsStringObject(Value) = False Then Return False
	Dim S As String = Value
	If S.Length = 0 Then Return False
	For I = 0 To S.Length - 1
		Dim Code As Int = Asc(S.SubString2(I, I + 1))
		Dim Letter As Boolean = (Code >= 97 And Code <= 122) Or (Code >= 65 And Code <= 90)
		Dim Digit As Boolean = Code >= 48 And Code <= 57
		If I = 0 And Letter = False Then Return False
		If Letter = False And Digit = False And Code <> 95 And Code <> 46 And Code <> 45 Then Return False
	Next
	Return True
End Sub

Private Sub IsSupportedType(Value As Object) As Boolean
	If IsStringObject(Value) = False Then Return False
	Dim T As String = Value
	Return T = "text" Or T = "multiline" Or T = "password" Or T = "number" Or T = "switch" Or T = "checkbox" Or T = "choice" Or T = "multichoice"
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

Private Sub IsMapObject(Value As Object) As Boolean
	If Value Is Map Then Return True
	Return False
End Sub
