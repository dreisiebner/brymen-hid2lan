;- -- DeclareModule --
DeclareModule Common
	EnableExplicit
	
	;- -- Constant.
	
	;- eEventCustom.
	; Events that are sent via PostEvent().
	; The enumeration is used and extended in other modules.
	Enumeration eEventCustom #PB_Event_FirstCustomValue
		#eEventCustomServerExit
		#eEventCustomServerError
		#eEventCustomLog
	EndEnumeration
	
	;- Chars.
	#sCharComma = ","
	#sCharSemicolon = ";"
	#sCharSpace = " "
	#sWhiteSpace = #sCharSpace + #TAB$ + #CRLF$

	;- -- Macro.
	
	Macro MError(Code = 0, Text = #Null$)
		CompilerIf Not Defined(uError, #PB_Variable)
		Protected uError.ErrorLog::uError
		CompilerEndIf
		uError\iCode = Code
		uError\sModule = #PB_Compiler_Module
		uError\sProc = #PB_Compiler_Procedure
		uError\sDescription = Text
		*iError\i = ErrorLog::SetError(uError, *iError\i)
	EndMacro

	Macro MError2(Code = 0, Text = #Null$)
		CompilerIf Not Defined(uError, #PB_Variable)
		Protected uError.ErrorLog::uError
		CompilerEndIf
		uError\iCode = Code
		uError\sModule = #PB_Compiler_Module
		uError\sProc = #PB_Compiler_Procedure
		uError\sDescription = Text
	EndMacro

	;- -- Declare.
	
	Declare.s TrimAny(sText.s, sCharList.s = #sWhiteSpace)
	Declare SplitToList(sString.s, List StringList.s(), sSeparator.s = #sCharSpace)
	Declare EditorScrollToBottom(iEditorNumber.i)
	
EndDeclareModule


;- -- Module --
Module Common
	
	;- -- Procedure.
	
	Procedure.s LTrimAny(sText.s, sCharList.s = #sWhiteSpace)
		Protected sReturn.s, c.i, *sChar.Character
		
		c = 1
		*sChar = @sText
		While (*sChar\c <> 0 And (FindString(sCharList, Chr(*sChar\c)) <> 0))
			c + 1
			*sChar + SizeOf(Character)
		Wend
		sReturn = Mid(sText, c)
		
		ProcedureReturn sReturn
	EndProcedure


	Procedure.s RTrimAny (sText.s, sCharList.s = #sWhiteSpace)
		Protected sReturn.s, c.i, *sChar.Character
		
		c = Len(sText)
		*sChar = @sText + (c - 1) * SizeOf(Character)
		While (c >= 1 And (FindString(sCharList, Chr(*sChar\c)) <> 0))
			c - 1
			*sChar - SizeOf(Character)
		Wend
		sReturn = Left(sText, c)
		
		ProcedureReturn sReturn
	EndProcedure
	
	
	Procedure.s TrimAny(sText.s, sCharList.s = #sWhiteSpace)
		Protected sReturn.s

		sReturn = RTrimAny(LTrimAny(sText, sCharList), sCharList)
		
		ProcedureReturn sReturn
	EndProcedure


	Procedure SplitToList(sString.s, List StringList.s(), sSeparator.s = " ")
		Protected sStringPos.String, *StringPos.Integer, iFindPos.i, iSeparatorLen.i
		
		iSeparatorLen = Len(sSeparator)
		ClearList(StringList())
		
		*StringPos = @sStringPos
		*StringPos\i = @sString
		
		Repeat
			AddElement(StringList())
			iFindPos = FindString(sStringPos\s, sSeparator)
			StringList() = PeekS(*StringPos\i, iFindPos - 1)
			*StringPos\i + ((iFindPos + iSeparatorLen - 1) * SizeOf(Character))
		Until iFindPos = 0
		*StringPos\i = 0
		
	EndProcedure
	

	Procedure EditorScrollToBottom(iEditorNumber.i)
			CompilerIf #PB_Compiler_OS = #PB_OS_Windows
				SendMessage_(GadgetID(iEditorNumber), #EM_SCROLL, #SB_BOTTOM, 0)
			CompilerElseIf #PB_Compiler_OS = #PB_OS_Linux
				Protected iEndMark.I, iTextBuffer.I, uEndIter.GtkTextIter
				iTextBuffer = gtk_text_view_get_buffer_(GadgetID(iEditorNumber))
				gtk_text_buffer_get_end_iter_(iTextBuffer, @uEndIter)
				iEndMark = gtk_text_buffer_create_mark_(iTextBuffer, "end_mark", @uEndIter, #False)
				gtk_text_view_scroll_mark_onscreen_(GadgetID(iEditorNumber), iEndMark)
			CompilerEndIf
	EndProcedure

EndModule
