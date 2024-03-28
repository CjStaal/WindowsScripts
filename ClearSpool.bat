net stop spooler
taskkill /f /im "printfilterpipelinesvc.exe"
del /F /Q C:\Windows\System32\Spool\Printers\*.*
net start spooler