function thjonustur {
param (
        [Parameter(HelpMessage="running eða stopped")]
        [string]$string

)

if ($string.ToLower() -eq "stopped")
{
Get-Service | Where-Object {$_.status -eq "stopped"}
}
elseif ($string.ToLower() -eq "running")
{
Get-Service | Where-Object {$_.status -eq "running"}
}
else 
{
Get-Service
}
}

function notendurIskra {
 param(
 [Parameter(Mandatory=$true)]
 [string]$NafnAou
 )
 Import-Module ActiveDirectory  
 $ou = Get-ADOrganizationalUnit –Filter { name -like $NafnAou }
 $users = Get-ADUser -SearchBase $ou -filter * `  -property description
 $users | export-csv C:\Users\Administrator\Desktop\users.csv -Encoding UTF8

 }
