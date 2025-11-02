;- -- DeclareModule --
DeclareModule WindowMain
	EnableExplicit
	
	;- -- Declare.

	Declare WindowOpen()
	Declare LanServer(fEnable.i)
	
EndDeclareModule


;- -- Module --
Module WindowMain
	UseModule Common
	
	;- -- Constant.
	
	#sWindowTitle = #PB_Editor_FileDescription + " v" + #PB_Editor_FileVersion
	#iWindowWidth = 500
	#iWindowHeight = 260
	#sLogDateMask = "  %hh:%ii:%ss" + #TAB$
	
	;- eWindow.
Runtime	Enumeration eWindow
		#eWindowNone
		#eWindowMain
		#eXmlDialogMain
	EndEnumeration
	
	;- eGadget.
	Runtime Enumeration eGadget
		#eGadgetNone
		; Panel Setup.
		#eGadgetPanel
		#eGadgetButtonRefresh
		#eGadgetListIconDevice
		#eGadgetButtonStart
		#eGadgetIpAddress
		#eGadgetStringPort
		; Panel Log.
		#eGadgetButtonTest
		#eGadgetButtonClear
		#eGadgetCheckboxDebug
		#eGadgetEditorLog
		#eGadgetEditorHelp
		; Helper.
		#eGadgetButtonTextWidth
	EndEnumeration
	
	;- ePanel.
	Enumeration ePanel
		#ePanelSetup
		#ePanelLog
		#ePanelHelp
	EndEnumeration
	
	;- eColumnDevice.
	Enumeration eColumnDevice
		#eColumnDeviceName
		#eColumnDeviceVid
		#eColumnDevicePid
		#eColumnDeviceRev
		#eColumnDeviceSerial
		#eColumnDevicePath
	EndEnumeration
	
	;- -- Structure.
	
	;- uDevice.
	Structure uDevice
		sName.s
		sPath.s
		iHandle.i
	EndStructure
	
	;- uLanServerThreadData.
	Structure uLanServerThreadData
		iThreadNumber.i
		iIpAddress.i
		iPort.i
		fExit.i
		iError.i
		List uDeviceList.uDevice()
		sMainValue.s
		sMainUnit.s
		sSecondValue.s
		sSecondUnit.s
	EndStructure
	
	;- -- Variable.
	
	Global guLanServerThreadData.uLanServerThreadData
	Global gfDebug.i
	
	;- -- Declare.
	
	Declare RefreshDeviceList()
	Declare TestDevices()
	Declare LanServer(fEnable.i)
	Declare LanServerThread(*uThreadData.uLanServerThreadData)
	Declare.s ProcessCommand(sCommand.s, *uThreadData.uLanServerThreadData)
	
	;- -- Event-Procedure.
	
	Runtime	Procedure EventButtonStart()
		Protected fEnable.i
		
		fEnable = GetGadgetState(#eGadgetButtonStart)
		If fEnable
			SetGadgetText(#eGadgetButtonStart, "Stop")
		Else
			SetGadgetText(#eGadgetButtonStart, "Start")
		EndIf
		DisableGadget(#eGadgetButtonRefresh, fEnable)
		DisableGadget(#eGadgetButtonTest, fEnable)
		DisableGadget(#eGadgetListIconDevice, fEnable)
		DisableGadget(#eGadgetIpAddress, fEnable)
		DisableGadget(#eGadgetStringPort, fEnable)
		LanServer(fEnable)
	EndProcedure	
	
	
	Runtime Procedure EventButtonRefresh()
		RefreshDeviceList()
	EndProcedure
	
	
	Runtime	Procedure EventButtonTest()
		TestDevices()
	EndProcedure


	Runtime	Procedure EventButtonClear()
		ClearGadgetItems(#eGadgetEditorLog)
	EndProcedure


	Runtime	Procedure EventCheckboxDebug()
		gfDebug = Bool(Not gfDebug)
	EndProcedure
	
	
	Procedure EventCustomServerExit()
		Protected sText.s

		SetGadgetState(#eGadgetButtonStart, #False)
		PostEvent(#PB_Event_Gadget, #eWindowMain, #eGadgetButtonStart, #PB_EventType_LeftClick)

		sText = FormatDate(#sLogDateMask, Date()) + "The server has been stopped."
		AddGadgetItem(#eGadgetEditorLog, -1, sText)
		EditorScrollToBottom(#eGadgetEditorLog)
	EndProcedure
	
	
	Procedure EventCustomServerError()
		Protected sText.s

		If EventType()
			SetGadgetState(#eGadgetButtonStart, #False)
			PostEvent(#PB_Event_Gadget, #eWindowMain, #eGadgetButtonStart, #PB_EventType_LeftClick)
		EndIf
		
		sText = FormatDate(#sLogDateMask, Date()) + ErrorLog::GetErrorText(EventData())
		AddGadgetItem(#eGadgetEditorLog, -1, sText)
		EditorScrollToBottom(#eGadgetEditorLog)
	EndProcedure


	Procedure EventCustomLog()
		Protected iEventData.i, uError.ErrorLog::uError
		Static iLines.i
		
		iEventData = EventData()
		If iLines > 1000
			ClearGadgetItems(#eGadgetEditorLog)
			iLines = 0
		EndIf
		While ErrorLog::GetError(iEventData, @uError)
			AddGadgetItem(#eGadgetEditorLog, -1, FormatDate(#sLogDateMask, Date()) + uError\sDescription)
			iLines + 1
		Wend
		EditorScrollToBottom(#eGadgetEditorLog)
	EndProcedure
	
	;- -- Procedure.

	Procedure.i WindowOpen()
		Protected iReturn.i, iXml.i
		
		DataSection
			DialogXmlFile:
			IncludeBinary "WindowMain.xml"	; UTF8 with BOM.
			DialogXmlFileEnd:
			DialogHelpFile:
			IncludeBinary "Help.txt"	; UTF8 with BOM.
			Data.w 0
		EndDataSection
			
; 		If CreateDialog(#eWindowMain)
		If CreateDialog(#eXmlDialogMain)
			iXml = CatchXML(#PB_Any, ?DialogXmlFile, ?DialogXmlFileEnd - ?DialogXmlFile)
			If iXml
				If Not XMLStatus(iXml) = #PB_XML_Success
					Debug "Error CatchXML(): " + XMLError(iXml)
					Debug "Error Line: " + XMLErrorLine(iXml) + " -  Position: " + XMLErrorPosition(iXml)
				Else
; 					If Not OpenXMLDialog(#eWindowMain, iXml, "WindowMain",
					If Not OpenXMLDialog(#eXmlDialogMain, iXml, "WindowMain",
						#PB_Default, #PB_Default, #iWindowWidth, #iWindowHeight)
						Debug "Error OpenXMLDialog(): " + DialogError(#eWindowMain)
					Else

						SetWindowTitle(#eWindowMain, #sWindowTitle)

						; Setup.						
						SetGadgetItemAttribute(#eGadgetListIconDevice, #PB_Ignore, #PB_ListIcon_ColumnWidth, 60, 0)
						AddGadgetColumn(#eGadgetListIconDevice, #eColumnDeviceVid, "VID", 40)
						AddGadgetColumn(#eGadgetListIconDevice, #eColumnDevicePid, "PID", 40)
						AddGadgetColumn(#eGadgetListIconDevice, #eColumnDeviceRev, "Rev", 45)
						AddGadgetColumn(#eGadgetListIconDevice, #eColumnDeviceSerial, "Serial", 85)
						AddGadgetColumn(#eGadgetListIconDevice, #eColumnDevicePath, "Path", 540)
						
						GadgetToolTip(#eGadgetButtonStart, "Start/Stop the network server.")

						SetGadgetState(#eGadgetIpAddress, MakeIPAddress(0, 0, 0, 0))
						GadgetToolTip(#eGadgetIpAddress,
							"Use the IP address 0.0.0.0 to enable external access to all network interfaces.")

						SetGadgetText(#eGadgetStringPort, "5025")
						GadgetToolTip(#eGadgetStringPort, "IP port number.")
						
						GadgetToolTip(#eGadgetButtonRefresh, "Search for Brymen BC-86X/P adapters.")
						
						; Log.
						GadgetToolTip(#eGadgetButtonTest, "Read in values from each selected adapter and output it in the log.")
						GadgetToolTip(#eGadgetButtonClear, "Clears the log.")
						GadgetToolTip(#eGadgetCheckboxDebug, "Displays the received and transmitted network data.")

						; Help.
						SetGadgetText(#eGadgetEditorHelp, PeekS(?DialogHelpFile, -1, #PB_UTF8))
						
						; Refresh device list.
						PostEvent(#PB_Event_Gadget, #eWindowMain, #eGadgetButtonRefresh, #PB_EventType_LeftClick)
						
						BindEvent(#eEventCustomLog, @EventCustomLog(), #eWindowMain)
						
						iReturn = #True
					EndIf
				EndIf
			EndIf
		EndIf
		
		ProcedureReturn iReturn
	EndProcedure


	Procedure RefreshDeviceList()
		Protected iError.i, sText.s, sDate.s, iCount.i, iName.i, c.i, sTemp.s
		Protected NewList uDeviceList.Hid::uDevice()
		Protected iWidth.i, iWidthName.i, iWidthVid.i, iWidthPid.i, iWidthRev.i, iWidthSerial.i, iWidthPath.i
		
		ClearGadgetItems(#eGadgetListIconDevice)
		sDate = FormatDate(#sLogDateMask, Date())
		
		ExamineHIDs(Hid::#iBrymenBC86XVid, Hid::#iBrymenBC86XPid)
		While NextHID()
			AddElement(uDeviceList())
			uDeviceList()\sPath = HIDInfo(#PB_HID_Path)
			uDeviceList()\iVid = Val(HIDInfo(#PB_HID_VendorId))
			uDeviceList()\iPid = Val(HIDInfo(#PB_HID_ProductId))
			uDeviceList()\iRev = Val(HIDInfo(#PB_HID_ReleaseNumber))
			sText = HIDInfo(#PB_HID_SerialNumber)
			
			iCount = StringByteLength(sText)
			sTemp = #Null$
			For c = iCount To 1 Step - 1
				sTemp + RSet(Hex(PeekA(@sText + c - 1), #PB_Ascii), 2, "0")
			Next
			uDeviceList()\sSerial = LTrim(sTemp, "0")
		Wend
		
		If Not ListSize(uDeviceList())
			AddGadgetItem(#eGadgetEditorLog, -1, sDate + "No adapter was found.")
		Else
			SortStructuredList(uDeviceList(), #PB_Sort_Ascending, OffsetOf(Hid::uDevice\sSerial), TypeOf(Hid::uDevice\sSerial))
			iName = Asc("A")
			HideGadget(#eGadgetButtonTextWidth, #False)
			ForEach uDeviceList()
				With uDeviceList()
					sTemp = Chr(iName)
					SetGadgetText(#eGadgetButtonTextWidth, sTemp)
					iWidth = GadgetWidth(#eGadgetButtonTextWidth, #PB_Gadget_RequiredSize)
					If iWidth > iWidthName : iWidthName = iWidth : EndIf
					sText = sTemp + #LF$
					
					sTemp = RSet(Hex(\iVid), 4, "0")
					SetGadgetText(#eGadgetButtonTextWidth, sTemp)
					iWidth = GadgetWidth(#eGadgetButtonTextWidth, #PB_Gadget_RequiredSize)
					If iWidth > iWidthVid : iWidthVid = iWidth : EndIf
					sText + sTemp + #LF$
					
					sTemp = RSet(Hex(\iPid), 4, "0") 
					SetGadgetText(#eGadgetButtonTextWidth, sTemp)
					iWidth = GadgetWidth(#eGadgetButtonTextWidth, #PB_Gadget_RequiredSize)
					If iWidth > iWidthPid : iWidthPid = iWidth : EndIf
					sText + sTemp + #LF$
					
					sTemp = Left(RSet(Hex(\iRev, #PB_Word), 4, "0"), 2) + "." +
						Right(Hex(\iRev, #PB_Word), 2)
					SetGadgetText(#eGadgetButtonTextWidth, sTemp)
					iWidth = GadgetWidth(#eGadgetButtonTextWidth, #PB_Gadget_RequiredSize)
					If iWidth > iWidthRev : iWidthRev = iWidth : EndIf
						sText + sTemp + #LF$
					
					sTemp = \sSerial 
					SetGadgetText(#eGadgetButtonTextWidth, sTemp)
					iWidth = GadgetWidth(#eGadgetButtonTextWidth, #PB_Gadget_RequiredSize)
					If iWidth > iWidthSerial : iWidthSerial = iWidth : EndIf
					sText + sTemp + #LF$
				
					sTemp = \sPath
					SetGadgetText(#eGadgetButtonTextWidth, sTemp)
					iWidth = GadgetWidth(#eGadgetButtonTextWidth, #PB_Gadget_RequiredSize)
					If iWidth > iWidthPath : iWidthPath = iWidth : EndIf
					sText + sTemp 
					
					AddGadgetItem(#eGadgetListIconDevice, -1, sText)
					SetGadgetItemState(#eGadgetListIconDevice, CountGadgetItems(#eGadgetListIconDevice) - 1,
						#PB_ListIcon_Checked)
					iName + 1
				EndWith
			Next
			
			HideGadget(#eGadgetButtonTextWidth, #True)
			If iWidthName
				SetGadgetItemAttribute(#eGadgetListIconDevice, #PB_Ignore, #PB_ListIcon_ColumnWidth,
					iWidthName + 25 + 10, #eColumnDeviceName)
				SetGadgetItemAttribute(#eGadgetListIconDevice, #PB_Ignore, #PB_ListIcon_ColumnWidth,
					iWidthVid + 10, #eColumnDeviceVid)
				SetGadgetItemAttribute(#eGadgetListIconDevice, #PB_Ignore, #PB_ListIcon_ColumnWidth,
					iWidthPid + 10, #eColumnDevicePid)
				SetGadgetItemAttribute(#eGadgetListIconDevice, #PB_Ignore, #PB_ListIcon_ColumnWidth,
					iWidthRev + 10, #eColumnDeviceRev)
				SetGadgetItemAttribute(#eGadgetListIconDevice, #PB_Ignore, #PB_ListIcon_ColumnWidth,
					iWidthSerial + 10, #eColumnDeviceSerial)
				SetGadgetItemAttribute(#eGadgetListIconDevice, #PB_Ignore, #PB_ListIcon_ColumnWidth,
					iWidthPath + 10, #eColumnDevicePath)
			EndIf
			
			iCount = ListSize(uDeviceList())
			If iCount = 1
				AddGadgetItem(#eGadgetEditorLog, -1, sDate + iCount + " BC-86X/P adapter was found.")
			Else
				AddGadgetItem(#eGadgetEditorLog, -1, sDate + iCount + " BC-86X/P adapters were found.")
			EndIf
		EndIf
		EditorScrollToBottom(#eGadgetEditorLog)
	EndProcedure
	
	
	Procedure TestDevices()
		Protected sText.s, sName.s, sPath.s, iDeviceHandle.i, iError.i, iCount.i, iIndex.i
		Protected *uData.Hid::uBM86XData
		
		iCount = CountGadgetItems(#eGadgetListIconDevice)
		If Not iCount
			sText = FormatDate(#sLogDateMask, Date()) + "There is no adapter available for a test."
			AddGadgetItem(#eGadgetEditorLog, -1, sText)
		Else
			iCount - 1
			For iIndex = 0 To iCount
				If GetGadgetItemState(#eGadgetListIconDevice, iIndex) & #PB_ListIcon_Checked
					sName = GetGadgetItemText(#eGadgetListIconDevice, iIndex, #eColumnDeviceName)
					sPath = GetGadgetItemText(#eGadgetListIconDevice, iIndex, #eColumnDevicePath)
					iDeviceHandle = OpenHIDPath(#PB_Any, sPath)
					If Not iDeviceHandle
						sText = FormatDate(#sLogDateMask, Date()) + sName + ": " + ErrorLog::GetErrorText(iError)
						AddGadgetItem(#eGadgetEditorLog, -1, sText)
						iError = 0
					Else
						*uData = Hid::BrymenBM86XRead(iDeviceHandle, @iError)
						If Not *uData
							sText = FormatDate(#sLogDateMask, Date()) + sName + ": " + ErrorLog::GetErrorText(iError)
							AddGadgetItem(#eGadgetEditorLog, -1, sText)
						Else
							iError = 0
							sText = FormatDate(#sLogDateMask, Date()) + sName + ": " +
								Hid::BrymenBM86XDecode(*uData, Hid::#eDataTypeAll, @iError)
							AddGadgetItem(#eGadgetEditorLog, -1, sText)
							If iError
								sText = FormatDate(#sLogDateMask, Date()) + sName + ": " + ErrorLog::GetErrorText(iError)
								AddGadgetItem(#eGadgetEditorLog, -1, sText)
							EndIf
							FreeStructure(*uData)
						EndIf
						CloseHID(iDeviceHandle)
					EndIf
				EndIf
				EditorScrollToBottom(#eGadgetEditorLog)
			Next
		EndIf
	EndProcedure
	
	
	Procedure LanServer(fEnable.i)
		; -> fEnable: If True, the server is started; if False, it is stopped.
		Protected fResult.i, iCount.i, iIndex.i, sText.s, iError.i
		
		If fEnable
			With guLanServerThreadData
				If \iThreadNumber
					LanServer(#False)
				EndIf
				\iIpAddress = GetGadgetState(#eGadgetIpAddress)
				\iPort = Val(GetGadgetText(#eGadgetStringPort))
				\fExit = #False
				\iError = 0
				ClearList(\uDeviceList())
				iCount = CountGadgetItems(#eGadgetListIconDevice)
				If iCount
					iCount - 1
					For iIndex = 0 To iCount
						AddElement(\uDeviceList())
						\uDeviceList()\sName = GetGadgetItemText(#eGadgetListIconDevice, iIndex, #eColumnDeviceName)
						\uDeviceList()\sPath = GetGadgetItemText(#eGadgetListIconDevice, iIndex, #eColumnDevicePath)
						\uDeviceList()\iHandle = OpenHIDPath(#PB_Any, \uDeviceList()\sPath)
						If Not \uDeviceList()\iHandle
							MError2(0, FormatDate(#sLogDateMask, Date()) + \uDeviceList()\sName + ": " +
								ErrorLog::GetErrorText(iError))
							PostEvent(#eEventCustomServerError, #eWindowMain, #PB_Ignore, #False, ErrorLog::SetError(uError))
							DeleteElement(\uDeviceList())
						EndIf
					Next
				EndIf
				\iThreadNumber = CreateThread(@LanServerThread(), @guLanServerThreadData)
				sText = FormatDate(#sLogDateMask, Date()) + "The server has been started."
				AddGadgetItem(#eGadgetEditorLog, -1, sText)
				EditorScrollToBottom(#eGadgetEditorLog)
			EndWith
		EndIf
		
		If Not fEnable
			With guLanServerThreadData
				If \iThreadNumber And IsThread(\iThreadNumber)
					\fExit = #True
					fResult = Bool(WaitThread(\iThreadNumber, 2000))
					If Not fResult
						KillThread(\iThreadNumber)
						sText = FormatDate(#sLogDateMask, Date()) + "The server has been killed."
						AddGadgetItem(#eGadgetEditorLog, -1, sText)
					EndIf
				EndIf
				\iThreadNumber = #Null
				ForEach \uDeviceList()
					If \uDeviceList()\iHandle
						CloseHID(\uDeviceList()\iHandle)
					EndIf
				Next
				ClearList(\uDeviceList())
			EndWith
		EndIf
	EndProcedure
	
	
	Procedure LanServerThread(*uThreadData.uLanServerThreadData)
		Protected iConnection.i, sBoundIp.s, fExit.i, iClientId.i, *Buffer, iBufferSize.i
		Protected iResult.i, sReceived.s, sCommand.s, sAnswer.s, iPos.i
		
		If *uThreadData\iIpAddress
			sBoundIp = IPString(*uThreadData\iIpAddress, #PB_Network_IPv4)
		EndIf
		iConnection = CreateNetworkServer(#PB_Any, *uThreadData\iPort,
			#PB_Network_TCP | #PB_Network_IPv4, sBoundIp)
		If Not iConnection
			MError2(0, "The server could not be created. IP-Address: " +
				IPString(*uThreadData\iIpAddress, #PB_Network_IPv4) + " Port: " + *uThreadData\iPort)
			*uThreadData\iError = ErrorLog::SetError(uError, *uThreadData\iError)
			PostEvent(#eEventCustomServerError, #eWindowMain, #PB_Ignore, #True, *uThreadData\iError)
		EndIf
		
		If iConnection
			iBufferSize = 128
			*Buffer = AllocateMemory(iBufferSize)
			
			Repeat
				Select NetworkServerEvent()
				
					Case #PB_NetworkEvent_Data
						iClientId = EventClient()
						iResult = ReceiveNetworkData(iClientId, *Buffer, iBufferSize)
						If iResult > 0
							sReceived = PeekS(*Buffer, iResult, #PB_Ascii)
							iPos = FindString(sReceived, #LF$)
							If iPos
								sCommand + Left(sReceived, iPos)
								sAnswer = ProcessCommand(sCommand, *uThreadData)
								iResult = SendNetworkString(iClientId, sAnswer, #PB_Ascii)
								If iResult < Len(sAnswer)
									MError2(0, "The answer was not sent completely - Command: " + TrimAny(sCommand) +
										" - Answer: " + TrimAny(sAnswer) + " - Send: " + iResult + " bytes")
									*uThreadData\iError = ErrorLog::SetError(uError, *uThreadData\iError)
									PostEvent(#eEventCustomServerError, #eWindowMain, #PB_Ignore, #False,
										*uThreadData\iError)
								EndIf
								sCommand = #Null$
							Else
								sCommand + sReceived
							EndIf
						EndIf
						
					Case #PB_NetworkEvent_Connect
						iClientId = EventClient()
						MError2(0, "A client has connected - IP address: " + IPString(GetClientIP(iClientId)))
						PostEvent(#eEventCustomLog, #eWindowMain, #PB_Ignore, #PB_Ignore,
							ErrorLog::SetError(uError))
						
					Case #PB_NetworkEvent_Disconnect
						iClientId = EventClient()
						MError2(0, "A client has disconnected - IP address: " + IPString(GetClientIP(iClientId)))
						PostEvent(#eEventCustomLog, #eWindowMain, #PB_Ignore, #PB_Ignore,
							ErrorLog::SetError(uError))
						
					Case #PB_NetworkEvent_None
						Delay(50)
				EndSelect
				
				fExit = *uThreadData\fExit
			Until fExit
			
			CloseNetworkServer(iConnection)
			If *Buffer
				FreeMemory(*Buffer)
			EndIf
		EndIf
		
		*uThreadData\iThreadNumber = #Null
		PostEvent(#eEventCustomServerExit, #eWindowMain, #PB_Ignore)
	EndProcedure


	Procedure.s ProcessCommand(sReceived.s, *uThreadData.uLanServerThreadData)
		; Processes the command received and creates the response.
		; -> sReceived: The received command.
		; -> *uThreadData: Structure and list with the device data.
		; Return: The answer with the data.
		Protected sReturn.s, sCommand.s, sParse.s, sName.s, sParam.s, sText.s, iIndex.i, iDeviceHandle.i, iError.i
		Protected *uData.Hid::uBM86XData
		Protected NewList sCommandList.s()
		
		; A? MV,SV;B? MV,SV;C? MV,SV...
		sCommand = UCase(TrimAny(sReceived))
		SplitToList(sCommand, sCommandList(), #sCharSemicolon)
		ForEach sCommandList()
			sParse = sCommandList()
			
			If sParse = "*IDN?"
				sReturn = "Brymen,HID-to-LAN," + FormatDate("%yyyy-%mm-%dd", #PB_Compiler_Date) +
				"," + #PB_Editor_FileVersion
				sReturn + #sCharSemicolon
			Else
				; e.g: A? MV,MU,SV,SU
				; Determine the first character for the selected device.
				sName = Left(sParse, 1)
				sText = Mid(sParse, 3)
				If Asc(sName)
					With *uThreadData
						ForEach \uDeviceList()
							If sName = \uDeviceList()\sName
								iDeviceHandle = \uDeviceList()\iHandle
								*uData = Hid::BrymenBM86XRead(iDeviceHandle, @iError)
								If Not *uData
									MError2(0, FormatDate(#sLogDateMask, Date()) + sName + ": " +
										ErrorLog::GetErrorText(iError))
									PostEvent(#eEventCustomServerError, #eWindowMain, #PB_Ignore, #False, ErrorLog::SetError(uError))
								Else
									iIndex = 0
									Repeat
										iIndex + 1
										sParam = TrimAny(StringField(sText, iIndex, #sCharComma))
										If Asc(sParam)
											Select sParam
												Case "MV"
													sReturn + Hid::BrymenBM86XDecode(*uData, Hid::#eDataTypeMainValue, @iError)
													sReturn + #sCharSemicolon
												Case "MU"
													sReturn + Hid::BrymenBM86XDecode(*uData, Hid::#eDataTypeMainUnit, @iError)
													sReturn + #sCharSemicolon
												Case "SV"
													sReturn + Hid::BrymenBM86XDecode(*uData, Hid::#eDataTypeSecondValue, @iError)
													sReturn + #sCharSemicolon
												Case "SU"
													sReturn + Hid::BrymenBM86XDecode(*uData, Hid::#eDataTypeSecondUnit, @iError)
													sReturn + #sCharSemicolon
												Default
													Break
											EndSelect
											If iError
												MError2(0, FormatDate(#sLogDateMask, Date()) + sName + ": " +
												ErrorLog::GetErrorText(iError))
												PostEvent(#eEventCustomServerError, #eWindowMain, #PB_Ignore, #False,
												ErrorLog::SetError(uError))
												iError = 0
											EndIf
										Else
											If iIndex = 1
												sReturn + Hid::BrymenBM86XDecode(*uData, Hid::#eDataTypeMainValue, @iError)
												sReturn + #sCharSemicolon
											EndIf
											Break
										EndIf
									ForEver
									FreeStructure(*uData)
								EndIf
								Break
							EndIf
						Next
					EndWith
				EndIf
			EndIf
			
			If *uThreadData\fExit
				Break
			EndIf
		Next
		
		If Right(sReturn, 1) = #sCharSemicolon
			sReturn = Left(sReturn, Len(sReturn) - 1)
		EndIf
		
		sReturn + #LF$
		
		If gfDebug
			sText = ~"Received: \"" + sReceived + ~"\" - Transmitted: \"" + sReturn + ~"\""
			sText = ReplaceString(sText, #LF$, "<LF>")
			sText = ReplaceString(sText, #CR$, "<CR>")
			MError2(0, sText)
			PostEvent(#eEventCustomLog, #eWindowMain, #PB_Ignore, #PB_Ignore, ErrorLog::SetError(uError))
		EndIf
		
		ProcedureReturn sReturn
	EndProcedure

EndModule
