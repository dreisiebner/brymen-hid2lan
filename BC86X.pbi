;- -- DeclareModule --
DeclareModule Hid
	EnableExplicit

	;- -- Constant.
	
	#iBrymenBC86XVid = $0820
	#iBrymenBC86XPid = $0001

	;- eDataType.
	Enumeration eDataType
		#eDataTypeNone
		#eDataTypeAll
		#eDataTypeMainValue
		#eDataTypeMainUnit
		#eDataTypeMainAll
		#eDataTypeSecondValue
		#eDataTypeSecondUnit
		#eDataTypeSecondAll
	EndEnumeration
	
	;- -- Structure.
	
	;- uDevice.
	Structure uDevice
		sPath.s
		iVid.i
		iPid.i
		iRev.i
		sSerial.s
	EndStructure
	
	;- uBM86XData.
	Structure uBM86XData
		; 3 * 9 Bytes.
		; Byte 0 to 8.
		aReportId1.a
		aDontCare1.a
		aFunction1.a
		aFunction2.a
		aDigit1.a
		aDigit2.a
		aDigit3.a
		aDigit4.a
		aDigit5.a
		; Byte 9 to 17.
		aReportId2.a
		aDigit6.a
		aFunction3.a
		aDigit7.a
		aDigit8.a
		aDigit9.a
		aDigit10.a
		aFunction4.a
		aFunction5.a
		; Byte 18 to 26.
		aReportId3.a
		aDontCare2.a
		aDontCare3.a
		aDontCare4.a
		aModelId.a
		aDontCare5.a
		aDontCare6.a
		aDontCare7.a
		aDontCare8.a
	EndStructure
	
	;- -- Declare.
	
	Declare.i BrymenBM86XRead(iDeviceHandle.i, *iError.Integer)
	Declare.s BrymenBM86XDecode(*uData.uBM86XData, eDataType.i, *iError.Integer)
	
EndDeclareModule


;- -- Module --
Module Hid
	UseModule Common
	
	;- -- Constant.
	
	#iReadTimeout = 1500 ; It takes almost a second to read in both temperature values.
	#rErrorValue = -999999.0
	#sErrorValue = "-999999"

	;- -- Structure.
	
	;- uBM86XHidData.
	Structure uBM86XHidData
		aByte.a[3 * 9]
	EndStructure
	
	;- -- Prototype.
	
	;- -- Variable.
		
	;- -- Declare.
	
	Declare.d BrymenBM86XDecodeMainValue(*uData.uBM86XData, *iError.Integer)
	Declare.s BrymenBM86XDecodeMainUnit(*uData.uBM86XData, *iError.Integer)
	Declare.d BrymenBM86XDecodeSecondValue(*uData.uBM86XData, *iError.Integer)
	Declare.s BrymenBM86XDecodeSecondUnit(*uData.uBM86XData, *iError.Integer)
	Declare.i BrymenBM86XDecodeDigit(aDigit.a, fNoError.i, *iError.Integer)
	Declare.i BrymenBM86XDecodeDecimalPoint(aDigit1.a, aDigit2.a, aDigit3.a, aDigit4.a, *iError.Integer)
	
	;- -- Procedure.	

	Procedure.i BrymenBM86XRead(iDeviceHandle.i, *iError.Integer)
		; Reads the data from the Brymen BC-86X/P adapter.
		; -> iDeviceHandle: The handle of the opened device.
		; <> *iError: Error description.
		; Return: A pointer to the structure with the data, otherwise zero in the event of an error.
		; Attention: The structure must be released again.
		Protected iResult.i, fResult.i, iCount.i, uData.uBM86XHidData , *uData
		Protected Dim aaData.a(4 - 1)
		
		aaData(0) =$00	; ReportNumber.
		aaData(1) =$00	; Command 1
		aaData(2) =$86	; Command 2
		aaData(3) =$66	; Command 3
		iResult = WriteHIDData(iDeviceHandle, @aaData(0), 4)
		fResult = Bool(iResult)
		If Not fResult
			MError(0, "Error sending the start sequence to the Brymen BC-86X/P adapter." +
				" HID Error: " + HIDError())
		Else
			 For iCount = 1 To 3
				; Read in 3 packets with 8 bytes each. 8 data bytes per packet.
				Dim aaData.a(8 - 1)	; Delete received data each time.
			 	iResult = ReadHIDData(iDeviceHandle, @aaData(0), 8, 2000)
			 	fResult = Bool(iResult)
			 	If Not fResult
					MError(0, "Error reading from the Brymen BC-86X/P adapter." +
						" HID Error: " + HIDError())
			 		Break
			 	Else
			 		CopyMemory(@aaData(0), @uData + ((iCount -1) * 9) + 1, 8)
			 	EndIf
			 Next
		EndIf
		If fResult
			*uData = AllocateStructure(uBM86XHidData)
			If *uData
				CopyStructure(uData, *uData, uBM86XHidData)
			EndIf
		EndIf
		
		ProcedureReturn *uData
	EndProcedure

	;-

	Procedure.s BrymenBM86XDecode(*uData.uBM86XData, eDataType.i, *iError.Integer)
		; Decodes the data into the desired value.
		; -> *uData: The structure with the thread data.
		; -> eDataType: The type of value to be determined, e.g. main value or second value. Enum #eDataType...
		; <>*iError: Error description.
		; Return: The decoded value.
		Protected sReturn.s, fResult.i, rValue.d, sUnit.s, iCount.i
		
		Select eDataType
		
			Case #eDataTypeMainValue, #eDataTypeNone
				sReturn = StrD(BrymenBM86XDecodeMainValue(*uData, *iError))
				
			Case #eDataTypeMainUnit
				sReturn = BrymenBM86XDecodeMainUnit(*uData, *iError)
				
			Case #eDataTypeMainAll
				sReturn = StrD(BrymenBM86XDecodeMainValue(*uData, *iError))
				sReturn + " " + BrymenBM86XDecodeMainUnit(*uData, *iError)
		
			Case #eDataTypeSecondValue
				sReturn = StrD(BrymenBM86XDecodeSecondValue(*uData, *iError))
				
			Case #eDataTypeSecondUnit
				sReturn = BrymenBM86XDecodeSecondUnit(*uData, *iError)
				
			Case #eDataTypeSecondAll
				sReturn = StrD(BrymenBM86XDecodeSecondValue(*uData, *iError))
				sReturn + " " + BrymenBM86XDecodeSecondUnit(*uData, *iError)
				
			Case #eDataTypeAll
				sReturn = StrD(BrymenBM86XDecodeMainValue(*uData, *iError))
				sReturn + " " + BrymenBM86XDecodeMainUnit(*uData, *iError)
				sReturn + " ; " + StrD(BrymenBM86XDecodeSecondValue(*uData, *iError))
				sReturn + " " + BrymenBM86XDecodeSecondUnit(*uData, *iError)
				
			Default
				sReturn = #sErrorValue
		EndSelect

		ProcedureReturn sReturn
	EndProcedure

	
	Procedure.d BrymenBM86XDecodeMainValue(*uData.uBM86XData, *iError.Integer)
		; Decodes the main value of the HID data read in from the Brymen BM867s/BM869s.
		; -> *uData: The structure with the data.
		; <>*iError: Error description.
		; Return:	The main value or -999999 in the event of an error.
		Protected rReturn.d, fResult.i, rMainValue.d, iValue.i
		
		rMainValue = 0
		
		; The first, leftmost digit is not always present, e.g. for S (Siemens), so ignore an error.
		iValue = BrymenBM86XDecodeDigit(*uData\aDigit1, #False, *iError)
		fResult = Bool(iValue > -1)
		If fResult
			rMainValue + (iValue * 100000)
		Else
			fResult = #True
		EndIf
		
		If fResult
			iValue = BrymenBM86XDecodeDigit(*uData\aDigit2, #False, *iError)
			fResult = Bool(iValue > -1)
			rMainValue + (iValue * 10000)
		EndIf
		
		If fResult
			iValue = BrymenBM86XDecodeDigit(*uData\aDigit3, #False, *iError)
			fResult = Bool(iValue > -1)
			rMainValue + (iValue * 1000)
		EndIf
		
		If fResult
			iValue = BrymenBM86XDecodeDigit(*uData\aDigit4, #False, *iError)
			fResult = Bool(iValue > -1)
			rMainValue + (iValue * 100)
		EndIf
		
		If fResult
			iValue = BrymenBM86XDecodeDigit(*uData\aDigit5, #False, *iError)
			fResult = Bool(iValue > -1)
			rMainValue + (iValue * 10)
		EndIf
		
		If fResult
			iValue = BrymenBM86XDecodeDigit(*uData\aDigit6, #True, *iError)
			; The sixth digit in HighRes mode does not always have to be present, it is not an error.
			If (iValue > -1)
				rMainValue + iValue
			EndIf
		EndIf

		; Determine the decimal point and calculate the value.
		If fResult
			iValue = BrymenBM86XDecodeDecimalPoint(*uData\aDigit2, *uData\aDigit3,
				*uData\aDigit4, *uData\aDigit5, *iError)
			rMainValue / Pow(10, iValue)
		EndIf
		
		; Determine the sign and calculate the value.
		If fResult
			; Evaluate bit 7 for the sign. Bit 5 is also possible, both indicate the sign.
			If (*uData\aFunction2 & $80)
				rMainValue * (-1)
			EndIf
		EndIf
		
		If fResult
			rReturn = rMainValue
		Else
			rReturn = #rErrorValue
		EndIf
		
		ProcedureReturn rReturn
	EndProcedure

	
	Procedure.s BrymenBM86XDecodeMainUnit(*uData.uBM86XData, *iError.Integer)
		; Decodes the unit and additional information from the main value of the data read in
		; from the Brymen BM867s/BM869s.
		; -> *uData: The structure with the data.
		; <>*iError: Error description.
		; Return: The unit or an empty string in the event of an error.
		Protected fResult.i, sUnit.s, sText.s
		
		sUnit = #Empty$
				
		; Volt - aDigit6 Bit 0.
		If (*uData\aDigit6 & $01)
			sUnit = "V"
		
		; Ampere - aFunction4 Bit 7.
		ElseIf (*uData\aFunction4 & $80)
			sUnit = "A"
		
		; Farad - aFunction4 Bit 5.
		ElseIf (*uData\aFunction4 & $20)
			sUnit = "F"
		
		; Siemens - aFunction4 Bit 4.
		ElseIf (*uData\aFunction4 & $10)
			sUnit = "S"
		
		; D% - aFunction5 Bit 7.
		ElseIf (*uData\aFunction5 & $80)
			sUnit = "D%"
		
		; Ohm - aFunction5 Bit 4.
		ElseIf (*uData\aFunction5 & $10)
			sUnit = Chr($03A9) ; "Ohm" U+03A9 Capital Greek letter omega.
		
		; dB - aFunction5 Bit 1.
		ElseIf (*uData\aFunction5 & $02)
			sUnit = "dB"
		
		; Hz - aFunction5 Bit 0.
		ElseIf (*uData\aFunction5 & $01)
			sUnit = "Hz"
		
		; T1 or T1-T2 - aFunction2 Bit 1.
		ElseIf (*uData\aFunction2 & $02)
			; degrees Celsius or Fahrenheit.
			; aDigit6 is then a C or F.
			If ((*uData\aDigit6 & $FE) = $1E)
				sUnit = Chr($00B0) + "C"	; degrees U+00B0.
			ElseIf ((*uData\aDigit6 & $FE) = $4E)
				sUnit = Chr($00B0) + "F"
			EndIf
		
		; T2 - aFunction2 Bit 3.
		ElseIf (*uData\aFunction2 & $08)
			; degrees Celsius or Fahrenheit.
			; aDigit6 is then a C or F.
			If ((*uData\aDigit6 & $FE) = $1E)
				sUnit = Chr($00B0) + "C"	; degrees U+00B0.
			ElseIf ((*uData\aDigit6 & $FE) = $4E)
				sUnit = Chr($00B0) + "F"
			EndIf

		EndIf

		
		; Determine subunit.
		If Len(sUnit)
		
			; Nano - aFunction4 Bit 6.
			If (*uData\aFunction4 & $40)
				sUnit = "n" + sUnit 
			
			; Kilo - aFunction5 Bit 6.
			ElseIf (*uData\aFunction5 & $40)
				sUnit = "k" + sUnit
			
			; Mega - aFunction5 Bit 5.
			ElseIf (*uData\aFunction5 & $20)
				sUnit = "M" + sUnit
			
			; Micro - aFunction5 Bit 3.
			ElseIf (*uData\aFunction5 & $08)
				sUnit = Chr($00B5) + sUnit	; Micro-Char U+00B5.
			
			; Milli - aFunction5 Bit 2.
			ElseIf (*uData\aFunction5 & $04)
				If (sUnit = "dB")
					sUnit + "m"
				Else
					sUnit = "m" + sUnit
				EndIf
			EndIf				
		EndIf


		; DC and AC.
		If Len(sUnit)

			; DC+AC.
			If ((*uData\aFunction1 & $10) And (*uData\aFunction2 & $01))
				sUnit + " DC+AC"
			
			; DC - aFunction1 Bit 4.
			ElseIf (*uData\aFunction1 & $10)
				sUnit + " DC"
			
			; AC - aFunction2 Bit 0.
			ElseIf (*uData\aFunction2 & $01)
				sUnit + " AC"
			EndIf
		EndIf

		
		; AVG, MIN and MAX.
		If Len(sUnit)
			
			; If all three indicators are active, do not output anything.
			If ((*uData\aFunction1 & $80) And (*uData\aFunction1 & $40) And (*uData\aFunction1 & $20))
				; Not output anything.
				; Record mode has been activated without selecting MIN, MAX or AVG.
				
			; AVG - aFunction1 Bit 7.
			ElseIf (*uData\aFunction1 & $80)
				sUnit + " AVG"
			
			; MIN - aFunction1 Bit 6.
			ElseIf (*uData\aFunction1 & $40)
				sUnit + " MIN"
			
			; MAX - aFunction1 Bit 5.
			ElseIf (*uData\aFunction1 & $20)
				sUnit + " MAX"
			EndIf		
		EndIf

		
		; Delta - aDigit1 Bit 0.
		If Len(sUnit)
			If (*uData\aDigit1 & $01)
				sUnit = Chr($0394) + #sCharSpace + sUnit	; "Delta" U+0394 Capital Greek letter Delta.
			EndIf
		EndIf
		
		ProcedureReturn sUnit
	EndProcedure
	
	
	Procedure.d BrymenBM86XDecodeSecondValue(*uData.uBM86XData, *iError.Integer)
		; Decodes the second value of the HID data read in from the Brymen BM867s/BM869s.
		; -> *uData: The structure with the data.
		; <>*iError: Error description.
		; Return: The second value or -999999 in the event of an error.
		Protected rReturn.d, fResult.i, rSecondValue.d, iValue.i
		
		rSecondValue = 0
		
		iValue = BrymenBM86XDecodeDigit(*uData\aDigit7, #False, *iError)
		fResult = Bool(iValue > -1)
		If fResult
			rSecondValue + (iValue * 1000)
		EndIf
		
		If fResult
			iValue = BrymenBM86XDecodeDigit(*uData\aDigit8, #False, *iError)
			fResult = Bool(iValue > -1)
			rSecondValue + (iValue * 100)
		EndIf
		
		If fResult
			iValue = BrymenBM86XDecodeDigit(*uData\aDigit9, #False, *iError)
			fResult = Bool(iValue > -1)
			rSecondValue + (iValue * 10)
		EndIf
		
		If fResult
			iValue = BrymenBM86XDecodeDigit(*uData\aDigit10, #False, *iError)
			fResult = Bool(iValue > -1)
			rSecondValue + iValue
		EndIf

		; Determine the decimal point and calculate the value.
		If fResult
			iValue = BrymenBM86XDecodeDecimalPoint(0, *uData\aDigit8, *uData\aDigit9,
				*uData\aDigit10, *iError)
			; Adjust to second value, the decimal point is calculated for the main value.
			If iValue
				iValue - 1
			EndIf
			rSecondValue / Pow(10, iValue)
		EndIf
		
		; Determine the sign and calculate the value.
		If fResult
			If (*uData\aFunction3 & $10)
				rSecondValue * (-1)
			EndIf
		EndIf
		
		If fResult
			rReturn = rSecondValue
		Else
			rReturn = #rErrorValue
		EndIf
		
		ProcedureReturn rReturn
	EndProcedure

	
	Procedure.s BrymenBM86XDecodeSecondUnit(*uData.uBM86XData, *iError.Integer)
		; Decodes the unit and additional information from the second value of the data read in
		; from the Brymen BM867s/BM869s.
		; -> *uData: The structure with the data.
		; <>*iError: Error description.
		; Return: The unit or an empty string in the event of an error.
		Protected fResult.i, sUnit.s, sText.s, fVolt.i, fAmpere.i
		
		sUnit = #Empty$
		
		; Volt - aFunction4 Bit 3.
		If (*uData\aFunction4 & $08)
			sUnit + "V"
			fVolt = #True
		
		; Ampere - aFunction3 Bit 2.
		ElseIf (*uData\aFunction3 & $04)
			sUnit + "A"
			fAmpere = #True
		
		; Hz - aFunction4 Bit 2.
		ElseIf (*uData\aFunction4 & $04)
			sUnit + "Hz"
		
		; %4-20mA - aFunction3 Bit 3.
		ElseIf (*uData\aFunction3 & $08)
			sUnit + "%4-20mA"
		
		; T2 - aFunction3 Bit 6.
		ElseIf (*uData\aFunction3 & $40)
			; degrees Celsius or Fahrenheit.
			; aDigit6 is then a C or F..
			If ((*uData\aDigit6 & $FE) = $1E)
				sUnit + Chr($00B0) + "C"	; degrees U+00B0.
			ElseIf ((*uData\aDigit6 & $FE) = $4E)
				sUnit + Chr($00B0) + "F"
			EndIf
		EndIf

		
		; Determine subunit.
		If Len(sUnit)
			
			; Mega - aFunction4 Bit 0.
			If (*uData\aFunction4 & $01)
				sUnit = "M" + sUnit
			
			; Kilo - aFunction4 Bit 1.
			ElseIf (*uData\aFunction4 & $02)
				sUnit = "k" + sUnit
			
			; Mikro - aFunction3 Bit 0.
			ElseIf (*uData\aFunction3 & $01)
				sUnit = Chr($00B5) + sUnit	; Micro-Char U+00B5.
			
			; Milli - aFunction3 Bit 1.
			ElseIf (*uData\aFunction3 & $02)
				sUnit = "m" + sUnit
			EndIf				
		EndIf


		; DC and AC.
		If Len(sUnit)
			
			; AC - aFunction3 Bit 5.
			If (*uData\aFunction3 & $20)
				sText = " AC"
			Else
				sText = " DC"
			EndIf
			
			If (fVolt Or fAmpere)
				sUnit + sText
			EndIf
		EndIf

		ProcedureReturn sUnit
	EndProcedure


	Procedure.i BrymenBM86XDecodeDigit(aDigit.a, fNoError.i, *iError.Integer)
		; Decodes the transferred digit.
		; -> aDigit: The byte from the raw data of the BM869.
		; -> fNoError: If True, no error is output.
		; <>*iError: Error description.
		; Return: The decoded digit 0 to 9, or -1 in the event of an error.
		Protected iReturn.i

		fNoError = #True	; Disable Error Messages.
		
		aDigit & $FE
		
		Select aDigit
			Case $BE
				iReturn = 0
			Case $A0
				iReturn = 1
			Case $DA
				iReturn = 2
			Case $F8
				iReturn = 3
			Case $E4
				iReturn = 4
			Case $7C
				iReturn = 5
			Case $7E
				iReturn = 6
			Case $A8
				iReturn = 7
			Case $FE
				iReturn = 8
			Case $FC	; possibly also $EC?
				iReturn = 9
			Default
				iReturn = -1
				; Note: It is not an error if HighRes mode is not activated and the sixth digit is not present.
 				If Not fNoError
					MError(0, "The digit was not recognized, unknown value. aDigit = 0x" +
						RSet(Hex(aDigit, #PB_Ascii), 2, "0"))
				EndIf
		EndSelect
				
		ProcedureReturn iReturn
	EndProcedure


	Procedure.i BrymenBM86XDecodeDecimalPoint(aDigit1.a, aDigit2.a, aDigit3.a, aDigit4.a, *iError.Integer)
		; Decodes the transferred digit.
		; -> aDigit1: The byte for the first leftmost digit from the raw data of the BM869.
		; -> aDigit2:
		; -> aDigit3:
		; -> aDigit4:
		; <>*iError: Error description
		; Return: Returns the exponent for the calculation with 10^Exp.
		Protected iReturn.i

		If (aDigit1 & $01)
			iReturn = 5
		ElseIf (aDigit2 & $01)
			iReturn = 4
		ElseIf (aDigit3 & $01)
			iReturn = 3
		ElseIf (aDigit4 & $01)
			iReturn = 2
		Else
			iReturn = 0
		EndIf
				
		ProcedureReturn iReturn
	EndProcedure
		
EndModule
