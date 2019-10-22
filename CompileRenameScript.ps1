$PasswordReplaceString = "~~password~~"
$TempFile = Get-Content -Path 'RenameComputer.ps1'
Write-Host "Running this program to completion re-compiles the rename script into a secure .exe file"
Write-Host "If you run this to completion with the wrong password, the rename script will break"
Write-Host "This is only used to make changes to the rename script, not for its actual functionality"
Write-Host "If this was ran accidentally, close out of the script at the prompt, and nothing should break"
$Password = Read-Host -Prompt 'Input HelpdeskADManage password' 
For ($i = 0; $i -lt $TempFile.Count; $i++) {
    if ($TempFile[$i].IndexOf($PasswordReplaceString) -ne -1) {
        $PasswordIndex = $TempFile[$i].IndexOf($PasswordReplaceString)
        $Line = $i
        $TempFile[$i].replace($PasswordReplaceString, $Password);
        Break
    }
}
$FinalTempFile = Out-String -InputObject $TempFile
Try{ 
Remove-Item -Path TempScript.ps1 -ErrorAction SilentlyContinue
}
catch {
Write-Host "Temp File not present, creating file"
}
New-Item -Path . -Name "TempScript.ps1" -ItemType "File" -Value $FinalTempFile
.\ps2exe.ps1 -inputFile TempScript.ps1 -outputFile RenameComputer.exe

Remove-Item -Path "TempScript.ps1"

$WshShell = New-Object -comObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut(".\RunMeForRename.lnk")
$ScriptDir = Get-Location
$Shortcut.TargetPath = $ScriptDir.ToString() + '\RenameComputer.exe'
$Shortcut.Save()

$bytes = [System.IO.File]::ReadAllBytes(".\RunMeForRename.lnk")
$bytes[0x15] = $bytes[0x15] -bor 0x20 #set byte 21 (0x15) bit 6 (0x20) ON
[System.IO.File]::WriteAllBytes(".\RunMeForRename.lnk", $bytes)
pause