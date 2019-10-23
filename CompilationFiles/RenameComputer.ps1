function Get-CorrectComputerName {
#get correct name of the computer
$SerialNumberGet = [string](WMIC BIOS GET SERIALNUMBER)
$SerialNumber = $SerialNumberGet.Substring(16, $SerialNumberGet.Length - 18)
$ComputerName = 'MSOE-' + $SerialNumber.Substring(0, $SerialNumber.IndexOf(" "))
return $ComputerName
}

function Get-Domain {
return (Get-WmiObject Win32_ComputerSystem).Domain
}

function Get-CurrentComputerName {
return (Get-WmiObject Win32_ComputerSystem).Name
}

Function Check-LogFile
{
    $Time = Get-Date
    #Test if log file folder exists
    if ((Test-Path -Path "C:\Logs\RenameLogs\") -ne $true)
        {
            mkdir "C:\Logs\RenameLogs\"
        }
    # Test if the log file for this computer exists
	if ((Test-Path -Path "C:\Logs\RenameLogs\$CurrentComputerName.txt") -ne $true)
	    {
			New-Item "C:\Logs\RenameLogs\$CurrentComputerName.txt"
	    }
    
    
}

Function Write-Log
{

		Param ([string]$logstring)
		Add-content $Logfile -value $logstring

}
#Check to see if the log file exist


#Check if the computer name is what it is supposed to be
$CurrentComputerName = Get-CorrectComputerName
$CorrectComputerName = Get-CurrentComputerName

#Set up Logging
Check-LogFile
$LogFile = "C:\Logs\RenameLogs\$CurrentComputerName.txt"
$Date = (Get-Date).ToString()
Write-Log "-----------------------------------------------------"
Write-Log "-----------------------------------------------------"
Write-Log "Time Ran: $Date"
Write-Host "Time Ran: $Date"

Write-Host "Starting Rename Process for $CurrentComputerName"
Write-Log "Starting Rename Process for $CurrentComputerName"

If (-NOT ($CurrentComputerName -like $CorrectComputerName)) {#Is the name correct
    #Show current and correct name
    Write-Host "Changing computer name"
    Write-Log "Changing computer name"
    sleep 1
    $ActualName = Get-CorrectComputerName
    $CurrentName = (Get-WmiObject Win32_ComputerSystem).Name
    Write-Host "Computer Name should be $ActualName, but computer is currently called $CurrentName"
    Write-Log "Computer Name should be $ActualName, but computer is currently called $CurrentName"
    sleep 1
    #Rename the computer
    $User = "ad.msoe.edu\helpdeskadmanage"
    $PWord = ConvertTo-SecureString -String "~~password~~" -AsPlainText -Force ##Place password for AD account, get from Sys Admin
    $Credential = "AD\Helpdeskadmanage"
    #$Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User, $PWord
    If ((Get-WmiObject Win32_ComputerSystem).Domain -like "ad.msoe.edu") {
        Try 
        {
            Remove-ADComputer -Identity $CurrentComputerName -Credential $Credential
        }
        Catch {
            Write-Host "Computer not in the domain, trying to add to arbitrary workgroup"
            Write-Log "Computer not in the domain, trying to add to arbitrary workgroup"
            Write-Log  "Error Message: $($_.Exception.Message)"
        }
        Try {
            Add-Computer -WorkgroupName IT -Credential $Credential -Restart -Confirm
        }
        Catch
        {
            Write-Host "Can't unjoin from domain, Computer not Renamed"
            Write-Log "Can't unjoin from domain, Computer not Renamed"
            Write-Log  "Error Message: $($_.Exception.Message)"
        }
    }else {
        Try {
        Add-Computer -DomainName ad.msoe.edu -Credential $Credential 
            Try{
            Rename-Computer -NewName $ActualName -DomainCredential $Credential -Confirm -Restart
            }
            Catch {
            Write-Log "Computer Rename Failure"
            Write-Host "Computer Rename Failure"
            sleep 1
            }
        }
        Catch {
           Write-Host "Domain Rejoin Failure, Computer not renamed"
           Write-Log "Domain Rejoin Failure, Computer not renamed"
           Write-Log  "Error Message: $($_.Exception.Message)"
           sleep 1
        }
    }
}else {
Write-Host "Name is already correct"
Write-Host "If this is incorrect, try restarting the computer to get Windows to pull the correct serial number"
Write-Log "Name is already correct"
Write-Log "If this is incorrect, try restarting the computer to get Windows to pull the correct serial number"

sleep 1
}

    #Check if computer is back on the MSOE domain
    $Domain = Get-Domain
    
    If ($Domain -ne "ad.msoe.edu") {
        Write-Host "Adding Computer Back to Domain"
        Write-Log "Adding Computer Back to Domain"
        Try {
        Add-Computer -DomainName "ad.msoe.edu" -LocalCredential $Credential -Confirm -Restart
        }
        Catch {
            Write-Host "Could not add to domain"
            Write-Log "Could not add to domain"
            Write-Log  "Error Message: $($_.Exception.Message)"
        }
    }
    Else {
        Write-Host "Computer Already on Domain"
        Write-Log "Computer Already on Domain"
    }
sleep 1

If (($CurrentComputerName -like $CorrectComputerName) -and ($Domain -like "*ad.msoe.edu*")) {
    Write-Host "Rename Script Successful"
    Write-Log "Rename Script Successful.  https://tinyurl.com/YouDidTheRename"
    }
ElseIf ($CurrentComputerName -like $CorrectComputerName) {
    Write-Host "Computer name correct, not on domain"
    Write-Log "Computer Name Correct, not on Domain. This is likely an intermediate step which will be remedied by running this program more" 
    }
ElseIf ($Domain -like "*ad.msoe.edu*") {
    Write-Host "Computer on Domain, but name is incorrect"
    Write-Log "Computer on Domain, but name is incorrect.  This is likely an intermediate step which will be remedied by running this program more"
    }
Else {
    Write-Host "Nothing Worked, Try restarting"
    Write-Log "Nothing Worked, What are you doing?"
}
pause