B4J=true
Group=Classes
ModulesStructureVersion=1
Type=Class
Version=10.7
@EndOfDesignText@
Sub Class_Globals
	Private Dictionaries As Map
	Private CurrentLanguage As String
End Sub

Public Sub Initialize
	Dictionaries.Initialize
	CurrentLanguage = ""
End Sub

Public Sub SetDictionary(Language As String, Values As Map)
	Dictionaries.Put(Language, Values)
End Sub

Public Sub SetLanguage(Language As String)
	CurrentLanguage = Language
End Sub

Public Sub GetLanguage As String
	Return CurrentLanguage
End Sub

Public Sub ToggleLanguage
	If CurrentLanguage = "en" And Dictionaries.ContainsKey("ms") Then
		CurrentLanguage = "ms"
	Else If Dictionaries.ContainsKey("en") Then
		CurrentLanguage = "en"
	Else If Dictionaries.Size > 0 Then
		For Each Language As String In Dictionaries.Keys
			CurrentLanguage = Language
			Exit
		Next
	End If
End Sub

Public Sub Text(Key As String) As String
	If Dictionaries.ContainsKey(CurrentLanguage) Then
		Dim Values As Map = Dictionaries.Get(CurrentLanguage)
		If Values.ContainsKey(Key) Then Return Values.Get(Key)
	End If
	Return Key
End Sub
