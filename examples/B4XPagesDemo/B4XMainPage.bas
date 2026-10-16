B4A=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=9.85
@EndOfDesignText@

' Shared B4XPages launcher page. It builds its UI in code with cross-platform
' views and talks to the app only through the AppHost code module, so the same
' source runs on B4J and B4A. Each project supplies its own AppHost: B4J mounts
' the facade page and can open the modal dialog; B4A renders the form into the
' host and owns Save/Cancel (its renderer has no built-in chrome).
Sub Class_Globals
	Private Root As B4XView
	Private xui As XUI
	Private TitleLabel As Label
	Private PageHost As B4XView
	#If B4J
	Private DialogButton As Button
	#End If
	#If B4A
	Private SaveButton As Button
	Private CancelButton As Button
	#End If
End Sub

Public Sub Initialize
End Sub

'This event will be called once, before the page becomes visible.
Private Sub B4XPage_Created (Root1 As B4XView)
	Root = Root1
	TitleLabel.Initialize("")
	TitleLabel.Text = "B4XFlexibleDialog"
	TitleLabel.TextSize = 22
	Root.AddView(TitleLabel, 20dip, 16dip, 440dip, 36dip)

	#If B4J
	DialogButton.Initialize("DialogButton")
	DialogButton.Text = "Open preferences dialog"
	Root.AddView(DialogButton, 20dip, 64dip, 300dip, 48dip)
	#End If

	#If B4A
	SaveButton.Initialize("SaveButton")
	SaveButton.Text = "Save"
	Root.AddView(SaveButton, 20dip, 64dip, 145dip, 44dip)
	CancelButton.Initialize("CancelButton")
	CancelButton.Text = "Cancel"
	Root.AddView(CancelButton, 175dip, 64dip, 145dip, 44dip)
	#End If

	CreatePageHost
	Root.AddView(PageHost, 340dip, 16dip, Max(200dip, Root.Width - 360dip), Max(240dip, Root.Height - 32dip))
	AppHost.ShowPrefsPage(PageHost)
End Sub

Private Sub CreatePageHost
	#If B4J
		Dim Anchor As AnchorPane
		Anchor.Initialize("pageHost")
		PageHost = Anchor
	#Else
		PageHost = xui.CreatePanel("pageHost")
	#End If
End Sub

#If B4J
Private Sub DialogButton_Click
	AppHost.ShowPrefsDialog
End Sub
#End If

#If B4A
Private Sub SaveButton_Click
	AppHost.SavePrefs
End Sub

Private Sub CancelButton_Click
	AppHost.CancelPrefs
End Sub
#End If
