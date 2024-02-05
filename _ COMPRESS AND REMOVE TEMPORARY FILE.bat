Echo Off
:: Color 9b
Color 17
D:

:: Del Unit*.dcu
Del *.dcu
Del *.~*
RmDir __history /s /q

If Exist "March 1, 2013.exe" Del "March 1, 2013.exe"
If Exist "March 1, 2013.ini" Del "March 1, 2013.ini"
Cls

UPX -9 -o "March 1, 2013.exe" "Project1.exe"
Copy "Project1.ini" "March 1, 2013.ini"

:: If Exist "D:\Temp\Christmas\Christmas2012.exe" Del "D:\Temp\Christmas\Christmas2012.exe"

:: Copy Christmas2012.exe "D:\Temp\Christmas\Christmas2012.exe"
