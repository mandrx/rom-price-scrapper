#cs ----------------------------------------------------------------------------

 AutoIt Version: 3.3.14.2
 Author: mandrx

 Script Function:
	Ragnarok Online Mobile: Eternal Love Exchange Price Scrapper.

#ce ----------------------------------------------------------------------------

AutoItSetOption ("MouseClickDelay",50);
AutoItSetOption ("MouseClickDownDelay",80);
AutoItSetOption ("MouseClickDragDelay",100)
AutoItSetOption ("MouseCoordMode", 2)

;#RequireAdmin
#include <Array.au3>
#include <GUIConstants.au3>
#include <GUIConstantsEx.au3>

#include <library/NomadMemory.au3>
#include <library/Json.au3>
#include <library/ImageSearch.au3>
#include <library/FastFind.au3>

#include <Date.au3>

HotKeySet("^0",exitApp)
HotKeySet("^1",findCategory)
HotKeySet("^2",changeCategory)
HotKeySet("^4",pauseScan)
HotKeySet("^5",scrollItemList)
HotKeySet("^6",printPricelist)
HotKeySet("^7",getItemInfo)
HotKeySet("^8",scanCurrentList)
HotKeySet("^9",reloadINI)

Local $appName = "ROM Exchange Price Scrapper v0.1"


reloadINI()
Func reloadINI()
	Global $listDragPointCoor[2] = [getConf("listDragPointCoor_x"),getConf("listDragPointCoor_y")]
	Global $listDragDistance = getConf("listDragDistance")
	Global $scrollDragSpeed = getConf("scrollDragSpeed")
	Global $mouseMoveDelay = getConf("mouseMoveDelay")

	Global $backButtonCoor[2] = [getConf("backButtonCoor_x"),getConf("backButtonCoor_y")]

	Global $listAreaStartCoor[2] = [getConf("listAreaStartCoor_x"),getConf("listAreaStartCoor_y")]

	Global $itemListWidth = getConf("itemListWidth")
	Global $itemListHeight = getConf("itemListHeight")


	Global $selectedItemID_address = getConf("itemIdAddress")
	Global $selectedItemPrice_address = getConf("itemPriceAddress")

	Global $appClientMemoryName = getConf("emulatorMemoryProcess")
	Global $appClientWindowName = getConf("emulatorWindowProcess")

	Global $itemListImageTolerence = getConf("itemListImageTolerence")
	Global $categoryImageTolerence = getConf("categoryImageTolerence")



	Global $categorylistAreaStartCoor[2] = [getConf("categorylistAreaStartCoor_x"),getConf("categorylistAreaStartCoor_y")]

	Global $categoryListWidth = getConf("categoryListWidth")
	Global $categoryListHeight = getConf("categoryListHeight")

	Global $itemScan1_Name = getConf("itemScan1_Name")
	Global $itemScan2_Name = getConf("itemScan2_Name")
	Global $itemScan3_Name = getConf("itemScan3_Name")

	Global $itemScan1_Id = getConf("itemScan1_Id")
	Global $itemScan2_Id = getConf("itemScan2_Id")
	Global $itemScan3_Id = getConf("itemScan3_Id")

	Global $itemScan1_Price = getConf("itemScan1_Price")
	Global $itemScan2_Price = getConf("itemScan2_Price")
	Global $itemScan3_Price = getConf("itemScan3_Price")

	Global $debugMode =  False
	if getConf("debugMode") == 1 Then
		$debugMode =  True
	EndIf

	print("> Ini reloaded!")
EndFunc




; Init Process data
Local $processList = ProcessList($appClientMemoryName)
$latestPID = $processList[$processList[0][0]][1];
Local $hMemory = _MemoryOpen($latestPID) ; Open the memory

; Init Window data
Local $window_processList = ProcessList($appClientWindowName)
$hWndPID = $window_processList[$window_processList[0][0]][1];
Local $hWnd = _GetHwndFromPID($hWndPID)

WinMove($hWnd,"",0,0,1280,720)

WinActivate($hWnd)
Local $winpos = WinGetPos($hWnd)
$winsize = WinGetClientSize($hWnd)





Global $jsonObj = Json_ObjCreate()
Global $lastItemID = 0
Global $scanning = False
Global $updateInterval = 0
Global $pause = False
Global $lastListEndChecksum = 0
Global $categoryIndex = 0
Global $subCategoryIndex = 0
Dim $categoryList[9]  = ["item9","item8","item7","item6","item5","item4","item3","item2","item1"]

; Main GUI
$guiHeight = 440
$guiWidth = 300
$hGUI = GUICreate($appName, $guiWidth, $guiHeight, (@DesktopWidth - $guiWidth - 10), 10,BitXOR($WS_CAPTION, $WS_POPUP, $WS_SYSMENU))
$itemPrice_grp = GUICtrlCreateGroup("Selected Item Price",10, 10,$guiWidth - 20, 120)
$itemPrice_txt = GUICtrlCreateInput("0",20, 30,$guiWidth - 40, 40,BitXOR($ES_CENTER,$WS_DISABLED))
GUICtrlSetFont ( -1, 24)
$start_btn = GUICtrlCreateButton("Start Scan", 20, 80, 120, 32)
$pricecount_txt = GUICtrlCreateLabel("", 150, 90, 120, 26)
GUICtrlCreateGroup("", -99, -99, 1, 1) ;close group

$hTab = GUICtrlCreateTab(10, 140, 280, 280)
local $i = 1
GUICtrlCreateTabItem("Memory Address")


$updateAddress1_grp = GUICtrlCreateGroup("Address Update Wizard",20, 170,$guiWidth - 20, 120)
Global $step0[2],$step1[4],$step2[4],$step3[4]

$step0[0] = GUICtrlCreateLabel("If the shown price is incorrect, press 'Update Address' and follow the instructions to update the memory address.", 30, 200, 240, 100)
GUICtrlSetFont ( -1, 12)
GUICtrlSetColor(-1,0xff5e00)
$step0[1] = GUICtrlCreateButton("Update Address", 45, 300, 200, 40)
GUICtrlSetFont ( -1, 12)


$step1[0] = GUICtrlCreateLabel("1. Open Exchange, go to '"&$itemScan1_Name&"' listing to see the price, and press 'Next Step'...", 30, 170, 240, 100)
GUICtrlSetFont ( -1, 11)
GUICtrlSetColor(-1,0x0659d6)
$step1[2] = GUICtrlCreatePic("res/step1.jpg",30,220,242,132)
$step1[1] = GUICtrlCreateButton("Next Step >", 31, 360, 170, 36)
$step1[3] = GUICtrlCreateButton("Cancel", 210, 360, 60, 36)


$step2[0] = GUICtrlCreateLabel("2. Go to '"&$itemScan2_Name&"' listing, and press 'Next Step'...", 30, 175, 240, 100)
GUICtrlSetFont ( -1, 11)
GUICtrlSetColor(-1,0x0659d6)
$step2[2] = GUICtrlCreatePic("res/step2.jpg",30,220,242,132)
$step2[1] = GUICtrlCreateButton("Next Step >", 31, 360, 170, 36)
$step2[3] = GUICtrlCreateButton("Cancel", 210, 360, 60, 36)

$step3[0] = GUICtrlCreateLabel("3. Next, go to '"&$itemScan3_Name&"' listing, and press 'Next Step'...", 30, 175, 240, 100)
GUICtrlSetFont ( -1, 11)
GUICtrlSetColor(-1,0x0659d6)
$step3[2] = GUICtrlCreatePic("res/step3.jpg",30,220,242,132)
$step3[1] = GUICtrlCreateButton("Next Step >", 31, 360, 170, 36)
$step3[3] = GUICtrlCreateButton("Cancel", 210, 360, 60, 36)
GUICtrlSetFont ( -1, 12)


GUICtrlSetState($updateAddress1_grp , $GUI_HIDE)

$i = 2
GUICtrlCreateTabItem("Hotkeys")

GUICtrlCreateLabel("See how 'laggy' the UDF buttons are when selecting this tab because of using WinSetState", 20, 200, 150, 60)
GUICtrlCreateButton("Built-In " & $i, 20 + ($i * 100), 40 + ($i * 50), 80, 30)

GUISetState(@SW_SHOW)

showStep0()

While 1
	Switch GUIGetMsg()
		Case $GUI_EVENT_CLOSE, $idOK
			ExitLoop
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

		Case $step1[3],$step2[3],$step3[3]
			doCancelUpdate()

	EndSwitch

	updateGuiView()
	Sleep(10)
WEnd


;==============================
;	GUI RELATED FUNCTIONS
;==============================

func hideAllUpdateSteps()

	For $i = 0 To UBound($step0)-1
		GUICtrlSetState ( $step0[$i], $GUI_HIDE )
	Next

	For $i = 0 To UBound($step1)-1
		GUICtrlSetState ( $step1[$i], $GUI_HIDE )
	Next

	For $i = 0 To UBound($step2)-1
		GUICtrlSetState ( $step2[$i], $GUI_HIDE )
	Next

	For $i = 0 To UBound($step3)-1
		GUICtrlSetState ( $step3[$i], $GUI_HIDE )
	Next

EndFunc


func showStep0()
	hideAllUpdateSteps()

	For $i = 0 To UBound($step0)-1
		GUICtrlSetState ( $step0[$i], $GUI_SHOW )
	Next
EndFunc

func doStep1()
	hideAllUpdateSteps()

	For $i = 0 To UBound($step1)-1
		GUICtrlSetState ( $step1[$i], $GUI_SHOW )
	Next


EndFunc

func doStep2()
	hideAllUpdateSteps()

	For $i = 0 To UBound($step2)-1
		GUICtrlSetState ( $step2[$i], $GUI_SHOW )
	Next


	Local $scan_result = _MemoryScan($hMemory,"A8 61 00 00")


	print($scan_result)

EndFunc

func doStep3()
	hideAllUpdateSteps()

	For $i = 0 To UBound($step3)-1
		GUICtrlSetState ( $step3[$i], $GUI_SHOW )
	Next
EndFunc

func doStepFinal()
	hideAllUpdateSteps()

	;For $i = 0 To UBound($step1)-1
		;GUICtrlSetState ( $step1[$i], $GUI_SHOW )
	;Next

	print("DONE ALL STEPS")
EndFunc

func doCancelUpdate()
	showStep0()
	print("> Memory Address Update Wizard Cancelled...")
EndFunc

func updateGuiView()

	if ($updateInterval > 30) Then
		$updateInterval = 0
		$itemPrice = _MemoryRead($selectedItemPrice_address,$hMemory,'dword')
		GUICtrlSetData($itemPrice_txt,formatPrice($itemPrice) & "z")

		$itemId = _MemoryRead($selectedItemID_address,$hMemory,'dword')
		GUICtrlSetData($itemPrice_grp,"Selected Item Price ( ID: " & $itemId & " )" )

	EndIf

	$updateInterval += 1

EndFunc



;===========================================
;	PRICE SCANNING RELATED FUNCTIONS
;===========================================

Func startScan()
	WinActivate($hWnd)
	Sleep(100)
	WinWait($hWnd)

	MouseClick("left",$listDragPointCoor[0],$listDragPointCoor[1]) ; Init click to focus

	; Show list area
	if $debugMode Then
		MouseMove($listAreaStartCoor[0],$listAreaStartCoor[1])
		Sleep(500)
		MouseMove($listAreaStartCoor[0]+($itemListWidth*2),$listAreaStartCoor[1]+($itemListHeight*4+40))
	EndIf


	$scanning = True

	While $scanning
		scanCurrentList()
		scrollItemList()
	WEnd
EndFunc


Func pauseScan()

	$pause = Not($pause)
	if $pause Then
		print("Pause Scanning...")
	Else
		print("Resume Scanning...")
	EndIf

EndFunc

func scrollItemList()
	WinActivate($hWnd)

	MouseClick("left",$listDragPointCoor[0],$listDragPointCoor[1]-50)
	Sleep(150)
	MouseWheel("down",1)
	Sleep(150)
	MouseWheel("down",1)
	Sleep(150)
	MouseWheel("down",1)
	Sleep(1500)

	if checkEndList() Then

		printPricelist()
		print("> scrollItemList Ended!")

		$scanning = False
	EndIf

	;MouseClickDrag("left",$listDragPointCoor[0],$listDragPointCoor[1],$listDragPointCoor[0],$listDragPointCoor[1]-$listDragDistance,$scrollDragSpeed)
EndFunc

Func scanCurrentList()
	Local $x = 0

	While $x < 8
		if Not($pause) Then
			scanEachListItem($x)
			$x += 1;
			Sleep(50)

			if Not($scanning) Then
				ExitLoop
			EndIf
		EndIf
	WEnd
EndFunc

func scanEachListItem($index)
	Dim $area[4]

	$column = Mod($index,2);
	$row = Floor($index / 2)

	$offset_x = $column * $itemListWidth;370
	$offset_y = $row * $itemListHeight;96

	$list_point_x = $listAreaStartCoor[0]+$offset_x
	$list_point_y = $listAreaStartCoor[1]+$offset_y

	$area[0] = $list_point_x+($itemListWidth-110)
	$area[1] = $list_point_y

	$area[2] = $list_point_x+($itemListWidth+10)
	$area[3] = $list_point_y+($itemListHeight+24)

	if $debugMode Then
		MouseMove($area[0],$area[1])
		Sleep(500)
		MouseMove($area[2],$area[3])
	EndIf

	scanClickPoint($area)

EndFunc


func scanClickPoint($rect)
	dim $result[2]

	$found = _ImageSearchArea("res/border_tr.bmp",0 , $rect[0],$rect[1],$rect[2],$rect[3], $result[0], $result[1],$itemListImageTolerence)

	if($found) Then
		Dim $pos[2] =  [$result[0]-50,$result[1]+5]

		if $debugMode Then
			print('- ' &  $result[0] & " / " & $result[1]);
			MouseMove($pos[0],$pos[1])
			Sleep(200)
		Else
			MouseClick("left",$pos[0],$pos[1],1,$mouseMoveDelay)
			getItemInfo()
		EndIf

	EndIf

EndFunc



; Save all prices data.
;$outputJson = json_encode("")

;$sFilePath = @ScriptDir & "\[output] eq with price.json"
;Local $hFileOpen = FileOpen($sFilePath, bitxor(2,8))
;FileWrite($hFileOpen,$outputJson)


func print($string)
	ConsoleWrite(@CRLF & $string)
EndFunc


func getItemInfo()
	Local $itemID = 0

	;print("> getItemInfo called")

	$retryCount = 0

	While $scanning
		$itemID = _MemoryRead($selectedItemID_address,$hMemory,'dword')
		$itemPrice = _MemoryRead($selectedItemPrice_address,$hMemory,'dword')

		;print("~ "  & $itemID & " : " & $itemPrice &  " - $lastItemID: " & $lastItemID);


		if $itemID <> $lastItemID Then
			print("+ ID: " & $itemID & ", Price: " & $itemPrice &  ", $lastItemID: " & $lastItemID);
			addToPricelist($itemID,$itemPrice)
			$lastItemID = $itemID
			ExitLoop
		EndIf

		if($retryCount > 20) Then
			print("! Price retrieve time-out");
			ExitLoop
		EndIf
		$retryCount += 1

		sleep(50)
	WEnd

	backToList()

	;print("> getItemInfo end")
EndFunc

func checkEndList()
	Dim $area[4] = [$listAreaStartCoor[0]+40,$listAreaStartCoor[1]+20,$listAreaStartCoor[0]+70,$listAreaStartCoor[1]+300]

	Local $pixel_checksum = PixelChecksum($area[0],$area[1],$area[2],$area[3])


	if $lastListEndChecksum == $pixel_checksum Then
		;print("> List End")
		return True
	Else
		;print("# "&$pixel_checksum)
		$lastListEndChecksum = $pixel_checksum
		return False
	EndIf

EndFunc

func findCategory()
	print($categoryList[$categoryIndex])
	Dim $result[2]
	Dim $rect[4] = [$categorylistAreaStartCoor[0],$categorylistAreaStartCoor[1],$categorylistAreaStartCoor[0] + $categoryListWidth,$categorylistAreaStartCoor[1] + $categoryListHeight]
	Local $imageFile = "res/" & $categoryList[$categoryIndex] & ".bmp"
	Local $found = _ImageSearchArea($imageFile,1 , $rect[0],$rect[1],$rect[2],$rect[3], $result[0], $result[1],$categoryImageTolerence)

	if $debugMode Then
		MouseMove($rect[0],$rect[1])
		Sleep(500)
		MouseMove($rect[2],$rect[3],0)
	EndIf

	if($found) Then
		Dim $pos[2] =  [$result[0],$result[1]]
		print($result[0] & "/" & $result[1])
		if $debugMode Then
			MouseMove($pos[0],$pos[1])
		Else
			MouseMove($pos[0],$pos[1])
			;MouseClick("left",$pos[0],$pos[1])
		EndIf
	Else
		print("! Category not found! - " & $imageFile)
	EndIf


EndFunc

func changeCategory()
	$categoryIndex+=1
	if $categoryIndex >= UBound($categoryList) Then
		$categoryIndex = 0
	EndIf
EndFunc

func backToList()
	MouseClick("left",$backButtonCoor[0],$backButtonCoor[1],1,$mouseMoveDelay)
EndFunc

Func exitApp()
	$scanning = False
	Exit
EndFunc

func getConf($key)
	$iniValue = IniRead("config.ini","config",$key,"Error")
	;print($iniValue)
	return  $iniValue
EndFunc


func addToPricelist($itemID,$itemPrice)
	dim $valueArr[2] = [$itemPrice,getTimestamp()]
	$value = ($valueArr)
	Json_ObjPut($jsonObj,$itemID,$value)
	$priceCount = Json_ObjGetCount($jsonObj)

	$updateInterval = 31
	updateGuiView()
	GUICtrlSetData($pricecount_txt,"Price Recorded: " & $priceCount)
EndFunc

func getPricelist()
	return (json_encode($jsonObj))
EndFunc

func printPricelist()
	print(getPricelist())
EndFunc

func getTimestamp()
	return _DateDiff( 's',"1970/01/01 00:00:00",_NowCalc())
EndFunc

Func formatPrice($number)
	return StringRegExpReplace($number, "(?!\.)(\d)(?=(?:\d{3})+(?!\d))(?<!\.\d{1}|\.\d{2}|\.\d{3}|\.\d{4}|\.\d{5}|\.\d{6}|\.\d{7}|\.\d{8}|\.\d{9})", "\1,")
EndFunc

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
EndFunc








Func roundBytes($address,$bytesLen)
	return (Floor($address/$bytesLen))*$bytesLen
EndFunc

Func roundDword($address)
	return roundBytes($address,4)
EndFunc

Func roundWord($address)
	return roundBytes($address,2)
EndFunc

Func _MemoryScan($ProcessHandle, $Pattern, $StartAddress = 0x6FFFFFFF, $StopAddress = 0xFFFFFFFF, $Step = 2560000)

	$StartAddress = 0xAF000000
	$StopAddress = 0xDFFFFFFF;0x88FFF130

	$StartAddress = roundDword(Int(StringFormat("%u", $StartAddress)))
	$StopAddress = roundDword(Int(StringFormat("%u", $StopAddress)))
	$Step = roundDword($Step)

	$Pattern = "A8 61 00 00"

	If Not IsArray($ProcessHandle) Then
	  SetError(1)
	  Return -1
	EndIf

	$Pattern = StringRegExpReplace($Pattern, '[^?0123456789ABCDEFabcdef.]', '')

	If StringLen($Pattern) = 0 Then
	  SetError(2)
	  Return -2
	EndIf

	Local $BufferPattern, $FormatedPattern
	For $i = 0 To ((StringLen($Pattern) / 2) - 1)
	  $BufferPattern = StringLeft($Pattern, 2)
	  $Pattern = StringRight($Pattern, StringLen($Pattern) - 2)
	  $FormatedPattern = $FormatedPattern & $BufferPattern
	Next

	$Pattern = $FormatedPattern

	Local $countScan = 0
	Local $ScanStep = $Step - (StringLen($Pattern) / 2)
	$ScanStep = $Step



	For $Address = $StartAddress To $StopAddress Step $ScanStep
		Local $mChunk = _MemoryRead($Address, $ProcessHandle, 'byte['&$Step&']')

		findInChunk($mChunk,$Pattern,$Address)

		$countScan += 1
	Next

	Return -3
EndFunc

#cs
Func findInChunk($memory,$pattern,$address)

		Global $mStrBuffer = StringTrimLeft(String($memory),2) ; remove 0x
		Global $bytes = 4

		Local $scanCount = 0
		Local $foundCount = 0

		While (StringLen($mStrBuffer) > 0)
			Local $bytesStringLen = $bytes * 2
			$checkString = StringLeft($mStrBuffer,$bytesStringLen)

			Local $pos
			if($checkString == $pattern) Then
				$pos = $scanCount * $bytes
				print("+ Found 0x" & hex($pos,8) & " + 0x" & Hex($address,8) & " = 0x" & Hex(($pos+$address),8))
				$foundCount += 1

			EndIf
			$mStrBuffer = StringTrimLeft($mStrBuffer,$bytesStringLen)

			if( Mod($scanCount,10000) == 0 ) Then
				print("+ Found " & $foundCount & " - " & $pos & " + 0x" & Hex($address,8))
			EndIf


			$scanCount += 1
		WEnd


EndFunc
#ce

Func findInChunk($memory,$pattern,$address)
	Local $mStrBuffer = StringTrimLeft(String($memory),2) ; remove 0x
	Local $pos = Floor((StringInStr($mStrBuffer,$pattern,0))/2)
	print("+ Found 0x" & hex($pos,8) & " = " & $pos & " + 0x" & Hex($address,8) & " = 0x" & Hex(($pos+$address),8))
EndFunc