"Filed out from Dolphin Smalltalk 7"!

OLEStructure subclass: #TYPEDESC
	instanceVariableNames: 'owner classDesc typeInfo'
	classVariableNames: 'VTIndirections'
	poolDictionaries: 'AXAutomationConstants'
	classInstanceVariableNames: ''!
TYPEDESC guid: (GUID fromString: '{c06f3b7a-0868-11d3-93af-00a024ca708a}')!
TYPEDESC comment: 'TYPEDESC is an ExternalStructure class to represent the AX Automation structure, TYPEDESC.

The TYPEDESC structure describes the type of a variable, function parameter, or return value, and is one of the key structures in the type library model.

Member Variables:
	u
		lptdesc		<TYPEDESC*> For a VT_PTR|VT_SAFEARRAY, describes the pointed at type
		lpadesc		<ARRAYDESC*> For a VT_CARRAY, provides additional description of the array
		hreftype		<HREFTYPE> For a VT_USERDEFINEDTYPE, ?
	vt			<VARTYPE> Variant type id (16-bits)

Note that this structure is only 6-bytes long, and requires packing when embedded in other structures (Dolphin''s external structure/array packing and alignment algorithm will handle this automatically).

Instance Variables:
	owner		<ExternalStructure>. Backpointer to original structure to keep it alive, and also to locate ITypeInfo.
'!
!TYPEDESC categoriesForClass!External-Data-Structured-COM! !
!TYPEDESC methodsFor!

analyzer
	"Private - Answer the <AXTypeInfoAnalyzer> from which the receiver originated."

	^owner analyzer!

arrayDesc
	"Private - Recurse down through any typedefs to the underlying ARRAYDESC. Anwer nil if the type does not describe an array."

	| vt |
	vt := self vt.
	vt == VT_PTR ifTrue: [^self tdesc arrayDesc].
	vt == VT_CARRAY ifTrue: [^self tdescArray].
	vt == VT_USERDEFINED ifTrue: [^self typeInfo tdesc arrayDesc].
	^nil!

buildClassDesc
	| vt |
	vt := self vt.
	vt == VT_PTR
		ifTrue: 
			["Its a pointer to something, so we need to recurse and answer  <typename>*"
			| indirTo |
			indirTo := self tdesc classDesc.
			^indirTo key -> (indirTo value + 1 min: 2)].
	vt == VT_CARRAY
		ifTrue: 
			[| arryDesc |
			arryDesc := self tdescArray tdesc classDesc.
			"Answer the type of array and the number of indirections to it - note that the element 
		type 	is asked to supply this array type, but the result may well be the generic 	
		<StructureArray>."
			^(arryDesc key arrayType: arryDesc value) -> 0].
	vt == VT_SAFEARRAY ifTrue: [^SAFEARRAY -> 1].
	vt == VT_USERDEFINED
		ifTrue: [^owner isNil ifTrue: [ExternalStructure -> 1] ifFalse: [self typeInfo classDesc]].
	^(VARIANT classForVT: vt) -> (VTIndirections at: vt)!

classDesc
	"Private - Answer a Dolphin class and indirection count pair which can be used to
	represent the external type described by the receiver."

	classDesc isNil ifTrue: [classDesc := self buildClassDesc].
	^classDesc!

getRefType
	^self analyzer getRefType: self hreftype!

hreftype
	"Answer the receiver's hreftype field as a Smalltalk object."

	^bytes dwordAtOffset: 0!

isAnonymous
	"Answer whether the type described by the receiver is an anonymous (i.e. unnamed)
	struct or union type."

	^self isStructure and: [self typeInfo isAnonymous]!

isStructure
	"Answer whether the receiver describes a user-defined struct or union type."

	^self isUserDefined and: [self typeInfo isStructure]!

isUnion
	"Answer whether the receiver describes a user-defined union type."

	^self isUserDefined and: [self typeInfo isUnion]!

isUserDefined
	"Answer whether the receiver describes a user-defined type, e.g. a struct."

	^self vt = VT_USERDEFINED!

lpadesc
	"Answer the receiver's lpadesc field as a Smalltalk object."

	^ARRAYDESC fromAddress: (bytes intPtrAtOffset: 0)!

lptdesc
	"Answer the receiver's lptdesc field as a Smalltalk object."

	^TYPEDESC fromAddress: (bytes intPtrAtOffset: 0)!

owner: struct
	"Private - Set the value of the receiver's 'owner' instance variable to the <AXTypeInfoStructure> 
	argument, struct. Answer the receiver."

	owner := struct!

printOn: aStream
	"Append a textual representation of the receiver to aStream."

	aStream
		basicPrint: self;
		nextPut: $(.
	self isAnonymous
		ifTrue: 
			[aStream
				nextPutAll: 'Anon: ';
				print: self typeInfo name]
		ifFalse: [aStream print: self typeName].
	aStream nextPut: $)!

tdesc
	"Answer a <TYPEDESC> which is the type of the element described by the receiver.
	Implementation Note: Set the back-pointer to be the same as the receiver's, since it
	is the destruction of the <AXTypeInfoStructure> which we wish to postpone for the
	lifetime of the TYPEDESC."

	^self lptdesc owner: owner!

tdescArray
	"Answer a <TYPEDESC> which is the type of the array described by the receiver.
	Implementation Note: Set the back-pointer to be the same as the receiver's, since it
	is the destruction of the <AXTypeInfoStructure> which we wish to postpone for the
	lifetime of the TYPEDESC."

	^self lpadesc
		owner: owner!

typeDesc
	"Recurse down through any typedefs to resolve the actual element type."

	| vt |
	vt := self vt.
	vt == VT_PTR ifTrue: [^self tdesc typeDesc].
	vt == VT_CARRAY ifTrue: [^self tdescArray tdesc typeDesc].
	vt == VT_USERDEFINED ifTrue: [self typeInfo tdesc typeDesc].
	^self!

typeInfo
	^typeInfo ifNil: [typeInfo := self getRefType]!

typeName
	"Answer the Dolphin external type name for the type described by the receiver."

	^self isAnonymous
		ifFalse: 
			[| desc answer |
			desc := self classDesc.
			answer := desc key typeName.
			desc value timesRepeat: [answer := answer , '*'].
			answer]!

vartype
	"Private - Answer the ultimate (implementation) variant type of the receiver.
	This may involve chasing down through aliases, etc, if the type is user defined."

	| vt |
	vt := self vt.
	self assert: [vt <= 16rFFF	"modifier flags not valid in a TYPEDESC"].
	(vt == VT_PTR or: [vt == VT_SAFEARRAY]) ifTrue: [^self tdesc vartype].
	vt == VT_USERDEFINED 
		ifTrue: 
			["Chase down the actual type via the referenced Type Info."

			^self typeInfo vt].
	^vt!

vt
	"Answer the receiver's vt field as a Smalltalk object."

	^bytes wordAtOffset: ##(self offsetOf: #vt)!

vtName
	"Private - Answer the Dolphin external type name for the receiver's variant type."

	^VARIANT nameOfVT: self vartype! !
!TYPEDESC categoriesFor: #analyzer!accessing!private! !
!TYPEDESC categoriesFor: #arrayDesc!development!private! !
!TYPEDESC categoriesFor: #buildClassDesc!helpers!private! !
!TYPEDESC categoriesFor: #classDesc!accessing!private! !
!TYPEDESC categoriesFor: #getRefType!accessing!private! !
!TYPEDESC categoriesFor: #hreftype!**compiled accessors**!public! !
!TYPEDESC categoriesFor: #isAnonymous!public!testing! !
!TYPEDESC categoriesFor: #isStructure!public!testing! !
!TYPEDESC categoriesFor: #isUnion!public!testing! !
!TYPEDESC categoriesFor: #isUserDefined!public!testing! !
!TYPEDESC categoriesFor: #lpadesc!**compiled accessors**!public! !
!TYPEDESC categoriesFor: #lptdesc!**compiled accessors**!public! !
!TYPEDESC categoriesFor: #owner:!accessing!private! !
!TYPEDESC categoriesFor: #printOn:!development!printing!public! !
!TYPEDESC categoriesFor: #tdesc!accessing!public! !
!TYPEDESC categoriesFor: #tdescArray!accessing!public! !
!TYPEDESC categoriesFor: #typeDesc!helpers!private! !
!TYPEDESC categoriesFor: #typeInfo!accessing!public! !
!TYPEDESC categoriesFor: #typeName!accessing!public! !
!TYPEDESC categoriesFor: #vartype!accessing!public! !
!TYPEDESC categoriesFor: #vt!**compiled accessors**!public! !
!TYPEDESC categoriesFor: #vtName!accessing!private! !

!TYPEDESC class methodsFor!

defineFields
	"Define the fields of the TYPEDESC structure.
		TYPEDESC compileDefinition
	
		typedef 		struct tagTYPEDESC {
			union 
			{
				TYPEDESC *lptdesc;
				ARRAYDESC *lpadesc;
				HREFTYPE hreftype;			// Handle to identify type description
			};
			VARTYPE vt;
		} TYPEDESC;

	See the constants beginning 'VT_...' in AXAutomationConstants for VARTYPEs.
	"

	self
		defineField: #lptdesc type: (PointerField type: TYPEDESC) beReadOnly;
		defineField: #vt type: WORDField readOnly.

	"Other fields of the union"
	self
		defineField: #lpadesc
			type: (PointerField type: ARRAYDESC) beReadOnly
			offset: 0;
		defineField: #hreftype
			type: DWORDField readOnly
			offset: 0!

initialize
	VTIndirections := Array new: VT_CLSID+1 withAll: 0.
	VTIndirections
		at: VT_DISPATCH put: 1;
		at: VT_UNKNOWN put: 1;
		at: VT_SAFEARRAY put: 1;
		at: VT_LPSTR put: 1;
		at: VT_LPWSTR put: 1! !
!TYPEDESC class categoriesFor: #defineFields!initializing!public! !
!TYPEDESC class categoriesFor: #initialize!class initialization!public! !
