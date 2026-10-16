B4A=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=9.85
@EndOfDesignText@

' Launcher page for the B4XPages demo. B4J-only for now: the hosted settings
' page needs a native AnchorPane, which only exists on B4J. The B4XPages
' structure (manager plus shared page class) allows B4A/B4i folders to be
' added later once the facade supports those platforms.
Sub Class_Globals
	Private Root As B4XView
	Private TitleLabel As Label
	Private DialogButton As Button
	Private PageHost As AnchorPane
End Sub

Public Sub Initialize
End Sub

'This event will be called once, before the page becomes visible.
Private Sub B4XPage_Created (Root1 As B4XView)
	Root = Root1
	TitleLabel.Initialize("")
	TitleLabel.Text = "B4XFlexibleDialog"
	Dim TitleView As B4XView = TitleLabel
	Root.AddView(TitleView, 20, 20, 400, 40)
	DialogButton.Initialize("PageDialog")
	DialogButton.Text = "Open preferences dialog"
	Dim ButtonView As B4XView = DialogButton
	Root.AddView(ButtonView, 20, 70, 300, 50)
	PageHost.Initialize("")
	Dim HostView As B4XView = PageHost
	Root.AddView(HostView, 340, 20, Root.Width - 360, Root.Height - 40)
	Main.ShowPrefsPage(PageHost)
End Sub

Private Sub PageDialog_Click
	Main.ShowPrefsDialog
End Sub
