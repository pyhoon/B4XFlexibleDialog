B4J=true
Group=Classes
ModulesStructureVersion=1
Type=Class
Version=10.7
@EndOfDesignText@
' Platform-independent self test for the preference model, controller,
' localization, theme and store. Uses only B4X core keywords and the
' shared modules, so the same source validates on B4J, B4A and B4i.
' RunAll uses an embedded minimal definition and returns a result Map:
' {"passed": Int, "failed": Int, "log": String}
Sub Class_Globals
	Private Passed As Int
	Private Failed As Int
	Private LogBuilder As StringBuilder
End Sub

Public Sub Initialize
	Passed = 0
	Failed = 0
	LogBuilder.Initialize
End Sub

Public Sub RunAll As Map
	Passed = 0
	Failed = 0
	LogBuilder.Initialize
	Dim Definition As String = TestDefinition
	RunModelChecks(Definition)
	RunControllerChecks(Definition)
	RunLocalizationChecks
	RunThemeChecks
	RunStoreChecks(Definition)
	Dim Result As Map
	Result.Initialize
	Result.Put("passed", Passed)
	Result.Put("failed", Failed)
	Result.Put("log", LogBuilder.ToString)
	Return Result
End Sub

Private Sub TestDefinition As String
	Return "{""schemaVersion"":1,""id"":""selftest"",""titleKey"":""selftest"",""sections"":[{""id"":""s1"",""titleKey"":""s1"",""preferences"":[{""id"":""username"",""type"":""text"",""titleKey"":""username"",""defaultValue"":""Guest"",""required"":true,""minLength"":3,""maxLength"":32},{""id"":""items_per_page"",""type"":""number"",""titleKey"":""ipp"",""defaultValue"":20,""options"":{""min"":5,""max"":200}},{""id"":""dark_mode"",""type"":""switch"",""titleKey"":""dm"",""defaultValue"":false},{""id"":""display_mode"",""type"":""choice"",""titleKey"":""dmode"",""defaultValue"":""compact"",""options"":{""items"":[{""value"":""compact"",""titleKey"":""c""},{""value"":""comfortable"",""titleKey"":""cf""}]}},{""id"":""note"",""type"":""label"",""titleKey"":""note""},{""id"":""run"",""type"":""action"",""titleKey"":""run""}]}]}"
End Sub

Private Sub RunModelChecks(Definition As String)
	Dim Model As PrefsModel
	Model.Initialize
	Check("valid self-test definition", Model.LoadFromJson(Definition))
	Dim Bad As PrefsModel
	Bad.Initialize
	Check("malformed JSON rejected", Bad.LoadFromJson("{") = False)
	Bad.Initialize
	Check("unknown type rejected", Bad.LoadFromJson("{""schemaVersion"":1,""id"":""x"",""sections"":[{""id"":""s"",""preferences"":[{""id"":""x"",""type"":""widget"",""titleKey"":""a""}]}]}") = False)
	Bad.Initialize
	Check("duplicate IDs rejected", Bad.LoadFromJson("{""schemaVersion"":1,""id"":""x"",""sections"":[{""id"":""s"",""preferences"":[{""id"":""dup"",""type"":""text"",""titleKey"":""a""},{""id"":""dup"",""type"":""text"",""titleKey"":""b""}]}]}") = False)
End Sub

Private Sub RunControllerChecks(Definition As String)
	Dim Model As PrefsModel
	Model.Initialize
	Model.LoadFromJson(Definition)
	Dim Values As PrefsController
	Values.Initialize(Model)
	Dim DefaultName As String = Values.GetValue("username")
	Dim DefaultNumber As Double = Values.GetValue("items_per_page")
	Check("defaults loaded", DefaultName = "Guest" And DefaultNumber = 20)
	Dim SetOk As Boolean = Values.SetValue("username", "Test")
	Dim ChangedName As String = Values.GetValue("username")
	Check("typed set/get", SetOk And ChangedName = "Test")
	Check("required text rejected", Values.SetValue("username", "") = False)
	Check("short text rejected", Values.SetValue("username", "Al") = False)
	Check("number bounds enforced", Values.SetValue("items_per_page", 999) = False)
	Check("switch value type", Values.SetValue("dark_mode", True) And Values.GetValue("dark_mode") = True)
	Check("choice value type", Values.SetValue("display_mode", "comfortable") And Values.GetValue("display_mode") = "comfortable")
	Check("action stores no value", Values.SetValue("run", "x") = False)
	Values.BeginDraft
	Values.SetDraftValue("username", "Discard me")
	Values.CancelDraft
	Dim CurrentName As String = Values.GetValue("username")
	Check("draft cancel keeps committed value", CurrentName = "Test")
	Values.BeginDraft
	Values.SetDraftValue("username", "Committed")
	Values.CommitDraft
	CurrentName = Values.GetValue("username")
	Check("draft commit updates value", CurrentName = "Committed")
	Dim Snapshot As Map = Values.GetValues
	Snapshot.Put("username", "Mutated")
	CurrentName = Values.GetValue("username")
	Check("GetValues returns snapshot", CurrentName = "Committed")
	Values.SetValue("items_per_page", 42)
	Values.ResetPreference("items_per_page")
	Dim ResetNumber As Double = Values.GetValue("items_per_page")
	Check("ResetPreference restores default", ResetNumber = 20)
	Values.ResetToDefaults
	Dim ResetName As String = Values.GetValue("username")
	Check("ResetToDefaults restores defaults", ResetName = "Guest")
End Sub

Private Sub RunLocalizationChecks
	Dim L As PrefsLocalization
	L.Initialize
	Dim EnDict As Map
	EnDict.Initialize
	EnDict.Put("settings.title", "Settings")
	Dim MsDict As Map
	MsDict.Initialize
	MsDict.Put("settings.title", "Tetapan")
	L.SetDictionary("en", EnDict)
	L.SetDictionary("ms", MsDict)
	L.SetLanguage("en")
	Check("localization resolves selected dictionary", L.Text("settings.title") = "Settings")
	L.SetLanguage("ms")
	Check("language change switches dictionary", L.Text("settings.title") = "Tetapan")
	Check("missing key falls back to key", L.Text("no.such.key") = "no.such.key")
End Sub

Private Sub RunThemeChecks
	Dim Light As PrefsTheme
	Light.Initialize(False)
	Dim Dark As PrefsTheme
	Dark.Initialize(True)
	Check("light theme initializes", Light.IsDark = False)
	Check("dark theme initializes", Dark.IsDark)
	Dark.Toggle
	Check("theme toggle flips state", Dark.IsDark = False)
End Sub

Private Sub RunStoreChecks(Definition As String)
	Dim S As PrefsStore
	S.Initialize
	S.SetValue("legacy_key", "keep me")
	Dim Committed As Map
	Committed.Initialize
	Committed.Put("username", "StoredUser")
	Committed.Put("items_per_page", 50)
	S.Save(Committed)
	Check("store merges known values", S.GetValue("username") = "StoredUser")
	Dim Legacy As String = S.GetValue("legacy_key")
	Check("store preserves unknown keys", S.ContainsKey("legacy_key") And Legacy = "keep me")
	Dim Json As String = S.ToJson
	Dim S2 As PrefsStore
	S2.Initialize
	Check("store round-trips through JSON", S2.FromJson(Json))
	Check("store JSON preserves unknown keys", S2.GetValue("legacy_key") = "keep me")
	Dim StoreModel As PrefsModel
	StoreModel.Initialize
	StoreModel.LoadFromJson(Definition)
	Dim StoreController As PrefsController
	StoreController.Initialize(StoreModel)
	Dim Applied As Int = StoreController.ApplyValues(S2.Load)
	Check("ApplyValues applies known stored keys", Applied = 2 And StoreController.GetValue("username") = "StoredUser")
	Check("ApplyValues keeps defaults for missing keys", StoreController.GetValue("dark_mode") = False)
End Sub

Private Sub Check(Name As String, Condition As Boolean)
	If Condition Then
		Passed = Passed + 1
		LogBuilder.Append("PASS: ")
		LogBuilder.Append(Name)
		LogBuilder.Append(CRLF)
	Else
		Failed = Failed + 1
		LogBuilder.Append("FAIL: ")
		LogBuilder.Append(Name)
		LogBuilder.Append(CRLF)
	End If
End Sub
