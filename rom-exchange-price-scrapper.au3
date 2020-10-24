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

#RequireAdmin
#include <Array.au3>
#include <GUIConstants.au3>
#include <GUIConstantsEx.au3>

#include <library/NomadMemory.au3>
#include <library/Json.au3>
#include <library/ImageSearch.au3>
#include <library/FastFind.au3>

#include <Date.au3>

HotKeySet("^0",exitApp)
HotKeySet("^1",checkEndList)
HotKeySet("^5",scrollItemList)
HotKeySet("^6",printPricelist)
HotKeySet("^7",getItemInfo)
HotKeySet("^8",scanCurrentList)
HotKeySet("^9",pauseScan)

Local $appName = "ROM Exchange Price Scrapper v0.1"

Dim $listDragPointCoor[2] = [getConf("listDragPointCoor_x"),getConf("listDragPointCoor_y")]
Local $listDragDistance = getConf("listDragDistance")
Local $scrollDragSpeed = getConf("scrollDragSpeed")
Local $mouseMoveDelay = getConf("mouseMoveDelay")

Dim $backButtonCoor[2] = [getConf("backButtonCoor_x"),getConf("backButtonCoor_y")]

Dim $listAreaStartCoor[2] = [getConf("listAreaStartCoor_x"),getConf("listAreaStartCoor_y")]
Dim $listAreaSize[2] = [getConf("listAreaStartCoor_x"),getConf("listAreaSize_y")]


Local $selectedItemID_address = getConf("itemIdAddress")
Local $selectedItemPrice_address = getConf("itemPriceAddress")

Local $appClientMemoryName = getConf("emulatorMemoryProcess")
Local $appClientWindowName = getConf("emulatorWindowProcess")

Local $imageTolerence = getConf("imageTolerence")


if getConf("debugMode") == 1 Then
	Local $debugMode =  True
Else
	Local $debugMode =  False
EndIf


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

; Main GUI
$guiHeight = 500
$guiWidth = 300
$hGUI = GUICreate($appName, $guiWidth, $guiHeight, (@DesktopWidth - $guiWidth - 10), 10,BitXOR($WS_CAPTION, $WS_POPUP, $WS_SYSMENU))
$itemPrice_grp = GUICtrlCreateGroup("Selected Item Price",10, 10,$guiWidth - 20, 120)
$itemPrice_txt = GUICtrlCreateInput("0",20, 30,$guiWidth - 40, 40,BitXOR($ES_CENTER,$WS_DISABLED))
GUICtrlSetFont ( -1, 24)
$start_btn = GUICtrlCreateButton("Start Scan", 20, 80, 120, 32)
$pricecount_txt = GUICtrlCreateLabel("", 150, 90, 150, 26)
GUICtrlCreateGroup("", -99, -99, 1, 1) ;close group
GUISetState(@SW_SHOW)


While 1
	Switch GUIGetMsg()
		Case $GUI_EVENT_CLOSE, $idOK
			ExitLoop
		Case $start_btn
			startScan()

	EndSwitch

	updateGuiView()
	Sleep(10)
WEnd

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

Func startScan()
	WinActivate($hWnd)
	Sleep(100)
	WinWait($hWnd)

	MouseClick("left",$listDragPointCoor[0],$listDragPointCoor[1]) ; Init click to focus

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
	;MouseMove($listAreaStartCoor[0],$listAreaStartCoor[1])
	;Sleep(500)
	MouseClick("left",$listDragPointCoor[0],$listDragPointCoor[1]-50)
	Sleep(150)
	MouseWheel("down",1)
	Sleep(150)
	MouseWheel("down",1)
	Sleep(150)
	MouseWheel("down",1)
	Sleep(1500)

	if checkEndList() Then
		print("= scrollItemList Ended!")
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

	$offset_x = $column * 360
	$offset_y = $row * 100

	$list_point_x = $listAreaStartCoor[0]+$offset_x
	$list_point_y = $listAreaStartCoor[1]+$offset_y

	$area[0] = $list_point_x
	$area[1] = $list_point_y

	$area[2] = $list_point_x+380
	$area[3] = $list_point_y+120

	if $debugMode Then
		MouseMove($area[0],$area[1])
		Sleep(500)
		MouseMove($area[2],$area[3])
	EndIf

	scanClickPoint($area)

EndFunc


func scanClickPoint($rect)
	dim $result[2]

	$found = _ImageSearchArea("res/border_tr.bmp",0 , $rect[0],$rect[1],$rect[2],$rect[3], $result[0], $result[1],$imageTolerence)

	if($found) Then

		if $debugMode Then
			print('- ' &  $result[0] & " / " & $result[1]);
			MouseMove($result[0]-50,$result[1]+5)
			Sleep(200)
		Else
			MouseClick("left",$result[0]-50,$result[1]+5,1,$mouseMoveDelay)
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


;Function for getting HWND from PID
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
EndFunc;==>_GetHwndFromPID