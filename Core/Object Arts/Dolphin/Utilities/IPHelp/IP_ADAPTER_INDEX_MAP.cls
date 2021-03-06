﻿"Filed out from Dolphin Smalltalk 7"!

ExternalStructure subclass: #IP_ADAPTER_INDEX_MAP
	instanceVariableNames: ''
	classVariableNames: '_OffsetOf_index _OffsetOf_Name'
	poolDictionaries: ''
	classInstanceVariableNames: ''!
IP_ADAPTER_INDEX_MAP guid: (GUID fromString: '{fc9307a0-b028-4f04-81c9-9d74847a63ef}')!
IP_ADAPTER_INDEX_MAP addClassConstant: '_OffsetOf_index' value: 16r0!
IP_ADAPTER_INDEX_MAP addClassConstant: '_OffsetOf_Name' value: 16r4!
IP_ADAPTER_INDEX_MAP comment: '<IP_ADAPTER_INDEX_MAP> is an <ExternalStructure> class to wrap the struct ''Win32.IP_ADAPTER_INDEX_MAP'' from type information in the ''Win32 API (ANSI). Derived from Bruce McKinney´s Hardcore Visual Basic Type Library'' library.

The type library contains no documentation for this struct

Warning: This comment was automatically generated from the struct''s type information, but any changes made here will not be overwritten if the wrapper class is regenerated.

IDL definition follows:

typedef 
struct tagIP_ADAPTER_INDEX_MAP {
	unsigned long index;
	unsigned short Name[128];
} IP_ADAPTER_INDEX_MAP;
'!
!IP_ADAPTER_INDEX_MAP categoriesForClass!Win32-Structs! !
!IP_ADAPTER_INDEX_MAP methodsFor!

index
	"Answer the <Integer> value of the receiver's 'index' field."

	^bytes dwordAtOffset: _OffsetOf_index!

Name
	"Answer the <Utf16String> value of the receiver's 'Name' field."

	^Utf16String fromAddress: bytes yourAddress + _OffsetOf_Name! !
!IP_ADAPTER_INDEX_MAP categoriesFor: #index!**compiled accessors**!public! !
!IP_ADAPTER_INDEX_MAP categoriesFor: #Name!**compiled accessors**!public! !

!IP_ADAPTER_INDEX_MAP class methodsFor!

defineFields
	"Define the fields of the IP_ADAPTER_INDEX_MAP structure.
		IP_ADAPTER_INDEX_MAP compileDefinition
	
		typedef 
		struct tagIP_ADAPTER_INDEX_MAP {
			unsigned long index;
			unsigned short Name[128];
		} IP_ADAPTER_INDEX_MAP;
"

	self
		defineField: #index
			type: DWORDField readOnly
			offset: 0;
		defineField: #Name
			type: ((StringField type: Utf16String length: 128)
					beReadOnly;
					yourself)
			offset: 4.
	self byteSize: 260!

getFieldNames
	^#(#index #Name)! !
!IP_ADAPTER_INDEX_MAP class categoriesFor: #defineFields!initializing!public! !
!IP_ADAPTER_INDEX_MAP class categoriesFor: #getFieldNames!**compiled accessors**!constants!private! !

