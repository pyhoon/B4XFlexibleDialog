B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=10.7
@EndOfDesignText@
' Public B4J facade for a JSON-backed modal preferences dialog.
Sub Class_Globals
	Private Callback As Object
	Private EventPrefix As String
	Private OwnerForm As Form
	Private Model As PrefsModel
	Private Controller As PrefsController
	Private Localization As PrefsLocalization
	Private CurrentTheme As PrefsTheme
	Private Ready As Boolean
	Public LastError As String
End Sub

Public Sub Initialize(EventTarget As Object, EventName As String, Owner As Form)
	Callback = EventTarget
	EventPrefix = EventName
	OwnerForm = Owner
	Model.Initialize
	Controller.Initialize(Model)
	Localization.Initialize
	CurrentTheme.Initialize(False)
	Ready = False
	LastError = ""
End Sub

Public Sub LoadDefinition(DefinitionJson As String) As Boolean
	Dim NewModel As PrefsModel
	NewModel.Initialize
	If NewModel.LoadFromJson(DefinitionJson) = False Then
		LastError = NewModel.LastError
		Ready = False
		Return False
	End If
	Model = NewModel
	Controller.Initialize(Model)
	Ready = True
	LastError = ""
	Return True
End Sub

Public Sub SetDictionary(Language As String, Values As Map)
	Localization.SetDictionary(Language, Values)
End Sub

Public Sub SetLanguage(Language As String)
	Localization.SetLanguage(Language)
End Sub

Public Sub GetLanguage As String
	Return Localization.GetLanguage
End Sub

Public Sub SetTheme(Value As PrefsTheme)
	CurrentTheme = Value
End Sub

Public Sub CreateLightTheme As PrefsTheme
	Dim Value As PrefsTheme
	Value.Initialize(False)
	Return Value
End Sub

Public Sub CreateDarkTheme As PrefsTheme
	Dim Value As PrefsTheme
	Value.Initialize(True)
	Return Value
End Sub

Public Sub IsDarkTheme As Boolean
	Return CurrentTheme.IsDark
End Sub

Public Sub SetValue(Id As String, Value As Object) As Boolean
	If CheckReady = False Then Return False
	If Controller.SetValue(Id, Value) = False Then
		LastError = Controller.LastError
		Return False
	End If
	LastError = ""
	Return True
End Sub

Public Sub GetValue(Id As String) As Object
	If Ready = False Then Return Null
	Return Controller.GetValue(Id)
End Sub

Public Sub GetValues As Map
	If Ready = False Then
		Dim Empty As Map
		Empty.Initialize
		Return Empty
	End If
	Return Controller.GetValues
End Sub

Public Sub Show
	If CheckReady = False Then
		LogError(LastError)
		Return
	End If
	Dim Dialog As PrefsDialog
	Dialog.Initialize(OwnerForm, Controller, Model, Localization, CurrentTheme, Callback, EventPrefix)
	Dim WasSaved As Boolean = Dialog.Show
	CallSub2(Callback, EventPrefix & "_DialogClosed", WasSaved)
End Sub

Private Sub CheckReady As Boolean
	If Ready = False Then
		LastError = "LoadDefinition must succeed before accessing preference values or showing the dialog."
		Return False
	End If
	Return True
End Sub
