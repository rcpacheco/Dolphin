"Filed out from Dolphin Smalltalk X6.1"!

Presenter subclass: #PackageDependencyPresenter
	instanceVariableNames: 'treePresenter tracesPresenter traces packages'
	classVariableNames: ''
	poolDictionaries: ''
	classInstanceVariableNames: ''!
PackageDependencyPresenter guid: (GUID fromString: '{183E540C-F682-44D4-AC9C-77D4E4CA9487}')!
PackageDependencyPresenter comment: 'PackageDependencyPresenter is the abstract superclass of the development tool windows which display a tree representing the dependency relationships between packages. Subclasses show emphasise either the pre-requisite relationship (where the children of a package in the tree are the pre-requisistes for that package) or dependency relationship (where the children of a package in the tree are the packages dependent upon it, i.e. of which it is itself a pre-requisite).

Instance Variables:
	prerequisitesPresenter	<TreePresenter> holding the dependency tree.
	tracesPresenter			<ListPresenter> holding the list of traces.
	traces					<IdentityDictionary> of traces generated by Package>>tracePrerequisites.
	packages				<Package>s at the root of the tree for which dependency relationships are being displayed.
'!
!PackageDependencyPresenter categoriesForClass!MVP-Presenters!MVP-Resources-IDE Tools! !
!PackageDependencyPresenter methodsFor!

browsePackages
	"Browse the currently selected prerequisite package."

	self selectedPair ifNotNil: [:selected | selected key browse]!

browseTrace
	"Browse the currently selected trace object."

	| trace |
	trace := tracesPresenter selections.
	trace notEmpty ifTrue: [
		trace first first browse]!

buildChildNodes: aCollection for: aTreeNode 
	^(aCollection asSortedCollection: Package defaultSortBlock) collect: [:p | p -> aTreeNode]!

childrenFor: aTreeNode 
	"Private - Answer a <sequencedReadableCollection> of the child nodes below the package
	dependency tree node argument."

	^self subclassResponsibility!

choosePackage
	"Prompt for the user to repackage the selected objects."

	| pkg newPkg dependees |
	dependees := IdentitySet new.
	tracesPresenter selections do: [:t | dependees add: t first].
	"Default to moving the selected objects to the pre-requisite package"
	pkg := self prerequisitePackage.
	pkg == Package uncommitted ifTrue: [pkg := nil].
	newPkg := PackagePrompter 
				showModalOn: pkg asValue
				caption: 'Re-package dependencies...'
				default: nil.
	newPkg isNil ifFalse: [self queryMoveObjects: dependees toPackage: newPkg]!

clear
	"Clear down the receiver"

	self packages: #()!

createComponents
	"Create the presenters contained by the receiver"

	super createComponents.
	treePresenter := self add: TreePresenter new name: 'tree'.
	tracesPresenter := self add: ListPresenter new name: 'traces'!

createSchematicWiring
	"Create the trigger wiring for the receiver"

	super createSchematicWiring.
	treePresenter
		when: #selectionChanged
			send: #onPackageSelected
			to: self;
		when: #actionPerformed
			send: #browsePackages
			to: self.
	tracesPresenter 
		when: #actionPerformed
		send: #browseTrace
		to: self.
	self packageManager 
		when: #prerequisitesReset:
		send: #onPrerequisitesReset:
		to: self!

dependencyModelWithRoots: anOrderedCollection 
	^(ExpandingTreeModel withRoots: anOrderedCollection)
		getChildrenBlock: [:each | self childrenFor: each];
		yourself!

dependentPackage
	^self subclassResponsibility!

initialize
	super initialize.
	packages := #()!

onPackageSelected
	"Private - One of the packages in the dependency tree has been selected. Populate the
	traces presenter with a list of all of the dependency relationships between the selected
	package and its parent in the tree."

	| pair |
	pair := self selectedPair.
	(pair notNil and: [pair value notNil]) 
		ifTrue: 
			[tracesPresenter 
				list: ((self prerequisiteTraceFor: self dependentPackage) at: self prerequisitePackage
						ifAbsent: [#()])]
		ifFalse: [tracesPresenter clear]!

onPrerequisitesReset
	"Private - The pre-requisites of a package have been reset, so the dependency tree must be
	rebuilt."

	"Implementation Note: In order to avoid having to immediately calculate the pre-requisites
	of all the pre-requisites of a package when the tree view asks if the root nodes have any
	children, we put the starting package in as the single root. This is also more consistent
	from a usability point of view, since when selected the pre-requisites list shows the
	dependencies on the parent node. It does mean we need to treat selection of the root as a
	special case however."

	| selected |
	selected := self selectedPair.
	traces := LookupTable new.
	treePresenter
		selectionOrNil: nil;
		model: (self dependencyModelWithRoots: (packages collect: [:each | each -> nil])).
	self selectedPair: selected!

onPrerequisitesReset: updatee
	"Private - The <Package>, updatee, has reset its prerequisites, so we need to rebuild the
	dependency tree to reflect any changes. We could do this more efficiently by locating the
	relevant nodes and collapsing only those, but at present we opt for the simple approach of
	collapsing the entire tree."

	self onPrerequisitesReset!

onViewClosed
	"Sent by the receiver's view when it has been closed.
	Disconnect from any events triggered by the devlopment system"

	super onViewClosed.
	self packageManager removeEventsTriggeredFor: self!

onViewOpened
	"Received when the receiver's view has been connected. "

	super onViewOpened.
	self packageManager youShouldBeProcessingEvents!

packageManager
	"Private - Answer the current PackageManager."

	^Package manager

!

packages
	"Answer the packages for which the receiver is showing dependency trees."

	^packages!

packages: aPackageCollection 
	"Set the packages which the constitute the roots of the dependency tree."

	packages := aPackageCollection.
	self onPrerequisitesReset!

prerequisitePackage
	^self subclassResponsibility!

prerequisiteTraceFor: aPackage
	"Private - Answer the pre-requisite trace for the specified package.
	We cache the info. for speed."

	^traces at: aPackage ifAbsentPut: [Cursor wait showWhile: [aPackage tracePrerequisites]]!

queryCommand: aCommandQuery 
	"Private - Enter details about a potential command for the receiver 
	into the <CommandQuery> argument."

	| selector |
	selector := aCommandQuery commandSymbol.
	#toggleStatusIcons == selector 
		ifTrue: 
			[aCommandQuery
				isEnabled: true;
				isChecked: treePresenter view viewMode == #smallIcons.
			^true].
	#browseTrace == selector 
		ifTrue: 
			[aCommandQuery isEnabled: tracesPresenter selectionOrNil size = 1.
			^true].
	#browsePackages == selector 
		ifTrue: 
			[aCommandQuery isEnabled: treePresenter hasSelection.
			^true].
	#choosePackage == selector 
		ifTrue: 
			[aCommandQuery isEnabled: tracesPresenter hasSelection.
			^true].
	^super queryCommand: aCommandQuery!

queryMoveObjects: aCollection toPackage: aPackage 
	"Private - Move the array of packageable objects, anArray, to the specified package."

	| stream max sorted |
	stream := String writeStream.
	stream nextPutAll: 'Are you sure you would like to move '.
	aCollection size = 1 
		ifTrue: [stream nextPutAll: 'the following object']
		ifFalse: 
			[stream
				nextPutAll: 'these ';
				display: aCollection size;
				nextPutAll: ' objects'].
	stream
		nextPutAll: ' to the package ';
		print: aPackage name;
		nextPut: $?;
		cr.
	sorted := aCollection asSortedCollection: [:a :b | a displayString <= b displayString].
	max := 30.
	sorted 
		from: 1
		to: (aCollection size min: max)
		do: 
			[:each | 
			stream
				crtab;
				display: each].
	aCollection size > max 
		ifTrue: 
			[stream
				crtab;
				nextPutAll: '... and ';
				print: aCollection size - max;
				nextPutAll: ' other items ...'].
	stream
		cr;
		cr;
		nextPutAll: 'Press Yes to repackage the object(s), or No to abort the operation'.
	(MessageBox confirm: stream contents) ifFalse: [^self].
	aCollection do: [:each | each owningPackage: aPackage]!

selectedPair
	"Answer the currently selected depedendency node."

	^treePresenter selectionOrNil!

selectedPair: anAssociation 
	"Set the currently selected prerequisite package."

	anAssociation notNil 
		ifTrue: [treePresenter selection: anAssociation ifAbsent: []]
		ifFalse: [treePresenter resetSelection]!

toggleStatusIcons
	treePresenter view 
		viewMode: (treePresenter view viewMode == #noIcons ifTrue: [#smallIcons] ifFalse: [#noIcons])! !
!PackageDependencyPresenter categoriesFor: #browsePackages!commands!public! !
!PackageDependencyPresenter categoriesFor: #browseTrace!commands!public! !
!PackageDependencyPresenter categoriesFor: #buildChildNodes:for:!helpers!private! !
!PackageDependencyPresenter categoriesFor: #childrenFor:!helpers!private! !
!PackageDependencyPresenter categoriesFor: #choosePackage!helpers!private! !
!PackageDependencyPresenter categoriesFor: #clear!commands!public! !
!PackageDependencyPresenter categoriesFor: #createComponents!initializing!public! !
!PackageDependencyPresenter categoriesFor: #createSchematicWiring!initializing!public! !
!PackageDependencyPresenter categoriesFor: #dependencyModelWithRoots:!helpers!private! !
!PackageDependencyPresenter categoriesFor: #dependentPackage!accessing!private! !
!PackageDependencyPresenter categoriesFor: #initialize!initializing!private! !
!PackageDependencyPresenter categoriesFor: #onPackageSelected!event handling!private! !
!PackageDependencyPresenter categoriesFor: #onPrerequisitesReset!event handling!private! !
!PackageDependencyPresenter categoriesFor: #onPrerequisitesReset:!event handling!private! !
!PackageDependencyPresenter categoriesFor: #onViewClosed!event handling!public! !
!PackageDependencyPresenter categoriesFor: #onViewOpened!event handling!public! !
!PackageDependencyPresenter categoriesFor: #packageManager!constants!private! !
!PackageDependencyPresenter categoriesFor: #packages!accessing!public! !
!PackageDependencyPresenter categoriesFor: #packages:!accessing!public! !
!PackageDependencyPresenter categoriesFor: #prerequisitePackage!accessing!private! !
!PackageDependencyPresenter categoriesFor: #prerequisiteTraceFor:!event handling!private! !
!PackageDependencyPresenter categoriesFor: #queryCommand:!commands!private! !
!PackageDependencyPresenter categoriesFor: #queryMoveObjects:toPackage:!helpers!private! !
!PackageDependencyPresenter categoriesFor: #selectedPair!accessing!public! !
!PackageDependencyPresenter categoriesFor: #selectedPair:!accessing!public! !
!PackageDependencyPresenter categoriesFor: #toggleStatusIcons!commands!public! !

!PackageDependencyPresenter class methodsFor!

icon
	"Answers an Icon that can be used to represent this class"

	^Package icon!

resource_Default_view
	"Answer the literal data from which the 'Default view' resource can be reconstituted.
	DO NOT EDIT OR RECATEGORIZE THIS METHOD.

	If you wish to modify this resource evaluate:
	ViewComposer openOn: (ResourceIdentifier class: self selector: #resource_Default_view)
	"

	^#(#'!!STL' 3 788558 10 ##(Smalltalk.STBViewProxy)  8 ##(Smalltalk.ContainerView)  98 15 0 0 98 2 8 1409482752 131073 416 0 524550 ##(Smalltalk.ColorRef)  8 4278190080 0 517 0 0 0 416 1180166 ##(Smalltalk.ProportionalLayout)  202 8 ##(Smalltalk.Dictionary)  98 3 721414 ##(Smalltalk.Association)  410 8 ##(Smalltalk.ListView)  98 30 0 416 98 2 8 1140920393 1 656 590662 2 ##(Smalltalk.ListModel)  202 208 98 0 0 1310726 ##(Smalltalk.IdentitySearchPolicy)  498 528 0 5 265030 4 ##(Smalltalk.Menu)  0 16 98 2 984134 2 ##(Smalltalk.CommandMenuItem)  1 1180998 4 ##(Smalltalk.CommandDescription)  8 #browseTrace 8 'Browse' 1 1 0 0 0 898 1 930 8 #choosePackage 8 'Package...' 1 1 0 0 0 8 '' 0 1 0 0 0 0 0 0 0 656 0 8 4294902005 8 ##(Smalltalk.BasicListAbstract)  0 1049670 1 ##(Smalltalk.IconImageManager)  0 0 0 328198 ##(Smalltalk.Point)  65 65 0 0 202 208 98 3 920646 5 ##(Smalltalk.ListViewColumn)  8 'Owned' 507 8 #left 1088 787814 3 ##(Smalltalk.BlockClosure)  0 0 1180966 ##(Smalltalk.CompiledExpression)  2 1 8 ##(Smalltalk.UndefinedObject)  8 'doIt' 8 '[:a :b | a displayString < b displayString]' 8 #[30 105 17 158 18 158 128 106] 8 #displayString 1280 7 513 0 459270 ##(Smalltalk.Message)  8 #first 98 0 0 656 8 ##(Smalltalk.IconicListAbstract)  3 0 0 1202 8 'Dependency' 337 1248 1088 8 ##(Smalltalk.SortedCollection)  1410 8 #last 1456 0 656 0 1 0 0 1202 8 'Prerequisite Object' 339 1248 1088 1266 0 0 1298 2 1 1328 8 'doIt' 8 '[:a :b | a displayString < b displayString]' 8 #[30 105 17 158 18 158 128 106] 1392 1600 7 513 0 1266 0 0 1298 1 83886081 1328 8 'doIt' 8 '[:a | a at: 2]' 8 #[29 105 17 64 148 106] 1680 7 257 0 0 656 1472 1 0 0 8 #report 784 0 131173 0 0 983302 ##(Smalltalk.MessageSequence)  202 208 98 3 721670 ##(Smalltalk.MessageSend)  8 #createAt:extent: 98 2 1138 1 171 1138 1189 285 656 1842 8 #contextMenu: 98 1 864 656 1842 8 #text: 98 1 8 'Owned' 656 983302 ##(Smalltalk.WINDOWPLACEMENT)  8 #[44 0 0 0 0 0 0 0 1 0 0 0 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 0 0 0 0 85 0 0 0 82 2 0 0 227 0 0 0] 98 0 1138 193 193 0 27 524806 ##(Smalltalk.Fraction)  24567 10361 626 410 8 ##(Smalltalk.TreeView)  98 27 0 416 98 2 8 1140916775 1 2176 590918 3 ##(Smalltalk.TreeModel)  0 816 525062 ##(Smalltalk.TreeNode)  0 0 0 234 256 784 498 528 0 5 850 0 16 98 2 898 1 930 8 #browsePackages 8 'Browse' 1 1 0 0 0 898 1 930 8 #toggleStatusIcons 8 'Show Status Icons' 1 1 0 0 0 8 '' 0 1 0 0 0 0 0 0 0 2176 0 8 4294902269 1266 0 0 1298 3 1 1328 8 'doIt' 8 '[:a | a key name]' 8 #[31 105 17 158 159 106] 8 #key 8 #name 2544 7 257 0 1266 0 0 1298 7 1 1264 8 'doIt' 8 '[:each |  (each key hasCyclicPrerequisites or: [each key hasUncommittedPrerequisites]) not icon 
	imageIndex]' 8 #[35 105 226 0 159 119 58 112 226 0 160 161 162 163 106] 2624 8 #hasCyclicPrerequisites 8 #hasUncommittedPrerequisites 8 #not 8 #icon 8 #imageIndex 2656 7 257 0 1120 0 0 0 0 0 234 240 784 17 8 #noIcons 11 0 1778 202 208 98 2 1842 1872 98 2 1138 1 1 1138 1189 161 2176 1842 1952 98 1 2352 2176 2050 8 #[44 0 0 0 0 0 0 0 1 0 0 0 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 0 0 0 0 0 0 0 0 82 2 0 0 80 0 0 0] 98 0 2112 0 27 2130 693 519 626 410 8 ##(Smalltalk.Splitter)  98 12 0 416 98 2 8 1140850688 1 3072 0 498 528 0 517 0 0 0 3072 1778 202 208 98 1 1842 1872 98 2 1138 1 161 1138 1189 11 3072 2050 8 #[44 0 0 0 0 0 0 0 1 0 0 0 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 0 0 0 0 80 0 0 0 82 2 0 0 85 0 0 0] 98 0 2112 0 27 1 16 234 256 98 4 2176 8 'tree' 656 8 'traces' 590342 ##(Smalltalk.Rectangle)  1138 1 1 1138 1 1 1778 202 208 98 1 1842 1872 98 2 1138 3837 21 1138 1189 455 416 2050 8 #[44 0 0 0 0 0 0 0 1 0 0 0 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 126 7 0 0 10 0 0 0 208 9 0 0 237 0 0 0] 98 3 2176 3072 656 2112 0 27 )! !
!PackageDependencyPresenter class categoriesFor: #icon!constants!public! !
!PackageDependencyPresenter class categoriesFor: #resource_Default_view!public!resources-views! !
