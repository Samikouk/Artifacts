Param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$True)]
    [string] $domain,
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$True)]
    [string] $domainOU,
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$True)]
    [string] $domainUser,
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$True)]
    [string] $domainPass
)

<##################################################################################################
    Description
    ===========
    - This script adds a machine to a domain
    - The script expects 3 parameters:
        domain: The domain that the machine should be joining
    - Log is generated in the same folder in which this script resides:
        - $PSScriptRoot\JoinDomain-{TimeStamp} folder
    Usage examples
    ==============
    
    Powershell -executionpolicy bypass -file DomainJoin.ps1 -domain myDomain 
    Pre-Requisites
    ==============
    - Please ensure that this script is run elevated.
    - Please ensure that the powershell execution policy is set to unrestricted or bypass.

##################################################################################################>

#
# Powershell Configurations
#

# Note: Because the $ErrorActionPreference is "Stop", this script will stop on first failure.  
$ErrorActionPreference = "stop"

#Enable-PSRemoting -Force -SkipNetworkProfileCheck

# Ensure that current process can run scripts. 
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force 

###################################################################################################

#
# Custom Configurations
#

# Location of the log files
#$ScriptLogFolder = Join-Path $PSScriptRoot -ChildPath $("DomainJoin-" + [System.DateTime]::Now.ToString("yyyy-MM-dd-HH-mm-ss"))
$ScriptLogFolder = "C:\Azure"
$ScriptLog = Join-Path -Path $ScriptLogFolder -ChildPath "DomainJoin.log"
#$ScriptLog = 'C:\Azure\DomainJoin.log'
# Default exit code
$ExitCode = 0

##################################################################################################

# 
# Description:
#  - Creates the folder structure which'll be used for dumping logs generated by this script and
#    the logon task.


function InitializeFolders
{
    if ($false -eq (Test-Path -Path $ScriptLogFolder))
    {
        New-Item -Path $ScriptLogFolder -ItemType directory | Out-Null
    }
}

##################################################################################################

# 
# Description:
#  - Writes specified string to the console as well as to the script log (indicated by $ScriptLog).
#
# Parameters:
#  - $message: The string to write.


function WriteLog
{
    Param(
        <# Can be null or empty #> $message
    )

    $timestampedMessage = $("[" + [System.DateTime]::Now + "] " + $message) | % {  
        Write-Host -Object $_
        Out-File -InputObject $_ -FilePath $ScriptLog -Append
    }
}

##################################################################################################

#
# 
#

try
{
    #
    #InitializeFolders

    #$cred = Import-Csv c:\Azure\domainjoin.csv

    # Concatenate the full user (domain\userName) to be used to join to the domain   
    # Followed by adding the machine to the specified domain
    $securePassword = $domainPass | ConvertTo-SecureString -asPlainText -Force
    #$fullUserName = $cred.UserName

    $credential = New-Object System.Management.Automation.PSCredential($domainUser,$securePassword)
    Add-Computer -DomainName $domain -Credential $credential -OUPath $domainOU
    Restart-Computer
    Remove-Item -path 'C:\Azure\domainjoin.csv' -Force
}

catch
{
    if (($null -ne $Error[0]) -and ($null -ne $Error[0].Exception) -and ($null -ne $Error[0].Exception.Message))
    {
        $errMsg = $Error[0].Exception.Message
        WriteLog $errMsg
        Write-Host $errMsg
    }

    # Important note: Throwing a terminating error (using $ErrorActionPreference = "stop") still returns exit 
    # code zero from the powershell script. The workaround is to use try/catch blocks and return a non-zero 
    # exit code from the catch block. 
    $ExitCode = -1
}

finally
{
    WriteLog $("This output log has been saved to: " + $ScriptLog)

    WriteLog $("Exiting with " + $ExitCode)
    exit $ExitCode
}
