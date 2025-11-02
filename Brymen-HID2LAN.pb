;- -- Brymen-HID2LAN.

;- -- Version 05.
; Status:			Work in progress.
; Author:			Peter Dreisiebner
; e-mail:			web@dreisiebner.at
; Website:		https://github.com/dreisiebner
; Changed:	2025-11-01 - PureBasic v6.30.
;
; 2025-10-30 - PureBasic v6.30.
;	- Use the dialog library for the main window.
;	- Added help.
; 2025-09-02 - PureBasic v6.30.
;	- Use the new HID library.
;	- Removed support for Windows 2000 and XP.
; 2025-05-04 - PureBasic v6.21.
;	- Error with Raspberry PI fixed. The EventButtonServer() event is triggered twice on exit.
; 2025-05-03 - PureBasic v6.21.
;	- The devices are now opened when the server is started and not every time data is requested.
; - Added support for Windows 2000 and XP. The compiler used is v6.04.
;	2025-04-30 - PureBasic v6.21.
;	- Error message in Hid::BrymenBM86XDecodeDigit() disabled.
;	2025-04-29 - PureBasic v6.21.
;	- Added support for Linux.
; 2025-04-26 - PureBasic v6.21.
;	- Newly created.

EnableExplicit

;-

;- -- Include.

XIncludeFile "ErrorLog.pbi"
XIncludeFile "Common.pbi"
XIncludeFile "BC86X.pbi"
XIncludeFile "WindowMain.pbi"

;-

Procedure.i MainLoop()
	; Program loop for processing the events of the program.
	; Return: Error code for exiting.
	Protected iReturn.i, iEvent.i, iExit.i
	
	Repeat
		iEvent = WaitWindowEvent()
		Select iEvent
					
			Case #PB_Event_CloseWindow
				WindowMain::LanServer(#False)
				iReturn = 0
				iExit = #True
				
		EndSelect
	Until iExit

	ProcedureReturn iReturn
EndProcedure


Procedure.i Main()
	; Start procedure of the program.
	; Return: Error code for exiting.
	Protected iReturn.i
	
	; Open the main window.
	WindowMain::WindowOpen()
	
	; Execute the program loop for processing the events.
	iReturn = MainLoop()
		
	ProcedureReturn iReturn
EndProcedure

;- -- Program start.

CompilerIf #PB_Compiler_OS = #PB_OS_Linux
	UsePNGImageDecoder()
	gtk_window_set_default_icon_(ImageID(CatchImage(#PB_Any, ?ProgramIcon)))
	DataSection
		ProgramIcon:
		IncludeBinary "Logo-blue.png"
	EndDataSection
CompilerEndIf

End Main()

;-
