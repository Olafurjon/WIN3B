function thjonustur { #bý til þjónustu
param (
        [Parameter(HelpMessage="running eða stopped")] #hjálparstrengur
        [string]$string

)

if ($string.ToLower() -eq "stopped") #tolower þannig að það væli ekki yfir STOPPED
{
Get-Service | Where-Object {$_.status -eq "stopped"}
}
elseif ($string.ToLower() -eq "running") #tolower þannig að það væli ekki yfir running
{
Get-Service | Where-Object {$_.status -eq "running"}
}
else #ef að notandi klúðrar innslátti fær hann bara allt
{
Get-Service
}
}

function notendurIskra { #import AD modulnum til að vinna með hann, leitar af nafni á ou , ef OU er ekk til þá segir hann það og prentar svo villu frá powershell, ef það er til þá exportar hún því beint í 
 param( 
 [Parameter(Mandatory=$true)]
 [string]$NafnAou
 )
 Import-Module ActiveDirectory  
 $ou = Get-ADOrganizationalUnit –Filter { name -like $NafnAou }
 $error.Clear()
 try {
 $users = Get-ADUser -SearchBase $ou -filter * `  -property description
 $users | export-csv "C:\Users\Administrator\Desktop\$NafnAou.csv" -Encoding UTF8 #Býr til skrá sem heitir það sem þú slærð inn ef að ou er til
 }
 catch
 {
  "Villa kom upp mögulega er OU ekki til, Powershell hefur þetta að segja: "
  $error
 }

 }

function prentararurcsv {
$prentarar =  import-csv "C:\Users\Administrator\OneDrive\Tskoli2017\WIN3B3U\Hlutaprof 1\prentarar.csv" -Encoding UTF8 #Býr til prentaranna
foreach($p in $prentarar){ #foreach 
Add-PrinterDriver $p.rekill #er viss um að rekillinn er sintallaður
Add-Printer -Name $p.nafn -drivername $p.rekill -Shared -PortName $p.port -ShareName $p.deilinafn -Location $p.staðsetning -Published #bætir síðan printernum við
}

}