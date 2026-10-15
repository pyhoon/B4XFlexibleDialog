B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=10.7
@EndOfDesignText@
' Normalized file/directory selection result.
' A successful selection sets Success=True and provides the best available locator.
' Cancelled selections set Success=False and Cancelled=True, and carry no path.
Sub Class_Globals
	Public Success As Boolean
	Public Cancelled As Boolean
	Public Path As String
	Public Uri As String
	Public DisplayName As String
	Public MimeType As String
	Public Access As String
	Public Message As String
End Sub

Public Sub Initialize
	Success = False
	Cancelled = False
	Path = ""
	Uri = ""
	DisplayName = ""
	MimeType = ""
	Access = ""
	Message = ""
End Sub

Public Sub SetSelected(SelectedPath As String, SelectedUri As String, SelectedName As String, SelectedMime As String, SelectedAccess As String)
	Success = True
	Cancelled = False
	Path = SelectedPath
	Uri = SelectedUri
	DisplayName = SelectedName
	MimeType = SelectedMime
	Access = SelectedAccess
	Message = ""
End Sub

Public Sub SetCancelled
	Success = False
	Cancelled = True
	Path = ""
	Uri = ""
	DisplayName = ""
	MimeType = ""
	Access = ""
	Message = ""
End Sub

Public Sub SetFailed(ErrorMessage As String)
	Success = False
	Cancelled = False
	Path = ""
	Uri = ""
	DisplayName = ""
	MimeType = ""
	Access = ""
	Message = ErrorMessage
End Sub

' Preferred locator: the filesystem path when available, otherwise the URI.
Public Sub Locator As String
	If Path <> "" Then Return Path
	Return Uri
End Sub
