﻿"Filed out from Dolphin Smalltalk 7"!

Win32Structure subclass: #HOSTENT
	instanceVariableNames: ''
	classVariableNames: '_OffsetOf_h_addr_list _OffsetOf_h_addrtype _OffsetOf_h_aliases _OffsetOf_h_length _OffsetOf_h_name'
	poolDictionaries: 'WinSocketConstants'
	classInstanceVariableNames: ''!
HOSTENT guid: (GUID fromString: '{87b4c5f4-026e-11d3-9fd7-00a0cc3e4a32}')!
HOSTENT addClassConstant: '_OffsetOf_h_addr_list' value: 16rC!
HOSTENT addClassConstant: '_OffsetOf_h_addrtype' value: 16r8!
HOSTENT addClassConstant: '_OffsetOf_h_aliases' value: 16r4!
HOSTENT addClassConstant: '_OffsetOf_h_length' value: 16rA!
HOSTENT addClassConstant: '_OffsetOf_h_name' value: 16r0!
HOSTENT comment: '<HOSTENT> is an <ExternalStructure> class to wrap the struct ''Win32.HOSTENT'' from type information in the ''Win32 API'' library.

The type library contains the following helpstring for this struct
	"Stores information about a given host, such as host name, IPv4 address, and so forth. An application should never attempt to modify this structure or to free any of its components. Furthermore, only one copy of the hostent structure is allocated per thread."

Warning: This comment was automatically generated from the struct''s type information, but any changes made here will not be overwritten if the wrapper class is regenerated.

IDL definition follows:

typedef [uuid(87B4C5F4-026E-11D3-9FD7-00A0CC3E4A32), helpstring("Stores information about a given host, such as host name, IPv4 address, and so forth. An application should never attempt to modify this structure or to free any of its components. Furthermore, only one copy of the hostent structure is allocated per thread.")]
struct tagHOSTENT {
	[readonly, helpstring("The official name of the host (PC). If using the DNS or similar resolution system, it is the Fully Qualified Domain Name (FQDN) that caused the server to return a reply. If using a local hosts file, it is the first entry after the IPv4 address.")] LPCSTR h_name;
	[readonly, helpstring("A NULL-terminated array of alternate names.")] void** h_aliases;
	[readonly, helpstring("The type of address being returned.")] short h_addrtype;
	[readonly, helpstring("The length, in bytes, of each address.")] short h_length;
	[readonly, helpstring("A NULL-terminated list of addresses for the host. Addresses are returned in network byte order.")] void** h_addr_list;
} HOSTENT;
'!
!HOSTENT categoriesForClass!Win32-Structs! !
!HOSTENT methodsFor!

address
	"Answer the primary <InternetAddress> for the receiver"

	^(self addressClass fromAddress: self h_addr) address!

addressClass
	^self h_addrtype == WinSocketConstants.AF_INET6 ifTrue: [IN6_ADDR] ifFalse: [IN_ADDR]!

allAddresses
	"Answer an <Array> of <InternetAddress>, composed from the receiver's
	address list."

	^self reifyNullTerminatedArray: self h_addr_list!

allAliases
	"Answer an <Array> of <InternetAddress>, composed from the receiver's
	alias list."

	^self reifyNullTerminatedArray: self h_aliases!

h_addr
	"Answer the FIRST entry in the receiver's h_addr_list field"

	^self h_addr_list dwordAtOffset: 0!

h_addr_list
	"Answer the <ExternalAddress> value of the receiver's 'h_addr_list' field."

	^(bytes uintPtrAtOffset: _OffsetOf_h_addr_list) asExternalAddress!

h_addrtype
	"Answer the <Integer> value of the receiver's 'h_addrtype' field."

	^bytes swordAtOffset: _OffsetOf_h_addrtype!

h_aliases
	"Answer the <ExternalAddress> value of the receiver's 'h_aliases' field."

	^(bytes uintPtrAtOffset: _OffsetOf_h_aliases) asExternalAddress!

h_length
	"Answer the <Integer> value of the receiver's 'h_length' field."

	^bytes swordAtOffset: _OffsetOf_h_length!

h_name
	"Answer the <AnsiString> value of the receiver's 'h_name' field."

	^AnsiString fromAddress: (bytes intPtrAtOffset: _OffsetOf_h_name)!

host
	"Answer the host name embedded in the receiver, trimming trailing nulls."

	^self h_name trimNulls!

reifyNullTerminatedArray: list
	| i each addresses addressClass |
	addresses := OrderedCollection new.
	i := 0.
	addressClass := self addressClass.
	
	[each := list uintPtrAtOffset: i.
	each isNull] whileFalse: 
				[addresses add: (addressClass fromAddress: each) address.
				i := i + VMConstants.IntPtrSize].
	^addresses asArray! !
!HOSTENT categoriesFor: #address!accessing!public! !
!HOSTENT categoriesFor: #addressClass!helpers!private! !
!HOSTENT categoriesFor: #allAddresses!accessing!public! !
!HOSTENT categoriesFor: #allAliases!accessing!public! !
!HOSTENT categoriesFor: #h_addr!accessing!public! !
!HOSTENT categoriesFor: #h_addr_list!**compiled accessors**!public! !
!HOSTENT categoriesFor: #h_addrtype!**compiled accessors**!public! !
!HOSTENT categoriesFor: #h_aliases!**compiled accessors**!public! !
!HOSTENT categoriesFor: #h_length!**compiled accessors**!public! !
!HOSTENT categoriesFor: #h_name!**compiled accessors**!public! !
!HOSTENT categoriesFor: #host!accessing!public! !
!HOSTENT categoriesFor: #reifyNullTerminatedArray:!helpers!private! !

!HOSTENT class methodsFor!

defineFields
	"Define the fields of the HOSTENT structure.

	HOSTENT  compileDefinition

		typedef [uuid(87B4C5F4-026E-11D3-9FD7-00A0CC3E4A32), helpstring('Stores information about a given host, such as host name, IPv4 address, and so forth. An application should never attempt to modify this structure or to free any of its components. Furthermore, only one copy of the hostent structure is allocated per thread.')]
		struct tagHOSTENT {
			[readonly, helpstring('The official name of the host (PC). If using the DNS or similar resolution system, it is the Fully Qualified Domain Name (FQDN) that caused the server to return a reply. If using a local hosts file, it is the first entry after the IPv4 address.')] LPCSTR h_name;
			[readonly, helpstring('A NULL-terminated array of alternate names.')] void** h_aliases;
			[readonly, helpstring('The type of address being returned.')] short h_addrtype;
			[readonly, helpstring('The length, in bytes, of each address.')] short h_length;
			[readonly, helpstring('A NULL-terminated list of addresses for the host. Addresses are returned in network byte order.')] void** h_addr_list;
		} HOSTENT;
"

	self
		defineField: #h_name type: (PointerField type: AnsiString) beReadOnly offset: 0;
		defineField: #h_aliases type: LPVOIDField new beReadOnly offset: 4;
		defineField: #h_addrtype type: SWORDField new beReadOnly offset: 8;
		defineField: #h_length type: SWORDField new beReadOnly offset: 10;
		defineField: #h_addr_list type: LPVOIDField new beReadOnly offset: 12.
	self byteSize: 16!

getFieldNames
	^#(#h_name #h_aliases #h_addrtype #h_length #h_addr_list)!

host: aStringHostName
	"Answer a new instance of the receiver describing a host with the name 
	held in aStringHostName.
		(self host: SessionManager current computerName) address
	"

	| answer |
	answer := WS2_32Library default gethostbyname: aStringHostName asAnsiString.
	^answer isNull ifTrue: [SocketError signalWith: Processor activeProcess lastError] ifFalse: [answer]! !
!HOSTENT class categoriesFor: #defineFields!**auto generated**!public!template definition! !
!HOSTENT class categoriesFor: #getFieldNames!**compiled accessors**!constants!private! !
!HOSTENT class categoriesFor: #host:!instance creation!public! !

