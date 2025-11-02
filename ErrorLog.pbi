;- -- DeclareModule --
DeclareModule ErrorLog
	EnableExplicit

	;- -- Structure.

	;- uError.
	Structure uError
		iCode.i
		sDescription.s
		sModule.s
		sProc.s
	EndStructure
		
	;- -- Declare.

 	Declare.i GetError(iKey.i, *uError.uError)
 	Declare.s GetErrorText(iKey.i)
 	Declare.i SetError(*uError.uError, iKey = #Null)	
	
EndDeclareModule


;- -- Module --
Module ErrorLog

	;- -- Variable.
	
	Global NewMap mErrorMap.uError()
	Global miErrorMutex.i

	;- -- Procedure.
	
	Procedure.i GetError(iKey.i, *uError.uError)
		; Returns the error description as a structure with the transferred key and deletes the error.
		; -> iKey: The key with which the error description was saved.
		; <- *uError: A pointer to the structure for the error description.
		; Return: True if the error description was present, otherwise False.
		Protected fReturn.i

		If (Not miErrorMutex)
			miErrorMutex = CreateMutex()
		EndIf
		
		LockMutex(miErrorMutex)
		fReturn = Bool(FindMapElement(mErrorMap(), Str(iKey)))
		If fReturn
			If *uError
 				CopyStructure(mErrorMap(), *uError, uError)
			EndIf
			DeleteMapElement(mErrorMap())
		EndIf
		UnlockMutex(miErrorMutex)

		ProcedureReturn fReturn
	EndProcedure
	
	
	Procedure.s GetErrorText(iKey.i)
		; Returns the error description as a string with the transferred key and deletes the error.
		; -> iKey: The key with which the error description was saved.
		; Return: The error description as a string if it was present, otherwise a null string.
		Protected sReturn.s, uError.uError
		
		If GetError(iKey, uError)
			With uError
				sReturn = \sModule + "::" + \sProc + ": (Code: " + \iCode + ") " + \sDescription
			EndWith
		EndIf

		ProcedureReturn sReturn
	EndProcedure


	Procedure.i SetError(*uError.uError, iKey = #Null)
		; Saves the transferred error description.
		; -> *uError: A pointer to the structure with the error description.
		; -> iKey: If a key is transferred, the error is saved with this key.
		;	This allows several errors to be summarized and retrieved with GetError().
		; Return: The key for getting the error, or zero in the event of an error.
		Protected iReturn.i
		Static iErrorKey.i
		#iErrorMapMaxSize = 1000
		
		If (Not miErrorMutex)
			miErrorMutex = CreateMutex()
		EndIf
		
		LockMutex(miErrorMutex)
		If MapSize(mErrorMap()) > #iErrorMapMaxSize
			ClearMap(mErrorMap())
			iErrorKey = 0
		EndIf
		
		If *uError
			If iKey
				iErrorKey = iKey
			Else
				iErrorKey + 1
			EndIf
			If AddMapElement(mErrorMap(), Str(iErrorKey), #PB_Map_NoElementCheck)
				iReturn = iErrorKey
 				CopyStructure(*uError, mErrorMap(), uError)
			EndIf
		EndIf
		UnlockMutex(miErrorMutex)

		ProcedureReturn iReturn
	EndProcedure

EndModule
