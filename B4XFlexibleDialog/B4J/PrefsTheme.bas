B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=10.7
@EndOfDesignText@
Sub Class_Globals
	Public BackgroundColor As Int
	Public TextColor As Int
	Public SecondaryTextColor As Int
	Public AccentColor As Int
	Public InputBackgroundColor As Int
	Public InputBorderColor As Int
	Public SecondaryButtonBackgroundColor As Int
	Public SecondaryButtonTextColor As Int
	Public PrimaryButtonTextColor As Int
	Public RowSpacing As Int
	Public SectionSpacing As Int
	Public ButtonStyle As String
End Sub

Public Sub Initialize(Dark As Boolean)
	ApplyTheme(Dark)
	RowSpacing = 12
	SectionSpacing = 18
	ButtonStyle = "-fx-font-weight: bold;"
End Sub

Private Sub ApplyTheme(Dark As Boolean)
	If Dark Then
		BackgroundColor = -13619152
		TextColor = -986896
		SecondaryTextColor = -5197648
		AccentColor = -7686920
		InputBackgroundColor = -12434878
		InputBorderColor = -9408400
		SecondaryButtonBackgroundColor = -12040120
		SecondaryButtonTextColor = -986896
		PrimaryButtonTextColor = -14671580
	Else
		BackgroundColor = -1
		TextColor = -14540254
		SecondaryTextColor = -10066330
		AccentColor = -14856488
		InputBackgroundColor = -1
		InputBorderColor = -6381922
		SecondaryButtonBackgroundColor = -1710101
		SecondaryButtonTextColor = -14735049
		PrimaryButtonTextColor = -1
	End If
End Sub

Public Sub IsDark As Boolean
	Return BackgroundColor = -13619152
End Sub

Public Sub Toggle
	If IsDark Then
		ApplyTheme(False)
	Else
		ApplyTheme(True)
	End If
End Sub
