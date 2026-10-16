B4A=true
Group=Services
ModulesStructureVersion=1
Type=Service
Version=14.2
@EndOfDesignText@
#Region  Service Attributes 
	#StartAtBoot: False
#End Region

Sub Process_Globals
End Sub

Sub Service_Create
End Sub

Sub Service_Start (StartingIntent As Intent)
	Service.StopAutomaticForeground
End Sub

Sub Service_Destroy
End Sub
