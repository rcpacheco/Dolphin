﻿"Filed out from Dolphin Smalltalk 7"!

HistoryBrowser subclass: #MethodHistoryBrowser
	instanceVariableNames: 'history class selector debugger selection slider source'
	classVariableNames: ''
	poolDictionaries: ''
	classInstanceVariableNames: ''!
MethodHistoryBrowser guid: (GUID fromString: '{58d8a262-ac1f-455c-ad71-5ebab63f34e3}')!
MethodHistoryBrowser comment: 'Searches the sources and changes files to provide a change history for a method and opens a browser on the results.

Usage:
ClassHistoryBrowser showOnClass: aClass selector: aSelectorSymbol

Versions of the method can be selected by using the controls at the top of the browser.

Versions are in the correct order but sequential duplicates have been removed.  If an method appears in the sources file 
and the changes file then the version from the sources file will be the first in the list.

The current version of the method can be
- copied.  To the clipboard
- restored.  The newly restored method will be added to the end of the list
- diffed.  A DifferencesPresenter will be opend comparing the current selection with the last version

If the IDB IDE Printer package is installed then the current version can be printed.


(C) 2005 Ian Bartholomew
ian@idb.me.uk
Public Domain Freeware'!
!MethodHistoryBrowser categoriesForClass!IDB Goodies! !
!MethodHistoryBrowser methodsFor!

about
	"Display the about view"

	self 
		about: '
Method History Browser
for
Dolphin Smalltalk 6.x

Version 6b
© 2005 Ian Bartholomew
http://www.idb.me.uk'!

canPrint
	^[super canPrint] on: MessageNotUnderstood do: [:e | false]!

createComponents
	super createComponents.
	slider := self add: NumberPresenter new name: 'slider'.
	source := self add: MethodWorkspace new name: 'source'!

createSchematicWiring
	super createSchematicWiring.
	slider 
		when: #valueChanged
		send: #onSliderValueChanged
		to: self.
	(SmalltalkSystem current)
		when: #methodAdded:
			send: #onMethodAdded:
			to: self;
		when: #methodUpdated:
			send: #onMethodUpdated:
			to: self;
		when: #methodRemoved:
			send: #onMethodRemoved:
			to: self!

currentMethod
	^self methodClass ifNotNil: [:mc | mc compiledMethodAt: selector ifAbsent: []]!

diff
	(DiffBrowser show: 'Vertical view')
		textFont: MethodWorkspace actualFont;
		styler: SmalltalkMethodStyler new;
		textStyles: MethodWorkspace textStyles;
		caption: self methodClass name , '>>' , selector;
		compare: ((history at: selection) at: 3)
			id: 'Version #' , selection printString
			and: ((history at: history size) at: 3)
			id: 'Current image'!

methodClass
	^class!

moveTo: anInteger 
	selection := anInteger.
	self updateSelection!

moveToFirst
	self moveTo: 1!

moveToLast
	self moveTo: history size!

moveToNext
	self moveTo: selection + 1!

moveToPrevious
	self moveTo: selection - 1!

onImageChanged: aCompiledMethod
	(aCompiledMethod methodClass == self methodClass and: [aCompiledMethod selector == selector])
		ifTrue: [self updateHistory]!

onMethodAdded: aCompilationResult
	self onImageChanged: aCompilationResult method!

onMethodRemoved: aCompiledMethod 
	self onImageChanged: aCompiledMethod!

onMethodUpdated: aCompilationResult 
	self onImageChanged: aCompilationResult method!

onSliderValueChanged
	self moveTo: slider model value!

onViewClosed
	"Private - This is needed to prevent events trying to access this shell
	after it is closed but before it is garbage collected"

	super onViewClosed.
	SmalltalkSystem current removeEventsTriggeredFor: self!

onViewOpened	
	super onViewOpened.
	source view isReadOnly: true.
	selection := history size!

parseContext
	^self methodClass!

printableView
	^source view!

queryCommand: aCommandQuery 
	(#(#print #printPreview) identityIncludes: aCommandQuery command) 
		ifTrue: 
			[aCommandQuery isEnabled: self canPrint.
			^true].
	aCommandQuery command == #moveToFirst 
		ifTrue: 
			[aCommandQuery isEnabled: selection ~= 1.
			^true].
	(#(#diff #moveToLast) identityIncludes: aCommandQuery command) 
		ifTrue: 
			[aCommandQuery isEnabled: selection ~= history size.
			^true].
	#restoreMethod == aCommandQuery command 
		ifTrue: 
			[ | method |
			method := self currentMethod.
			aCommandQuery isEnabled: (method isNil or: [method getSource ~= self source]).
			^true].
	aCommandQuery command == #moveToPrevious 
		ifTrue: 
			[aCommandQuery isEnabled: history size ~= 1 & (selection > 1).
			^true].
	aCommandQuery command == #moveToNext 
		ifTrue: 
			[aCommandQuery isEnabled: history size ~= 1 & (selection < history size).
			^true].
	^super queryCommand: aCommandQuery!

restoreMethod
	"Restore the selected method. Check for a compilation failure - although it 
	should be obvious, the displayed  method will be in red , we don't want to 
	let this go without a warning. The history browser will be updated by the 
	normal event mechanism"

	(self methodClass compile: self source) isNil ifTrue: [^MessageBox warning: 'Restore failed'].
	debugger ifNotNil: [debugger restartMethod]!

selectedMethod
	^nil!

setCaption
	self caption: (String writeStream
				nextPutAll: 'MethodHistory - ';
				nextPutAll: self methodClass name;
				nextPutAll: '>>';
				nextPutAll: selector asString;
				nextPutAll: '  (';
				print: selection;
				nextPutAll: ' of ';
				print: history size;
				nextPut: $);
				contents)!

setClass: aClass selector: aSymbol debugger: aDebuggerOrNil
	"Initialze the list by locating the source for all the historical methods for the selected
	class/selector. Rememer if it was opened from a Debugger so that we can perform an additioal
	step if historical source is restored"

	class := aClass.
	selector := aSymbol.
	debugger := aDebuggerOrNil.
	self updateHistory!

source
	^(history at: selection) at: 3!

updateHistory
	"Get the historic information for the method. Purge consecutive duplicates from the list"

	| temp |
	Cursor wait showWhile: [temp := self scanner forMethod: selector inClass: self methodClass].
	history := OrderedCollection with: temp first.
	temp do: 
			[:each |
			(history last at: 1) = (each at: 1) & ((history last at: 3) = (each at: 3))
				ifFalse: [history add: each]].
	self setCaption.
	self moveToLast!

updateSelection
	source text: ((history at: selection) at: 3).
	history size = 1
		ifTrue:
			[(slider view)
				range: (0 to: 1);
				isEnabled: false.
			slider value: 1]
		ifFalse:
			[(slider view)
				range: (1 to: history size);
				isEnabled: true.
			slider value: selection].
	self setCaption! !
!MethodHistoryBrowser categoriesFor: #about!commands!public! !
!MethodHistoryBrowser categoriesFor: #canPrint!printing!public!testing! !
!MethodHistoryBrowser categoriesFor: #createComponents!initializing!public! !
!MethodHistoryBrowser categoriesFor: #createSchematicWiring!initializing!public! !
!MethodHistoryBrowser categoriesFor: #currentMethod!accessing!private! !
!MethodHistoryBrowser categoriesFor: #diff!commands!public! !
!MethodHistoryBrowser categoriesFor: #methodClass!public! !
!MethodHistoryBrowser categoriesFor: #moveTo:!operations!public! !
!MethodHistoryBrowser categoriesFor: #moveToFirst!commands!public! !
!MethodHistoryBrowser categoriesFor: #moveToLast!commands!public! !
!MethodHistoryBrowser categoriesFor: #moveToNext!commands!public! !
!MethodHistoryBrowser categoriesFor: #moveToPrevious!commands!public! !
!MethodHistoryBrowser categoriesFor: #onImageChanged:!event handling!public! !
!MethodHistoryBrowser categoriesFor: #onMethodAdded:!event handling!public! !
!MethodHistoryBrowser categoriesFor: #onMethodRemoved:!event handling!public! !
!MethodHistoryBrowser categoriesFor: #onMethodUpdated:!event handling!public! !
!MethodHistoryBrowser categoriesFor: #onSliderValueChanged!initializing!public! !
!MethodHistoryBrowser categoriesFor: #onViewClosed!event handling!public! !
!MethodHistoryBrowser categoriesFor: #onViewOpened!event handling!public! !
!MethodHistoryBrowser categoriesFor: #parseContext!public! !
!MethodHistoryBrowser categoriesFor: #printableView!accessing!printing!public! !
!MethodHistoryBrowser categoriesFor: #queryCommand:!commands!public! !
!MethodHistoryBrowser categoriesFor: #restoreMethod!commands!public! !
!MethodHistoryBrowser categoriesFor: #selectedMethod!public! !
!MethodHistoryBrowser categoriesFor: #setCaption!operations!public! !
!MethodHistoryBrowser categoriesFor: #setClass:selector:debugger:!accessing!public! !
!MethodHistoryBrowser categoriesFor: #source!commands!public! !
!MethodHistoryBrowser categoriesFor: #updateHistory!operations!public! !
!MethodHistoryBrowser categoriesFor: #updateSelection!event handling!public! !

!MethodHistoryBrowser class methodsFor!

resource_Default_view
	"Answer the literal data from which the 'Default view' resource can be reconstituted.
	DO NOT EDIT OR RECATEGORIZE THIS METHOD.

	If you wish to modify this resource evaluate:
	ViewComposer openOn: (ResourceIdentifier class: self selector: #resource_Default_view)
	"

	^#(#'!!STL' 4 788558 10 ##(Smalltalk.STBViewProxy) ##(Smalltalk.ShellView) 34 27 nil nil 8 #(13565952 65536) 416 nil 327686 ##(Smalltalk.Color) #face3d 328198 ##(Smalltalk.Point) 1261 601 517 nil nil nil 416 852230 ##(Smalltalk.FramingLayout) 170 176 34 4 410 ##(Smalltalk.ContainerView) 34 15 nil 416 34 2 8 1140850688 131073 592 nil nil nil 7 nil nil nil 592 530 170 176 34 6 410 ##(Smalltalk.ContainerView) 34 15 nil 592 34 2 8 1140850688 131073 704 nil nil nil 7 nil nil nil 704 530 170 176 34 10 410 ##(Smalltalk.PushButton) 34 20 nil 704 34 2 8 1140924416 1 816 nil nil nil 7 nil nil nil 816 nil 8 1906506480 1180998 4 ##(Smalltalk.CommandDescription) #moveToNext 8 '>' 1 1 nil nil false nil nil nil 983302 ##(Smalltalk.MessageSequence) 138 144 34 3 721670 ##(Smalltalk.MessageSend) #createAt:extent: 34 2 498 489 9 498 49 57 816 1010 #isEnabled: 8 #(false) 816 1010 #text: 34 1 8 '>' 816 983302 ##(Smalltalk.WINDOWPLACEMENT) 8 #[44 0 0 0 0 0 0 0 1 0 0 0 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 244 0 0 0 4 0 0 0 12 1 0 0 32 0 0 0] 8 #() 498 193 193 nil 29 1181766 2 ##(Smalltalk.FramingConstraints) 1180678 ##(Smalltalk.FramingCalculation) #fixedViewRight -47 1282 #fixedPreviousLeft -7 1282 #fixedParentTop 9 1282 #fixedParentBottom -7 410 ##(Smalltalk.PushButton) 34 20 nil 704 34 2 8 1140924416 1 1360 nil nil nil 7 nil nil nil 1360 nil 8 1906506480 898 #moveToPrevious 8 '<' 1 1 nil nil false nil nil nil 946 138 144 34 3 1010 #createAt:extent: 34 2 498 65 9 498 49 57 1360 1010 #isEnabled: 8 #(false) 1360 1010 #text: 34 1 8 '<' 1360 1170 8 #[44 0 0 0 0 0 0 0 1 0 0 0 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 32 0 0 0 4 0 0 0 56 0 0 0 32 0 0 0] 8 #() 1232 nil 29 1250 1282 #fixedPreviousRight 9 1282 #fixedViewLeft 49 1328 9 1344 -7 410 ##(Smalltalk.PushButton) 34 20 nil 704 34 2 8 1140924416 1 1760 nil nil nil 7 nil nil nil 1760 nil 8 1906506480 898 #moveToLast 8 '>|' 1 1 nil nil false nil nil nil 946 138 144 34 3 1010 #createAt:extent: 34 2 498 545 9 498 49 57 1760 1010 #isEnabled: 8 #(false) 1760 1010 #text: 34 1 8 '>|' 1760 1170 8 #[44 0 0 0 0 0 0 0 1 0 0 0 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 16 1 0 0 4 0 0 0 40 1 0 0 32 0 0 0] 8 #() 1232 nil 29 1250 1296 -47 1282 #fixedParentRight -7 1328 9 1344 -7 410 ##(Smalltalk.PushButton) 34 20 nil 704 34 2 8 1140924416 1 2144 nil nil nil 7 nil nil nil 2144 nil 8 1906506480 898 #moveToFirst 8 '|<' 1 1 nil nil false nil nil nil 946 138 144 34 3 1010 #createAt:extent: 34 2 498 9 9 498 49 57 2144 1010 #isEnabled: 8 #(false) 2144 1010 #text: 34 1 8 '|<' 2144 1170 8 #[44 0 0 0 0 0 0 0 1 0 0 0 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 4 0 0 0 4 0 0 0 28 0 0 0 32 0 0 0] 8 #() 1232 nil 29 1250 1282 #fixedParentLeft 9 1744 49 1328 9 1344 -7 410 ##(Smalltalk.Slider) 34 18 nil 704 34 2 8 1140916485 1 2528 721990 2 ##(Smalltalk.ValueHolder) nil false 1376774 ##(Smalltalk.PluggableSearchPolicy) 459270 ##(Smalltalk.Message) #= 8 #() 2658 #hash 8 #() 3 nil nil 7 nil nil nil 2528 nil 8 1906420688 852486 ##(Smalltalk.NullConverter) nil nil 3 nil nil 946 138 144 34 3 1010 #createAt:extent: 34 2 498 121 1 498 361 71 2528 1010 #pageSize: 8 #(1) 2528 1010 #range: 34 1 525062 ##(Smalltalk.Interval) 1 3 3 2528 1170 8 #[44 0 0 0 0 0 0 0 1 0 0 0 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 60 0 0 0 0 0 0 0 240 0 0 0 35 0 0 0] 8 #() 1232 nil 27 1250 2512 121 2128 -119 1328 1 1282 #fixedViewTop 71 170 192 34 2 2528 8 'slider' nil 946 138 144 34 1 1010 #createAt:extent: 34 2 498 323 1 498 601 73 704 1170 8 #[44 0 0 0 0 0 0 0 1 0 0 0 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 161 0 0 0 0 0 0 0 205 1 0 0 36 0 0 0] 34 5 2144 1360 1760 816 2528 1232 nil 27 1250 1728 51 1744 601 1328 1 1344 1 410 ##(Smalltalk.PushButton) 34 20 nil 592 34 2 8 1140924416 1 3296 nil nil nil 7 nil nil nil 3296 nil 8 1906506480 898 #diff 8 'Diff' 1 1 nil nil false nil nil nil 946 138 144 34 3 1010 #createAt:extent: 34 2 498 153 9 498 121 57 3296 1010 #isEnabled: 8 #(false) 3296 1010 #text: 34 1 8 'Diff' 3296 1170 8 #[44 0 0 0 0 0 0 0 1 0 0 0 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 76 0 0 0 4 0 0 0 136 0 0 0 32 0 0 0] 8 #() 1232 nil 29 1250 1728 17 1744 121 1328 9 1344 -7 410 ##(Smalltalk.PushButton) 34 20 nil 592 34 2 8 1140924416 1 3664 nil nil nil 7 nil nil nil 3664 nil 8 1906506480 898 #restoreMethod 8 'Restore' 1 1 nil nil false nil nil nil 946 138 144 34 3 1010 #createAt:extent: 34 2 498 17 9 498 121 57 3664 1010 #isEnabled: 8 #(false) 3664 1010 #text: 34 1 8 'Restore' 3664 1170 8 #[44 0 0 0 0 0 0 0 1 0 0 0 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 8 0 0 0 4 0 0 0 68 0 0 0 32 0 0 0] 8 #() 1232 nil 29 1250 2512 17 1744 121 1328 9 1344 -7 170 192 8 #() nil 946 138 144 34 1 1010 #createAt:extent: 34 2 498 1 1 498 1229 73 592 1170 8 #[44 0 0 0 0 0 0 0 1 0 0 0 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 0 0 0 0 0 0 0 0 102 2 0 0 36 0 0 0] 34 3 3664 3296 704 1232 nil 27 1250 2512 1 2128 1 1328 1 3056 73 410 ##(Smalltalk.ReferenceView) 34 14 nil 416 34 2 8 1140916224 131073 4240 nil 655878 ##(Smalltalk.ThemeColor) #smalltalkWorkspace nil 7 nil nil nil 4240 1180230 1 ##(Smalltalk.ResourceIdentifier) ##(Smalltalk.MethodWorkspace) #resource_Default_view nil 946 138 144 34 1 1010 #createAt:extent: 34 2 498 1 73 498 1229 411 4240 1170 8 #[44 0 0 0 0 0 0 0 1 0 0 0 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 0 0 0 0 36 0 0 0 102 2 0 0 241 0 0 0] 4048 1232 nil 27 1250 2512 1 2128 1 1282 #fixedPreviousBottom 1 1344 1 170 192 34 2 4240 8 'source' 590342 ##(Smalltalk.Rectangle) 498 1 1 498 1 1 461638 4 ##(Smalltalk.MenuBar) nil true 34 4 265030 4 ##(Smalltalk.Menu) nil true 34 5 984134 2 ##(Smalltalk.CommandMenuItem) 1 898 #pageSetup 8 'Page &setup...' 1 1 nil nil nil 4754 1 898 #printPreview 8 'Print p&review...' 1 1 nil nil nil 4754 1 898 #print 8 '&Print...' 1 1 nil nil nil 983366 1 ##(Smalltalk.DividerMenuItem) 4097 4754 1 898 #exit 8 '&Close' 16615 1 nil nil nil 8 '&File' nil 1 nil nil 14291 nil nil 4706 nil true 34 3 4754 1 898 #copySelection 8 '&Copy' 1 1 nil nil nil 4754 1 898 #restoreMethod 8 '&Restore' 9381 1 nil nil nil 4754 1 898 #diff 8 '&Diff' 9353 1 nil nil nil 8 '&Edit' nil 1 nil nil 14299 nil nil 4706 nil true 34 4 4754 1 898 #moveToFirst 8 '&First' 1605 1 nil nil nil 4754 1 898 #moveToPrevious 8 '&Previous' 1611 1 nil nil nil 4754 1 898 #moveToNext 8 '&Next' 1615 1 nil nil nil 4754 1 898 #moveToLast 8 '&Last' 1603 1 nil nil nil 8 '&Position' nil 134217729 nil nil 14309 nil nil 4754 1 898 #about 8 '&About!!' 1 1 nil nil nil 8 '' nil 1 nil nil nil nil nil nil nil nil 1 nil nil nil nil 1 nil nil 946 138 144 34 3 1010 #createAt:extent: 34 2 498 3839 21 498 1261 601 416 1010 #text: 34 1 8 'Method History' 416 1010 #updateMenuBar 4048 416 1170 8 #[44 0 0 0 0 0 0 0 0 0 0 0 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 127 7 0 0 10 0 0 0 245 9 0 0 54 1 0 0] 34 2 592 4240 1232 nil 27 )!

showOnClass: aClass selector: aSymbol
	^self
		showOnClass: aClass
		selector: aSymbol
		debugger: nil!

showOnClass: aClass selector: aSymbol debugger: aDebuggerOrNil
	^self show
		setClass: aClass
		selector: aSymbol
		debugger: aDebuggerOrNil! !
!MethodHistoryBrowser class categoriesFor: #resource_Default_view!public!resources-views! !
!MethodHistoryBrowser class categoriesFor: #showOnClass:selector:!instance creation!public! !
!MethodHistoryBrowser class categoriesFor: #showOnClass:selector:debugger:!instance creation!private! !

