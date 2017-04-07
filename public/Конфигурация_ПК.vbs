Dim fso, ts, objShell, strpath, ramsize, vrm

ramsize=0

Const ForWriting=2

Set objShell=Wscript.CreateObject("WScript.Shell")
strpath=objShell.SpecialFolders("Desktop") & "\sysinfo.txt"

Set fso=CreateObject("Scripting.FileSystemObject")
Set ts=fso.CreateTextFile(strpath, True)
 
strComputer = "." 
Set objWMIService = GetObject("winmgmts:" _ 
    & "{impersonationLevel=impersonate}!\\" & strComputer & "\root\cimv2") 

On Error Resume Next

Set colItems = objWMIService.ExecQuery("Select * from Win32_VideoController") 
ts.writeline("----------------------------------------------------------------------------")
ts.writeline("[    Видеокарта   ]")
For Each objItem in colItems
    vrm=objItem.Caption
    if IsNull(vrm) Then
	vrm="NULL"
    End If
    ts.writeline("Name: " & vrm)
    ts.writeline("- - - - - - - - - - - - - ")
    Next


Set colItems = objWMIService.ExecQuery("Select * from Win32_BaseBoard") 
ts.writeline("----------------------------------------------------------------------------")
ts.writeline("[   Мат. плата   ]")
For Each objItem in colItems
    vrm=objItem.Product
    if IsNull(vrm) Then
	vrm="NULL"
    End If
    ts.writeline("Name: " & vrm)
    ts.writeline("- - - - - - - - - - - - - ")
    Next

Set colItems = objWMIService.ExecQuery("Select * from Win32_Processor") 
ts.writeline("----------------------------------------------------------------------------")
ts.writeline("[   Процессор   ]")
For Each objItem in colItems
    vrm=objItem.Name & " (" & objItem.Caption & ")"
    if IsNull(objItem.Name) Then
	vrm="NULL"
    End If
    ts.writeline("Name: " & vrm)
    ts.writeline("- - - - - - - - - - - - - ")
    Next

Set colItems = objWMIService.ExecQuery("Select * from Win32_PhysicalMemory") 
ts.writeline("----------------------------------------------------------------------------")
ts.writeline("[   ОЗУ   ]")
For Each objItem in colItems
    ramsize=ramsize+objItem.Capacity
    Next
ts.writeline("Size: " & ramsize/1048576 & "Mb")
    ts.writeline("- - - - - - - - - - - - - ")

Set colItems = objWMIService.ExecQuery("Select * from Win32_DiskDrive") 
ts.writeline("----------------------------------------------------------------------------")
ts.writeline("[    HDD   ]")
For Each objItem in colItems
    vrm=objItem.Caption
    if IsNull(vrm) Then
	vrm="NULL"
    End If
    ts.writeline("Name: " & vrm)
    ts.writeline("- - - - - - - - - - - - - ")
    Next


ts.close()
MsgBox "Файл конфигурации создан на рабочем столе с именем sysinfo.txt"