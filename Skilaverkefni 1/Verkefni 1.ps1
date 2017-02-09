
function NetkortogForest #Vilt keyra þetta fyrst, uppsetning á domaininu
{
 param(
        [Parameter(Mandatory=$true, HelpMessage="Hvað á Domainið að heita? (1/5)")]
        [string]$domain,
        [Parameter(Mandatory=$true, HelpMessage="Sláðu inn heitið á netkortinu sem þú vilt nota.(2/5)")] #Yfirleitt Ethernet 1 eða tvö
        [string]$gamlanetkort,
        [Parameter(Mandatory=$true, HelpMessage="Sláðu inn nýtt nafn fyrir það (3/5)")]
        [string]$nyjanetkort,
        [Parameter(Mandatory=$true, HelpMessage="Sláðu inn IP töluna sem þú vilt nota (4/5)")]
        $ipaddress,
        [Parameter(Mandatory=$true, HelpMessage="Sláðu inn prefixið á iptölunni (5/5)")]
        [int]$prefix
        
    )
    $local = ".local"
    $domainlocal = $domain+$local;
   



try {
if($gamlanetkort -notlike "" -or $nyjanetkort -notlike "") 
{
Rename-NetAdapter -Name $gamlanetkort -NewName $nyjanetkort
New-NetIPAddress -InterfaceAlias $nyjanetkort -IPAddress $ipaddress -PrefixLength $prefix #-DefaultGateway 192.168.1.1 notum ekki default gateway
Set-DnsClientServerAddress -InterfaceAlias $nyjanetkort -ServerAddresses 127.0.0.1 
}

Install-WindowsFeature -Name AD-Domain-Services –IncludeManagementTools
Install-ADDSForest –DomainName $domainlocal –InstallDNS -SafeModeAdministratorPassword (ConvertTo-SecureString -AsPlainText "pass.123" -Force) 
}
catch {$error, "Vandamál kom upp" }
if (!$error) {
$wshell = New-Object -ComObject Wscript.Shell
$wshell.Popup("Aðgerð Tókst, Vél mun endurræsa sig",0,"Okei",0x1)

}
}
function SetjauppDHCPscopeogClientADomain #Keyra þetta nr2
{
 param(
        [Parameter(Mandatory=$true, HelpMessage="Hvað á scopeið að heita? (1/7)")]
        [string]$scopename,
        [Parameter(Mandatory=$true, HelpMessage="Á hvaða IP á scopeið að byrja?(2/7)")] #Hversu marga notendur viltu í raun hafa
        $ipstart,
        [Parameter(Mandatory=$true, HelpMessage="Á hvaða Ip á scopeið að enda? (3/7)")]
        $ipend,
        [Parameter(Mandatory=$true, HelpMessage="Hver er subnet maskinn? (4/7)")]
        $subnet,
        [Parameter(Mandatory=$true, HelpMessage="Hvaða IP tala á serverinn að vera? (5/7)")]
        $routerip,
        [Parameter(Mandatory=$true, HelpMessage="Hvað er nafnið á server vélinni? (t.d. WIN3A-15) (6/7)")]
        [string]$servervel,
        [Parameter(Mandatory=$true, HelpMessage="Hvað er nafnið á Client vélinni? (t.d. WIN3A-W81-15) (7/7)")]
        [string]$client
        
    )
    $domain2 = Get-ADDomain
    $local = $domain2.DNSroot

    $domainname = $domain2.name
    $dnsname = $domainname+".local"

    
  
Install-WindowsFeature –Name DHCP –IncludeManagementTools
Add-DhcpServerv4Scope -Name $scopename -StartRange $ipstart -EndRange $ipend -SubnetMask $subnet
Set-DhcpServerv4OptionValue -DnsServer $routerip -Router $routerip
Add-DhcpServerInDC -DnsName $domain2.DNSroot #t.d. $($env:computername + “.” $env:userdnsdomain)


Add-Computer -ComputerName $client -LocalCredential $client\Administrator -DomainName $domainname -Credential $domain2.DNSroot\Administrator


if (!$error) {
$wshell = New-Object -ComObject Wscript.Shell
$wshell.Popup("Aðgerð Tókst, Vél mun endurræsa sig",0,"Okei",0x1) 
 }
 } 
 function BuaTilNotendur
{

$path = "C:\DDP"
   $getdomain = Get-ADDomain
   $domainname  = $getdomain.Name

New-ADOrganizationalUnit -Name Notendur -ProtectedFromAccidentalDeletion $false
New-ADGroup -Name NotendurAllir -Path "OU=Notendur,DC=$domainname,DC=local" -GroupScope Global
#Bý til möppuna
new-item $path\Sameign -ItemType Directory
 
#sæki núverandi réttindi
$rettindi = Get-Acl -Path $path\Sameign 
 
#bý til þau réttindi sem ég ætla að bæta við möppuna
$nyrettindi = New-Object System.Security.AccessControl.FileSystemAccessRule "$domainname\NotendurAllir","Modify","Allow"
#Hver á að fá réttindin, hvaða réttindi á viðkomandi að fá, erum við að leyfa eða banna (allow eða deny)
 
#bæti nýju réttindunum við þau sem ég sótti áðan
$rettindi.AddAccessRule($nyrettindi)
 
#Set réttindin aftur á möppuna
Set-Acl -Path $path\sameign $rettindi
 
#Share-a möppunni
New-SmbShare -Name Sameign -Path $path\sameign -FullAccess $domainname\NotendurAllir, administrators 

Add-PrinterDriver -Name "Brother Color Type3 Class Driver"
Add-Printer -Name "Sameign prentari2" -Location "Sameign" -Shared -PortName LPT1: -Drivername "Brother Color Type3 Class Driver" -Published
$notendur = Import-Csv "C:\Users\Administrator\OneDrive\Tskoli2017\WIN3B3U\Skilaverkefni 1\notendur.csv" -Encoding UTF8

foreach($n in $notendur)
{$getdomain = Get-ADDomain
   $domainname  = $getdomain.Name
    $Deild = $n.Deild

   if((Get-ADOrganizationalUnit -Filter { name -eq $Deild }).Name -ne $Deild)
    {

        New-ADOrganizationalUnit -Name $n.Deild -Path "OU=Notendur,DC=$domainname,DC=local" -ProtectedFromAccidentalDeletion $false
        New-ADGroup -Name $Deild -Path $("OU=" + $Deild + ",OU=Notendur,DC=$domainname,DC=local") -GroupScope Global
        Add-ADGroupMember -Identity NotendurAllir -Members $Deild

        #Bý til möppuna
        new-item $path\$Deild -ItemType Directory
 
        #sæki núverandi réttindi
        $rettindi = Get-Acl -Path $path\$Deild
 
        #bý til þau réttindi sem ég ætla að bæta við möppuna
        $nyrettindi = New-Object System.Security.AccessControl.FileSystemAccessRule $domainname\$Deild,"Modify","Allow"
        #Hver á að fá réttindin, hvaða réttindi á viðkomandi að fá, erum við að leyfa eða banna (allow eða deny)
 
        #bæti nýju réttindunum við þau sem ég sótti áðan
        $rettindi.AddAccessRule($nyrettindi)
 
        #Set réttindin aftur á möppuna
        Set-Acl -Path $path\$Deild $rettindi
 
        #Share-a möppunni
        New-SmbShare -Name $Deild -Path $path\$Deild -FullAccess $domainname\$Deild, administrators 

        Add-Printer -Name $($Deild + " prentari") -Location $Deild -Shared -PortName LPT1: -Drivername "Brother Color Type3 Class Driver" -Published

        
    }

    New-ADUser -Name $n.Nafn -DisplayName $n.Nafn -GivenName $n.Fornafn -Surname $n.Eftirnafn -SamAccountName $n.Notendanafn -UserPrincipalName $($n.Notendanafn + "@ddp.is") -EmailAddress $($n.Notendanafn + "@ddp.is") -Path $("OU=" + $Deild + ",OU=Notendur,DC=$domainname,DC=local") -AccountPassword (ConvertTo-SecureString -AsPlainText "pass.123" -Force) -Enabled $true -Title $n.Titill -Country "IS" -EmployeeNumber $n.Starfsmannanr -HomePhone $n.Heimasimi -OfficePhone $n.Vinnusimi -MobilePhone $n.Farsimi -Department $n.Deild -State $n.Sveitarfelag   
    Add-ADGroupMember -Identity $Deild -Members $n.Notendanafn
}


}
function medhondlaTitla {
    Import-Module ActiveDirectory  
    $ou = "ou=Notendur,dc=EEP-Olafur,dc=local"
    $ous =  Get-ADOrganizationalUnit -SearchBase $OU -SearchScope Subtree -Filter * | Select-Object DistinguishedName
    foreach ($o in $ous)
    {
        $boss = get-aduser -SearchBase $o.DistinguishedName -Filter { title -like "*stjóri*" }          
        $users = Get-ADUser -SearchBase $ou -filter * `  -property title,manager
        $boss
            foreach ($u in $users)
            {
            $boss = get-aduser -SearchBase $o.DistinguishedName -Filter { title -like "*stjóri*" }   
            $boss.SamAccountName
            $u.Name            
            if ($boss.Name -eq $u.Name)
            {
            $boss | set-aduser -Manager AndMag
            "Fór hingað"
            }
            else
            {
            $boss = $boss.SamAccountName
            Get-ADUser -SearchBase $o.DistinguishedName -Filter { name -eq $u.Name} | Set-ADUser -Manager $boss
            }
    }
    }

} #hægt er að kommenta út það að þetta birti nöfnin og það til að maður fylli ekki plássið sitt en mér finnst fínt að sjá það til að staðfesta að .það eru að koma ný yfirmanna nöfn

