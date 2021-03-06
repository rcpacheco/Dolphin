﻿"Filed out from Dolphin Smalltalk 7"!

MultilineTextEditTest subclass: #RichTextEditTest
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	classInstanceVariableNames: ''!
RichTextEditTest guid: (GUID fromString: '{bc34bf3f-4b1c-44a8-9c0c-b25db1e72469}')!
RichTextEditTest comment: ''!
!RichTextEditTest categoriesForClass!Unclassified! !
!RichTextEditTest methodsFor!

classToTest
	^RichTextEdit!

margins
	^0 @ 1!

nonProportionalFont
	^Font name: 'Consolas'!

testCharNearestPosition
	| text point char |
	#'1551'.
	text := (FileStream read: SourceManager default sourcesFileName) next: 100000.
	presenter text: text.
	(Array
		with: 1
		with: (presenter view positionAtLine: 2)
		with: (presenter view positionAtLine: 1000)
		with: (presenter view positionAtLine: (presenter view lineFromPosition: text size // 2))
		with: (presenter view positionAtLine: (presenter view lineFromPosition: text size))) do: 
				[:each |
				point := presenter view positionOfChar: each.
				char := presenter view charNearestPosition: point.
				self assert: char equals: each]!

testStreamInAnsiText
	| text ansi rtf actual |
	"The control asks for the text in blocks of just under 4k, so provide a little more to ensure the buffer it provides is insufficiently large to hold all the text."
	text := AnsiString writeStream: 4200.
	[text size < 4100] whileTrue: 
			[text
				nextPutAll: 'The quick brown fox jumped over the lazy dog';
				cr].
	ansi := text contents.
	presenter text: ansi.
	actual := presenter ansiText.
	self assert: actual equals: ansi.
	presenter text: ''.
	presenter ansiText: ansi.
	actual := presenter ansiText.
	self assert: actual equals: ansi.

	"Check selection"
	rtf := presenter rtfText.
	presenter selectAll.
	actual := presenter selectionRtf.
	self assert: actual equals: rtf.
	presenter selectLine: 10.
	actual := presenter selectionRtf.
	"This test is locale sensitive and may need revision"
	rtf := '{\rtf1\ansi\deff0{\fonttbl{\f0\fnil\fcharset0 Segoe UI;}}
\uc1\pard\lang<2d>\f0\fs20 over the lazy dog}
'
				expandMacrosWith: Character.AnsiCodePage
				with: Locale userDefault lcid.
	self assert: actual equals: rtf.

	"Now stream in the ANSI RTF"
	rtf := presenter rtfText.
	presenter text: ''.
	presenter rtfText: rtf.
	actual := presenter ansiText.
	self assert: actual equals: ansi.
	presenter rtfText: rtf.!

testStreamInUtfText
	| text rtf actual |
	"The control asks for the text in blocks of just under 4k, so provide a little more to ensure the buffer it provides is insufficiently large to hold all the text."
	text := Utf8String writeStream: 4200.
	[text size < 4100] whileTrue: 
			[text
				nextPutAll: self text;
				cr].
	text := text contents.
	"This has to be converted to UTF-16 on the way in"
	presenter utfText: text.
	actual := presenter utfText.
	self assert: actual equals: text.

	"Now via UTF, which can pass UTF8 directly"
	rtf := presenter urtfText.
	"If it contains bad characters, then the stream out didn't maintain the encoded bytes correctly"
	self deny: (rtf includes: Character replacement).
	presenter
		text: '';
		rtfText: rtf.
	actual := presenter utfText.
	self assert: actual equals: text.
	actual := presenter urtfText.
	"The RTF itself may vary slightly depending on the whim of the RTE, so may not be exactly equal. It should have the same result, however. Repeat"
	presenter rtfText: rtf.
	actual := presenter utfText.
	self assert: actual equals: text.
	rtf := presenter urtfText.

	"Check selection"
	presenter selectAll.
	actual := presenter selectionUrtf.
	self assert: actual equals: rtf.
	presenter selectLine: 10.
	actual := presenter selectionUrtf.
	"This test is locale sensitive and may need revision"
	rtf := '{\urtf1\ansi\ansicpg<1d>\deff0{\fonttbl{\f0\fnil\fcharset0 Segoe UI;}{\f1\fnil\fcharset238 Segoe UI;}}
\uc1\pard\lang<2d>\f0\fs20 ĉṓɲṩḙċ\f1 ť\f0 ᶒțûɾ ấɖḯƥĭṩ\f1 čį\f0 ɳġ ḝ\f1 łį\f0 ʈ}
'
				expandMacrosWith: Character.AnsiCodePage
				with: Locale userDefault lcid.
	self assert: actual equals: rtf.

	"Check round-trip as ANSI RTF (which has an escape syntax to preserve international characters)"
	presenter text: text.
	rtf := presenter rtfText.
	presenter
		text: '';
		rtfText: rtf.
	actual := presenter utfText.
	self assert: actual equals: text.
	actual := presenter rtfText.
	self assert: actual equals: rtf!

text
	"As of v2.0 of the RichEdit control, it strips out CRs internally, and so positions will be out relative to the original text"

	^'Ḽơᶉëᶆ ȋṕšᶙṁ ḍỡḽǭᵳ ʂǐť ӓṁệẗ, ĉṓɲṩḙċťᶒțûɾ ấɖḯƥĭṩčįɳġ ḝłįʈ'! !
!RichTextEditTest categoriesFor: #classToTest!helpers!private! !
!RichTextEditTest categoriesFor: #margins!private!unit tests! !
!RichTextEditTest categoriesFor: #nonProportionalFont!constants!private! !
!RichTextEditTest categoriesFor: #testCharNearestPosition!public!unit tests! !
!RichTextEditTest categoriesFor: #testStreamInAnsiText!public!unit tests! !
!RichTextEditTest categoriesFor: #testStreamInUtfText!public!unit tests! !
!RichTextEditTest categoriesFor: #text!public! !

