﻿"Filed out from Dolphin Smalltalk 7"!

Association subclass: #STONTestAssociation
	instanceVariableNames: 'timestamp'
	classVariableNames: ''
	poolDictionaries: ''
	classInstanceVariableNames: ''!
STONTestAssociation guid: (GUID fromString: '{d412d7d7-3654-4d31-9ebf-dbbe2a26135a}')!
STONTestAssociation comment: 'STONTestAssociation is used to support unit tests.
'!
!STONTestAssociation categoriesForClass!STON-Tests-Base! !
!STONTestAssociation methodsFor!

key: aKey value: anObject 
	super key: aKey value: anObject.
	timestamp := self now!

now
	^ DateAndTime now!

timestamp
	^ timestamp!

value: anObject
	super value: anObject.
	timestamp := self now! !
!STONTestAssociation categoriesFor: #key:value:!accessing!public! !
!STONTestAssociation categoriesFor: #now!accessing!public! !
!STONTestAssociation categoriesFor: #timestamp!accessing!public! !
!STONTestAssociation categoriesFor: #value:!accessing!public! !

