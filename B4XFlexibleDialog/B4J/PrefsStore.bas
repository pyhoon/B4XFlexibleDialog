B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=10.7
@EndOfDesignText@
' Persistence adapter. Holds a stored value map independent of the controller.
' Saving merges known values into the stored map and preserves unknown stored keys.
Sub Class_Globals
	Private Values As Map
	Private SchemaVersionValue As Int
End Sub

Public Sub Initialize
	Values.Initialize
	SchemaVersionValue = 1
End Sub

Public Sub InitializeFromMap(Source As Map)
	Values.Initialize
	For Each Key As String In Source.Keys
		Values.Put(Key, CopyValue(Source.Get(Key)))
	Next
	SchemaVersionValue = 1
End Sub

' Returns a copy of the stored map. Unknown keys are included.
Public Sub Load As Map
	Return CopyMap(Values)
End Sub

' Merges the given values into the store. Keys not present in NewValues are preserved.
Public Sub Save(NewValues As Map)
	For Each Key As String In NewValues.Keys
		Values.Put(Key, CopyValue(NewValues.Get(Key)))
	Next
End Sub

Public Sub SetValue(Id As String, Value As Object)
	Values.Put(Id, CopyValue(Value))
End Sub

Public Sub GetValue(Id As String) As Object
	If Values.ContainsKey(Id) Then Return CopyValue(Values.Get(Id))
	Return Null
End Sub

Public Sub ContainsKey(Id As String) As Boolean
	Return Values.ContainsKey(Id)
End Sub

Public Sub Remove(Id As String)
	Values.Remove(Id)
End Sub

Public Sub Clear
	Values.Clear
End Sub

Public Sub Count As Int
	Return Values.Size
End Sub

Public Sub SetSchemaVersion(Version As Int)
	SchemaVersionValue = Version
End Sub

Public Sub GetSchemaVersion As Int
	Return SchemaVersionValue
End Sub

Public Sub ToJson As String
	Dim Generator As JSONGenerator
	Generator.Initialize(Values)
	Return Generator.ToPrettyString(2)
End Sub

Public Sub FromJson(JsonText As String) As Boolean
	Try
		Dim Parser As JSONParser
		Parser.Initialize(JsonText)
		Dim Parsed As Map = Parser.NextObject
		Values.Initialize
		For Each Key As String In Parsed.Keys
			Values.Put(Key, CopyValue(Parsed.Get(Key)))
		Next
		Return True
	Catch
		Return False
	End Try
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
	If Value Is List Then
		Dim SourceList As List = Value
		Dim ResultList As List
		ResultList.Initialize
		For Each Item As Object In SourceList
			ResultList.Add(CopyValue(Item))
		Next
		Return ResultList
	End If
	If Value Is Map Then
		Dim SourceMap As Map = Value
		Dim ResultMap As Map
		ResultMap.Initialize
		For Each Key As String In SourceMap.Keys
			ResultMap.Put(Key, CopyValue(SourceMap.Get(Key)))
		Next
		Return ResultMap
	End If
	Return Value
End Sub
