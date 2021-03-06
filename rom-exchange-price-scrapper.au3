#cs ----------------------------------------------------------------------------

 AutoIt Version: 3.3.14.2
 Author: mandrx

 Script Function:
	Ragnarok Online Mobile: Eternal Love Exchange Price Scrapper.

#ce ----------------------------------------------------------------------------

#RequireAdmin
#RequireAdmin
#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=icon.ico
#AutoIt3Wrapper_Outfile=Rom Price Scrapper-1.2.exe
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****

AutoItSetOption("MouseClickDelay", 50) ;
AutoItSetOption("MouseClickDownDelay", 80) ;
AutoItSetOption("MouseClickDragDelay", 100)
AutoItSetOption("MouseCoordMode", 2)

#include <Array.au3>
#include <File.au3>

#include <GUIConstants.au3>
#include <GUIConstantsEx.au3>

#include <ScreenCapture.au3>

#include <library/NomadMemory.au3>
#include <library/Json.au3>
#include <library/ImageSearch.au3>
#include <library/FastFind.au3>

#include <Date.au3>


HotKeySet("^0", exitApp)
HotKeySet("^1", findCategory)
HotKeySet("^2", changeCategory)
HotKeySet("^4", stopAddressScanning)
HotKeySet("^5", scrollItemList)
HotKeySet("^6", savePricelist)
HotKeySet("^7", getItemInfo)
HotKeySet("^8", scanCurrentList)
HotKeySet("^9", reloadINI)

Local $appName = "ROM Exchange Price Scrapper v1.2"

print("=================================================")
print(">> START AT " & _Now())
print("=================================================")

; First load ini
reloadINI()

Func reloadINI()
	Global $listDragPointCoor[2] = [getConf("listDragPointCoor_x"), getConf("listDragPointCoor_y")]
	Global $listDragDistance = getConf("listDragDistance")
	Global $scrollDragSpeed = getConf("scrollDragSpeed")
	Global $mouseMoveDelay = getConf("mouseMoveDelay")

	Global $backButtonCoor[2] = [getConf("backButtonCoor_x"), getConf("backButtonCoor_y")]

	Global $listAreaStartCoor[2] = [getConf("listAreaStartCoor_x"), getConf("listAreaStartCoor_y")]

	Global $itemListWidth = getConf("itemListWidth")
	Global $itemListHeight = getConf("itemListHeight")


	Global $selectedItemID_address = getConf("itemIdAddress")
	Global $selectedItemPrice_address = getConf("itemPriceAddress")

	Global $scanCacheSize = getConf("scanCacheSize")
	Global $scanStartAddress = getConf("scanStartAddress")
	Global $scanStopAddress = getConf("scanStopAddress")


	Global $appClientMemoryName = getConf("emulatorMemoryProcess")
	Global $appClientWindowName = getConf("emulatorWindowProcess")

	Global $itemListImageTolerence = getConf("itemListImageTolerence")
	Global $categoryImageTolerence = getConf("categoryImageTolerence")
	Global $itemListDuplicateImageTolerence = getConf("itemListDuplicateImageTolerence")

	Global $categorylistAreaStartCoor[2] = [getConf("categorylistAreaStartCoor_x"), getConf("categorylistAreaStartCoor_y")]

	Global $categoryListWidth = getConf("categoryListWidth")
	Global $categoryListHeight = getConf("categoryListHeight")

	Global $itemScan1_Name = getConf("itemScan1_Name")
	Global $itemScan2_Name = getConf("itemScan2_Name")
	Global $itemScan3_Name = getConf("itemScan3_Name")

	Global $itemScan1_Id = Int(getConf("itemScan1_Id"))
	Global $itemScan2_Id = Int(getConf("itemScan2_Id"))
	Global $itemScan3_Id = Int(getConf("itemScan3_Id"))

	Global $itemScan1_Price = Int(getConf("itemScan1_Price"))
	Global $itemScan2_Price = Int(getConf("itemScan2_Price"))
	Global $itemScan3_Price = Int(getConf("itemScan3_Price"))

	Global $outputPricelistJson = getConf("outputPricelistJson")

	Global $debugMode = False
	If getConf("debugMode") == 1 Then
		$debugMode = True
	EndIf

	print("> Ini reloaded!")
EndFunc   ;==>reloadINI


; Init Process data
Local $processList = ProcessList($appClientMemoryName)
$latestPID = $processList[$processList[0][0]][1] ;

If Not (IsNumber($latestPID)) Then
	MsgBox(16, "Error!", $appClientMemoryName & " cannot be found! Make sure you open your emulator before continue.")
	Exit
EndIf

Local $hMemory = _MemoryOpen($latestPID) ; Open the memory

; Init Window data
Local $window_processList = ProcessList($appClientWindowName)
$hWndPID = $window_processList[$window_processList[0][0]][1] ;

If Not (IsNumber($hWndPID)) Then
	MsgBox(16, "Error!", $appClientWindowName & " cannot be found! Make sure you open your emulator before continue.")
	Exit
EndIf

Local $hWnd = _GetHwndFromPID($hWndPID)

WinMove($hWnd, "", 0, 0, 1280, 720)

WinActivate($hWnd)
Local $winpos = WinGetPos($hWnd)
$winsize = WinGetClientSize($hWnd)




Global $tmpdirPath = "_tmpdir"
Global $pricelistJsonObj = Json_ObjCreate()
Global $addressScanning = False
Global $lastItemID = 0
Global $scanning = False
Global $scanPriceAddressList[0]
Global $scanIdAddressList[0]
Global $updateInterval = 0
Global $pause = False
Global $lastListEndChecksum = 0
Global $categoryIndex = 0
Global $subCategoryIndex = 0
Global $clickSpotChecksumList[0]
Global $clickSpotCount = 0
Dim $categoryList[9] = ["item9", "item8", "item7", "item6", "item5", "item4", "item3", "item2", "item1"]

; Main GUI
$guiHeight = 440
$guiWidth = 300
$hGUI = GUICreate($appName, $guiWidth, $guiHeight, (@DesktopWidth - $guiWidth - 10), 10, BitOR($WS_CAPTION, $WS_POPUP, $WS_SYSMENU))
$itemPrice_grp = GUICtrlCreateGroup("Selected Item Price", 10, 10, $guiWidth - 20, 120)
$itemPrice_txt = GUICtrlCreateInput("0", 20, 30, $guiWidth - 40, 40, BitOR($ES_CENTER, $WS_DISABLED))
GUICtrlSetFont(-1, 24)
$start_btn = GUICtrlCreateButton("Start Collecting", 20, 80, 140, 32)
$pricecount_txt = GUICtrlCreateLabel("", 170, 90, 120, 26)
GUICtrlCreateGroup("", -99, -99, 1, 1) ;close group

$hTab = GUICtrlCreateTab(10, 140, 280, 290)
Local $i = 1
GUICtrlCreateTabItem("Memory Address")


Global $step0[2], $step1[5], $step2[5], $step3[5]

$step0[0] = GUICtrlCreateLabel("If the shown price is incorrect, press 'Update Address' and follow the instructions to update the memory address.", 30, 200, 240, 100)
GUICtrlSetFont(-1, 12)
GUICtrlSetColor(-1, 0xff5e00)
$step0[1] = GUICtrlCreateButton("Update Address", 45, 300, 200, 40)
GUICtrlSetFont(-1, 12)

Local $step1_btnlabel = "Start Scanning >"
$step1[0] = GUICtrlCreateLabel("1. Open Exchange, go to '" & $itemScan1_Name & "' listing to see the price, and press '" & $step1_btnlabel & "'...", 30, 170, 240, 100)
GUICtrlSetFont(-1, 11)
GUICtrlSetColor(-1, 0x0659d6)
$step1[2] = GUICtrlCreatePic("res/step1.jpg", 30, 220, 242, 132)

$step1[1] = GUICtrlCreateButton($step1_btnlabel, 31, 360, 150, 36)
$step1[3] = GUICtrlCreateButton("Cancel", 190, 360, 80, 36)
$step1[4] = GUICtrlCreateProgress(31, 400, 240, 20)
GUICtrlSetState(-1, $GUI_HIDE)



$step2[0] = GUICtrlCreateLabel("2. Go to '" & $itemScan2_Name & "' listing, and press 'Next Step'...", 30, 175, 240, 100)
GUICtrlSetFont(-1, 11)
GUICtrlSetColor(-1, 0x0659d6)
$step2[2] = GUICtrlCreatePic("res/step2.jpg", 30, 220, 242, 132)

$step2[1] = GUICtrlCreateButton("Next Step >", 31, 360, 150, 36)
$step2[3] = GUICtrlCreateButton("Cancel", 190, 360, 80, 36)
$step2[4] = GUICtrlCreateProgress(31, 400, 240, 20)
GUICtrlSetState(-1, $GUI_HIDE)

$step3[0] = GUICtrlCreateLabel("3. Next, go to '" & $itemScan3_Name & "' listing, and press 'Next Step'...", 30, 175, 240, 100)
GUICtrlSetFont(-1, 11)
GUICtrlSetColor(-1, 0x0659d6)

$step3[2] = GUICtrlCreatePic("res/step3.jpg", 30, 220, 242, 132)
$step3[1] = GUICtrlCreateButton("Next Step >", 31, 360, 150, 36)
$step3[3] = GUICtrlCreateButton("Cancel", 190, 360, 80, 36)
$step3[4] = GUICtrlCreateProgress(31, 400, 240, 20)
GUICtrlSetState(-1, $GUI_HIDE)

$i = 2
GUICtrlCreateTabItem("Hotkeys")
GUICtrlCreateLabel("Stop Address Scanning" & _
		@CRLF & "Print Pricelise JSON" & _
		@CRLF & "Reload Config.ini" & _
		@CRLF & "Force Close", 30, 180, 140, 240)
GUICtrlSetColor(-1, 0x0c39e0)
;GUICtrlSetBkColor(-1,0xDDDDDD)

GUICtrlCreateLabel("CTRL + 4" & _
		@CRLF & "CTRL + 6" & _
		@CRLF & "CTRL + 9" & _
		@CRLF & "CTRL + 0", 200, 180, 80, 240, $ES_CENTER)
GUICtrlSetColor(-1, 0x0c7711)
;GUICtrlSetBkColor(-1,0xDDDDDD)
;@CRLF & "CTRL + 0" & _
;@CRLF & "CTRL + 0" & _


GUISetState(@SW_SHOW)


;================
; Starts here
;================

If Not (FileExists($tmpdirPath)) Then
	DirCreate($tmpdirPath)
	FileSetAttrib($tmpdirPath, "+H")
EndIf

clearScanCache()
showStep0()

While 1
	getGuiMsg()
	updateGuiView()
	Sleep(10)
WEnd

Func getGuiMsg()
	Switch GUIGetMsg()
		Case $GUI_EVENT_CLOSE, $idOK
			exitApp()
		Case $start_btn
			startScan()

		Case $step0[1]
			doStep1()

		Case $step1[1]
			doStep2()

		Case $step2[1]
			doStep3()

		Case $step3[1]
			doStepFinal()

		Case $step1[3], $step2[3], $step3[3]
			doCancelUpdate()

	EndSwitch
EndFunc   ;==>getGuiMsg


;==============================
;	GUI RELATED FUNCTIONS
;==============================

Func hideAllUpdateSteps()

	For $i = 0 To UBound($step0) - 1
		GUICtrlSetState($step0[$i], $GUI_HIDE)
	Next

	For $i = 0 To UBound($step1) - 1
		GUICtrlSetState($step1[$i], $GUI_HIDE)
	Next

	For $i = 0 To UBound($step2) - 1
		GUICtrlSetState($step2[$i], $GUI_HIDE)
	Next

	For $i = 0 To UBound($step3) - 1
		GUICtrlSetState($step3[$i], $GUI_HIDE)
	Next

EndFunc   ;==>hideAllUpdateSteps


Func showStep0()
	hideAllUpdateSteps()
	stopAddressScanning()

	For $i = 0 To UBound($step0) - 1
		GUICtrlSetState($step0[$i], $GUI_SHOW)
	Next
EndFunc   ;==>showStep0

Func doStep1()
	hideAllUpdateSteps()

	For $i = 0 To UBound($step1) - 1
		GUICtrlSetState($step1[$i], $GUI_SHOW)
	Next
	GUICtrlSetState($step1[4], $GUI_HIDE)


EndFunc   ;==>doStep1

Func doStep2()

	clearScanCache()

	GUICtrlSetState($step1[1], $GUI_DISABLE)
	GUICtrlSetData($step1[1], "CTRL+4 to stop...")
	GUICtrlSetState($step1[4], $GUI_SHOW)
	GUICtrlSetData($step1[4], 0)

	Local $scan_result = _MemoryScan($hMemory, $itemScan1_Price, $scanStartAddress, $scanStopAddress, $scanCacheSize)

	GUICtrlSetState($step1[1], $GUI_ENABLE)
	GUICtrlSetData($step1[1], $step1_btnlabel)


	If $scan_result == -3 Then

		scanResToArray()

		hideAllUpdateSteps()

		For $i = 0 To UBound($step2) - 1
			GUICtrlSetState($step2[$i], $GUI_SHOW)
		Next
		GUICtrlSetState($step2[4], $GUI_HIDE)

		stopAddressScanning()

	Else
		If $scan_result <> -4 Then
			MsgBox(48, "Fail!", "Error code " & $scan_result)
		EndIf
		showStep0()
	EndIf


EndFunc   ;==>doStep2

Func doStep3()

	GUICtrlSetState($step2[1], $GUI_DISABLE)

	If (MsgBox(BitOR(1, 64, 262144), "Reminder", "Please confirm that you are in '" & $itemScan2_Name & "' listing page and its current price is " & $itemScan2_Price & "z.")) Then
	Else
		Return
	EndIf
	GUICtrlSetState($step2[1], $GUI_ENABLE)

	; Compare item price with previous value, if it changes to current price, that's the address that we are looking for!
	comparePreviousValue($itemScan2_Price)

	; Start listing potential itemID
	findPotentialItemID()

	hideAllUpdateSteps()

	For $i = 0 To UBound($step3) - 1
		GUICtrlSetState($step3[$i], $GUI_SHOW)
	Next
	GUICtrlSetState($step3[4], $GUI_HIDE)

EndFunc   ;==>doStep3

Func doStepFinal()

	GUICtrlSetState($step3[1], $GUI_DISABLE)

	If (MsgBox(BitOR(1, 64, 262144), "Reminder", "Please confirm that you are in '" & $itemScan3_Name & "' listing page and its current price is " & $itemScan3_Price & "z.")) Then
	Else
		Return
	EndIf
	GUICtrlSetState($step3[1], $GUI_ENABLE)

	; Check item price address once more, just to be sure...
	comparePreviousValue($itemScan3_Price)

	; Filter itemid address list
	filterPotentialItemID()

	If (UBound($scanPriceAddressList) > 0) And UBound($scanIdAddressList) > 0 Then
		MsgBox(BitOR(64, 262144), "Success!", "Needed address has been saved.")

		$selectedItemID_address = "0x" & Hex($scanIdAddressList[0], 8)
		$selectedItemPrice_address = "0x" & Hex($scanPriceAddressList[0], 8)

		setConf("itemIdAddress", $selectedItemID_address)
		setConf("itemPriceAddress", $selectedItemPrice_address)

		;$selectedItemID_address = getConf("itemIdAddress")
		;$selectedItemPrice_address = getConf("itemPriceAddress")
	Else
		MsgBox(BitOR(48, 262144), "Oops!", "Address cannot be found. Did you follow the instruction carefully? Also, make sure your Root access for your emulator is enabled. Restart the game + this tool also helps.")
	EndIf

	showStep0()

EndFunc   ;==>doStepFinal


Func doCancelUpdate()
	print("> Memory Address Update Wizard Cancelled...")

	stopAddressScanning()
	showStep0()
EndFunc   ;==>doCancelUpdate


Func scanResToArray()

	Local $addCount = 0
	$scanResList = _FileListToArray($tmpdirPath, "*.scanres", 1)
	If UBound($scanResList) <> 0 Then

		For $i = 1 To $scanResList[0]
			$fileName = $scanResList[$i] ;
			$baseAddress = StringSplit($fileName, ".")[1]
			$addList = FileReadToArray($tmpdirPath & "\" & $fileName)
			For $line = 0 To UBound($addList) - 1
				$addOffset = StringSplit($addList[$line], ",")[1]

				$endAdd = Dec($baseAddress) + Int($addOffset) ;

				; Clean non-divided by 4 aligned address
				$endAddress = Hex($endAdd, 8)

				If (alignedBy4($endAdd)) Then
					addToPriceAddressList($endAdd)
					print("+ " & $endAddress)
				Else
					print("- " & $endAddress)
				EndIf

				$addCount += 1
			Next
		Next

	Else
		MsgBox(BitOR(16, 262144), "Oops!", "No address is found.")
		; Reset wizard
	EndIf

EndFunc   ;==>scanResToArray

Func comparePreviousValue($itemPrice)

	$startingListCount = (UBound($scanPriceAddressList) - 1)


	For $i = $startingListCount To 0 Step -1
		$address = $scanPriceAddressList[$i]
		$addressValue = _MemoryRead($address, $hMemory, 'dword')
		print("> No. " & $i & ": Current value for " & Hex($address, 8) & " = " & $addressValue)

		If ($addressValue <> $itemPrice) Then
			;print("- Price is not equal to " & $itemScan2_Price & "z. Wrong address.")
			_ArrayDelete($scanPriceAddressList, $i)
		Else
			ConsoleWrite(" <<-- Gotcha!")
		EndIf
	Next

EndFunc   ;==>comparePreviousValue


Func findPotentialItemID()

	; Find potential item id address based on item price address.
	; item id normally 0x40, 0x0A or 0x0C less or greater than item price address.
	; item id normally 0x40, 0x0A or 0x0C less or greater than item price address.
	; we find up to 0x140. just to be safe

	Global $scanIdAddressList[0]

	$startingItemPriceListCount = (UBound($scanPriceAddressList) - 1)


	For $i = $startingItemPriceListCount To 0 Step -1
		print("> Checking potential for " & Hex($scanPriceAddressList[$i], 8))
		For $i2 = 21 To -21 Step -1
			$potentialAddress = ($scanPriceAddressList[$i] + (16 * $i2))
			$potentialAddressValue = _MemoryRead($potentialAddress, $hMemory, 'dword')

			If ($potentialAddressValue == $itemScan2_Id) Then
				print("+ Yes!! " & Hex($potentialAddress, 8) & " = " & $potentialAddressValue)
				_ArrayAdd($scanIdAddressList, $potentialAddress)
			Else
				;print("- Nope! " & Hex($potentialAddress,8) & " = " & $potentialAddressValue )
			EndIf

		Next
	Next

EndFunc   ;==>findPotentialItemID

Func filterPotentialItemID()

	$startingItemIdListCount = (UBound($scanIdAddressList) - 1)

	For $i = $startingItemIdListCount To 0 Step -1
		print("> Filtering potential for " & Hex($scanIdAddressList[$i], 8))

		$potentialAddress = $scanIdAddressList[$i] ;
		$potentialAddressValue = _MemoryRead($potentialAddress, $hMemory, 'dword')

		If ($potentialAddressValue == $itemScan3_Id) Then
			ConsoleWrite(" <<--  OK!" & Hex($potentialAddress, 8) & " = " & $potentialAddressValue)
		Else
			ConsoleWrite(" <<-- Nope! " & Hex($potentialAddress, 8) & " = " & $potentialAddressValue)
			_ArrayDelete($scanIdAddressList, $i)
		EndIf

	Next

EndFunc   ;==>filterPotentialItemID

Func updateGuiView()

	If ($updateInterval > 30) Then
		$updateInterval = 0
		$itemPrice = _MemoryRead($selectedItemPrice_address, $hMemory, 'dword')
		GUICtrlSetData($itemPrice_txt, formatPrice($itemPrice) & "z")

		$itemID = _MemoryRead($selectedItemID_address, $hMemory, 'dword')
		GUICtrlSetData($itemPrice_grp, "Selected Item Price ( ID: " & $itemID & " )")

	EndIf

	$updateInterval += 1

EndFunc   ;==>updateGuiView



;===========================================
;	PRICE SCANNING RELATED FUNCTIONS
;===========================================

Func startScan()
	WinActivate($hWnd)
	Sleep(100)
	WinWait($hWnd)

	MouseClick("left", $listDragPointCoor[0], $listDragPointCoor[1]) ; Init click to focus

	; Show list area
	If $debugMode Then
		MouseMove($listAreaStartCoor[0], $listAreaStartCoor[1])
		Sleep(500)
		MouseMove($listAreaStartCoor[0] + ($itemListWidth * 2), $listAreaStartCoor[1] + ($itemListHeight * 4 + 40))
	EndIf


	$scanning = True

	$scanTimeStart = TimerInit()
	print("> Scanning Start at " & _NowTime() & @CRLF)

	While $scanning
		WinActivate($hWnd)
		scanCurrentList()
		scrollItemList()
	WEnd

	$scanTimeDiff = TimerDiff($scanTimeStart)
	print("> Scanning Ended at " & _NowTime())
	print("> Scanning took " & Floor($scanTimeDiff / 1000) & "s.")


EndFunc   ;==>startScan


Func pauseScan()

	$pause = Not ($pause)
	If $pause Then
		print("Pause Scanning...")
	Else
		print("Resume Scanning...")
	EndIf

EndFunc   ;==>pauseScan

Func scrollItemList()
	WinActivate($hWnd)

	MouseClick("left", $listDragPointCoor[0], $listDragPointCoor[1] - 50)
	Sleep(150)
	MouseWheel("down", 1)
	Sleep(150)
	MouseWheel("down", 1)
	Sleep(150)
	MouseWheel("down", 1)
	Sleep(1500)

	If checkEndList() Then
		;printPricelist()
		print("> scrollItemList Ended!")
		savePricelist()
		$scanning = False
	EndIf

	;MouseClickDrag("left",$listDragPointCoor[0],$listDragPointCoor[1],$listDragPointCoor[0],$listDragPointCoor[1]-$listDragDistance,$scrollDragSpeed)
EndFunc   ;==>scrollItemList

Func scanCurrentList()
	Local $x = 0

	While $x < 8
		If Not ($pause) Then
			scanEachListItem($x)
			$x += 1 ;
			Sleep(50)

			If Not ($scanning) Then
				ExitLoop
			EndIf
		EndIf
	WEnd
EndFunc   ;==>scanCurrentList

Func scanEachListItem($index)
	Dim $area[4]

	$column = Mod($index, 2) ;
	$row = Floor($index / 2)

	$offset_x = $column * $itemListWidth ;370
	$offset_y = $row * $itemListHeight ;96

	$list_point_x = $listAreaStartCoor[0] + $offset_x
	$list_point_y = $listAreaStartCoor[1] + $offset_y

	$area[0] = $list_point_x
	$area[1] = $list_point_y - 24

	$area[2] = $list_point_x + 30 ;+($itemListWidth+10)
	$area[3] = $list_point_y + ($itemListHeight + 40)

	If $debugMode Then
		MouseMove($area[0], $area[1])
		Sleep(500)
		MouseMove($area[2], $area[3])
	EndIf

	scanClickPoint($area)

EndFunc   ;==>scanEachListItem


Func scanClickPoint($rect)
	Dim $result[2]

	$borderFound = _ImageSearchArea("res/border_tl.bmp", 0, $rect[0], $rect[1], $rect[2], $rect[3], $result[0], $result[1], $itemListImageTolerence)

	If ($borderFound) Then
		Dim $pos[2] = [$result[0] + 100, $result[1] + 5]

		Local $dupeCount = checkDuplicateClick($pos[0], $pos[1])

		If $debugMode Then
			If $dupeCount == 0 Then
				MouseMove($pos[0], $pos[1], 20)
			EndIf
		Else
			; Scan before click
			If $dupeCount == 0 Then
				; No dupe
				;print("> Check dupe: " & $dupeCount)
				MouseClick("left", $pos[0], $pos[1], 1, $mouseMoveDelay)
				getItemInfo()
			EndIf

		EndIf

	EndIf

EndFunc   ;==>scanClickPoint

Func checkDuplicateClick($posX, $posY)
	$storeSampleCount = 6

	$tmpBmpPath = $tmpdirPath & "\" & $clickSpotCount & ".bmp"

	Local $dupeSampleRect[4] = [$posX, $posY + 5, $posX + 245, $posY + 50]
	Local $dupeCheckArea[4] = [$dupeSampleRect[0] - 3, $dupeSampleRect[1] - 5, $dupeSampleRect[2] + 3, $dupeSampleRect[3] + 5]

	_ScreenCapture_Capture($tmpBmpPath, $dupeSampleRect[0], $dupeSampleRect[1], $dupeSampleRect[2], $dupeSampleRect[3])


	Dim $result[2]
	Local $dupeCount = 0

	;print("> create sample: "&$tmpBmpPath)

	For $i = ($clickSpotCount - $storeSampleCount) To ($clickSpotCount - 1)
		$_eachBmp = $tmpdirPath & "\" & ($i) & ".bmp"

		If $i > -1 Then

			Local $foundDuplicate = _ImageSearchArea($_eachBmp, 1, $dupeCheckArea[0], $dupeCheckArea[1], $dupeCheckArea[2], $dupeCheckArea[3], $result[0], $result[1], 120)

			If $foundDuplicate == True Then
				;print("- FOUND DUPE > " & $_eachBmp & " - " & $foundDuplicate & " = " & $result[0] & " - " & $result[1] & " - " & $_eachBmp)
				$dupeCount += 1
				ExitLoop
			ElseIf $foundDuplicate == False Then
				; keep file if there is no file or no dupe match.
				$dupeCount += 0
			Else
				; keep file if there is no file or no dupe match.
				$dupeCount += 0
			EndIf

		Else
			$dupeCount += 0
		EndIf
		; Delete last 15 bitmap
	Next

	If $dupeCount == 0 Then
		$deleteOldBmp = $tmpdirPath & "\" & ($clickSpotCount - ($storeSampleCount + 1)) & ".bmp"
		FileDelete($deleteOldBmp)
		$clickSpotCount += 1
	EndIf

	Return $dupeCount


EndFunc   ;==>checkDuplicateClick


Func print($string)
	ConsoleWrite(@CRLF & $string)
	FileWriteLine("rom-scrapper.log", $string)
EndFunc   ;==>print


Func getItemInfo()
	Local $itemID = 0

	;print("> getItemInfo called")

	$retryCount = 0


	$itemID = _MemoryRead($selectedItemID_address, $hMemory, 'dword')
	$itemPrice = _MemoryRead($selectedItemPrice_address, $hMemory, 'dword')

	;print("~ "  & $itemID & " : " & $itemPrice &  " - $lastItemID: " & $lastItemID);


	If $itemID <> $lastItemID Then
		print("+ ID: " & $itemID & ", Price: " & $itemPrice & ", $lastItemID: " & $lastItemID) ;
		addToPricelist($itemID, $itemPrice)
		$lastItemID = $itemID

	EndIf

	If ($retryCount > 20) Then
		print("! Price retrieve time-out") ;

	EndIf
	$retryCount += 1

	backToList()

	;print("> getItemInfo end")
EndFunc   ;==>getItemInfo

Func checkEndList()
	Dim $area[4] = [$listAreaStartCoor[0] + 40, $listAreaStartCoor[1] + 20, $listAreaStartCoor[0] + 70, $listAreaStartCoor[1] + 300]

	Local $pixel_checksum = PixelChecksum($area[0], $area[1], $area[2], $area[3])


	If $lastListEndChecksum == $pixel_checksum Then
		;print("> List End")
		Return True
	Else
		;print("# "&$pixel_checksum)
		$lastListEndChecksum = $pixel_checksum
		Return False
	EndIf

EndFunc   ;==>checkEndList

Func findCategory()
	print($categoryList[$categoryIndex])
	Dim $result[2]
	Dim $rect[4] = [$categorylistAreaStartCoor[0], $categorylistAreaStartCoor[1], $categorylistAreaStartCoor[0] + $categoryListWidth, $categorylistAreaStartCoor[1] + $categoryListHeight]
	Local $imageFile = "res/" & $categoryList[$categoryIndex] & ".bmp"
	Local $found = _ImageSearchArea($imageFile, 1, $rect[0], $rect[1], $rect[2], $rect[3], $result[0], $result[1], $categoryImageTolerence)

	If $debugMode Then
		MouseMove($rect[0], $rect[1])
		Sleep(500)
		MouseMove($rect[2], $rect[3], 0)
	EndIf

	If ($found) Then
		Dim $pos[2] = [$result[0], $result[1]]
		print($result[0] & "/" & $result[1])
		If $debugMode Then
			MouseMove($pos[0], $pos[1])
		Else
			MouseMove($pos[0], $pos[1])
			;MouseClick("left",$pos[0],$pos[1])
		EndIf
	Else
		print("! Category not found! - " & $imageFile)
	EndIf


EndFunc   ;==>findCategory

Func changeCategory()
	$categoryIndex += 1
	If $categoryIndex >= UBound($categoryList) Then
		$categoryIndex = 0
	EndIf
EndFunc   ;==>changeCategory

Func backToList()
	MouseClick("left", $backButtonCoor[0], $backButtonCoor[1], 1, $mouseMoveDelay)
EndFunc   ;==>backToList

Func exitApp()
	$scanning = False
	Exit
EndFunc   ;==>exitApp

Func getConf($key)
	Return IniRead("config.ini", "config", $key, "Error")
EndFunc   ;==>getConf

Func setConf($key, $value)
	IniWrite("config.ini", "config", $key, $value)
EndFunc   ;==>setConf


Func addToPricelist($itemID, $itemPrice)
	Dim $valueArr[2] = [$itemPrice, getTimestamp()]
	$value = ($valueArr)
	Json_ObjPut($pricelistJsonObj, $itemID, $value)
	$priceCount = Json_ObjGetCount($pricelistJsonObj)

	$updateInterval = 31
	updateGuiView()
	GUICtrlSetData($pricecount_txt, "Price Recorded: " & $priceCount)
EndFunc   ;==>addToPricelist

Func getPricelist()
	Return (json_encode($pricelistJsonObj))
EndFunc   ;==>getPricelist

Func printPricelist()
	Local $pricelist = getPricelist()
	print($pricelist)
EndFunc   ;==>printPricelist

Func savePricelist()
	Local $pricelist = getPricelist()
	print("> Saving pricelist > '" & $outputPricelistJson & "'...")

	saveToFilePath($outputPricelistJson, $pricelist)
EndFunc   ;==>savePricelist

Func getTimestamp()
	Return _DateDiff('s', "1970/01/01 00:00:00", _NowCalc())
EndFunc   ;==>getTimestamp

Func formatPrice($number)
	Return StringRegExpReplace($number, "(?!\.)(\d)(?=(?:\d{3})+(?!\d))(?<!\.\d{1}|\.\d{2}|\.\d{3}|\.\d{4}|\.\d{5}|\.\d{6}|\.\d{7}|\.\d{8}|\.\d{9})", "\1,")
EndFunc   ;==>formatPrice

Func _GetHwndFromPID($PID)
	$hWnd = 0
	$winlist = WinList()
	Do
		For $i = 1 To $winlist[0][0]
			If $winlist[$i][0] <> "" Then
				$iPID2 = WinGetProcess($winlist[$i][1])
				If $iPID2 = $PID Then
					$hWnd = $winlist[$i][1]
					ExitLoop
				EndIf
			EndIf
		Next
	Until $hWnd <> 0
	Return $hWnd
EndFunc   ;==>_GetHwndFromPID

Func alignedBy4($val)
	If (Floor(($val / 4)) * 4) == $val Then
		Return True
	Else
		Return False
	EndIf
EndFunc   ;==>alignedBy4

Func roundBytes($address, $bytesLen)
	Return (Floor($address / $bytesLen)) * $bytesLen
EndFunc   ;==>roundBytes

Func roundDword($address)
	Return roundBytes($address, 4)
EndFunc   ;==>roundDword

Func roundWord($address)
	Return roundBytes($address, 2)
EndFunc   ;==>roundWord

Func _MemoryScan($ProcessHandle, $pattern, $StartAddress = 0x6FFFFFFF, $StopAddress = 0xEFFFFFFF, $Step = 2560000)

	$addressScanning = True

	$StartAddress = roundDword(Int(StringFormat("%u", $StartAddress)))
	$StopAddress = roundDword(Int(StringFormat("%u", $StopAddress)))
	$Step = roundDword($Step)

	Local $maxStep = Floor(($StopAddress - $StartAddress) / $Step)
	print("$maxStep: " & $maxStep)

	If Not IsArray($ProcessHandle) Then
		SetError(1)
		Return -1
	EndIf



	; Convert int to little endian hex
	If IsInt($pattern) Then
		$pattern = Hex($pattern, 8)
		$pArray = StringRegExp($pattern, ".{2}", 3)
		_ArrayReverse($pArray)
		$pattern = _ArrayToString($pArray, " ")
	EndIf

	$pattern = StringRegExpReplace($pattern, '[^?0123456789ABCDEFabcdef.]', '')

	If StringLen($pattern) = 0 Then
		SetError(2)
		Return -2
	EndIf

	Local $BufferPattern, $FormatedPattern
	For $i = 0 To ((StringLen($pattern) / 2) - 1)
		$BufferPattern = StringLeft($pattern, 2)
		$pattern = StringRight($pattern, StringLen($pattern) - 2)
		$FormatedPattern = $FormatedPattern & $BufferPattern
	Next

	; Split binary
	$pArray = StringRegExp($FormatedPattern, ".{2}", 3)
	$pattern = '\x' & _ArrayToString($pArray, '\x')

	Local $countScan = 0
	Local $ScanStep = $Step - (StringLen($pattern) / 2)
	$ScanStep = $Step

	$Start_Time = TimerInit()
	Local $lastWaitingTime = 0
	For $address = $StartAddress To $StopAddress Step $ScanStep


		$memory = _MemoryRead($address, $ProcessHandle, 'byte[' & $Step & ']')


		$Previous_Time = TimerInit()
		scanMemSection($memory, $pattern, $address)
		;scanMemSection2($memory,$pattern,$address)
		;scanMemSection3($memory,$pattern,$address)
		$Time_Difference = TimerDiff($Previous_Time)
		print("> Write time: " & $Time_Difference)

		;print($countScan)
		$countScan += 1

		$waitingTime = Ceiling(TimerDiff($Start_Time) / 1000)

		If $waitingTime <> $lastWaitingTime Then
			$lastWaitingTime = $waitingTime
			print("> Waiting Time: " & $waitingTime & "s")
		EndIf

		If Not ($addressScanning) Then
			Return -4
			ExitLoop
		EndIf

		getGuiMsg()
		GUICtrlSetData($step1[4], (($countScan / $maxStep) * 100))
	Next


	Return -3
EndFunc   ;==>_MemoryScan

Func stopAddressScanning()
	clearScanCache()
	$addressScanning = False
EndFunc   ;==>stopAddressScanning

Func clearScanCache()
	$deleteCmd = @ComSpec & " /c del /Q " & $tmpdirPath
	RunWait($deleteCmd, @WorkingDir, @SW_HIDE)
EndFunc   ;==>clearScanCache

Func scanMemSection($memory, $pattern, $address)

	$tmpFile = $tmpdirPath & "\" & Hex($address, 8)
	$tmpFileRes = $tmpdirPath & "\" & Hex($address, 8) & ".scanres"

	$payload = $memory ; StringTrimLeft(($memory),2);

	FileWrite($tmpFile, $payload)

	; using grep is faster than autoit substring......  TODO: find faster way to scan
	; Sqlite is faster than grep..

	;$Previous_Time = TimerInit()
	;RunWait(@ComSpec & " /c grep -ob '" & $Pattern & "' " & $tmpFile & " >> " & $tmpFileRes,@WorkingDir,@SW_HIDE)

	$run_cmd = @ComSpec & ' /c "' & @WorkingDir & '\library\pcre2grep.exe" -a --file-offsets --buffer-size=3M  ' & $pattern & " " & $tmpFile & " > " & $tmpFileRes
	RunWait($run_cmd, @WorkingDir, @SW_HIDE)

	FileDelete($tmpFile)

	If FileGetSize($tmpFileRes) == 0 Then
		FileDelete($tmpFileRes)
	EndIf

EndFunc   ;==>scanMemSection

Func scanMemSection2($memory, $pattern, $address)
	; Very slow
	$payload = StringTrimLeft(String($memory), 2) ;
	$result = StringInStr($payload, $pattern)
	If $result <> 0 Then
		print($result)
	EndIf
EndFunc   ;==>scanMemSection2

Func scanMemSection3($memory, $pattern, $address)
	; No longer needed
	;_SQLite_Exec(-1, "INSERT INTO scan_db(memory,base_address) VALUES (x'"&StringTrimLeft($memory,2)&"','"&hex($address,8)&"');")
EndFunc   ;==>scanMemSection3

Func addToPriceAddressList($address)
	_ArrayAdd($scanPriceAddressList, $address)
EndFunc   ;==>addToPriceAddressList


Func createFilePath($filePath)
	$filePath = StringReplace($filePath, "/", "\")
	$filePathArr = StringSplit($filePath, "\")

	$fileDir = _ArrayToString($filePathArr, "\", 1, UBound($filePathArr) - 2)

	If FileExists($fileDir) Then
		;Return False
		Return $fileDir
	EndIf

	If DirCreate($fileDir) == 1 Then
		print('> ' & $fileDir & " dir created.")
		;return True
	EndIf

	Return $fileDir
EndFunc   ;==>createFilePath

Func saveToFilePath($filePath, $data)
	Local $fHandle, $baseJsonStr, $baseJsonObj

	; Create file dir if it's not exist.
	$dirPath = createFilePath($filePath)

	$baseJsonStr = FileRead($filePath)

	If StringLen($baseJsonStr) < 1 Then
		$baseJsonStr = "{}"
	EndIf

	$baseJsonObj = Json_Decode($baseJsonStr)

	Json_ObjMerge($baseJsonObj, $pricelistJsonObj)


	$currentPricelistJsonStr = json_encode($pricelistJsonObj)
	$baseJsonStr = json_encode($baseJsonObj)

	$fHandle = FileOpen($filePath, 2)
	FileWrite($fHandle, $baseJsonStr)
	FileClose($fHandle)

	$dirPathChunk = createFilePath($dirPath & "\_update_segment\")
	FileWrite($dirPathChunk & "\price_update_" & getTimestamp() & ".json", $currentPricelistJsonStr)

EndFunc   ;==>saveToFilePath
