#Function sem tekur í gildi þessar reglur:
#Reglur fyrir skráningu notenda: Notendanafn (samaccountname) á að vera fullt nafn notanda án
#íslenskra stafa og skal skilja nöfn notandans að með punkti (ath. max 20 stafir). Dæmi: Davíð Einar
#Fróðasona verður „david.einar.frodason“. Fornafn (givenname) á að vera allt nema síðasta nafn
#notanda, dæmi: Davið Einar. Föðurnafn (surname) á að vera síðasta nafn notanda, dæmi: Fróðason
function Nafnareglur{
param(
[parameter(Mandatory = $true)]
$nafn
)#tekur inn fullt nafn sem parameter
function replaceISL {
 param( 
 [Parameter(Mandatory=$true)]
    $string
 )
 #Þessi partur skiptir út öllum stöfum, (get bætt alltaf við í framtíðinni ef vantar...
 $string = $string -replace 'á','a'
 $string = $string -replace 'Á','A'
 $string = $string -replace 'í','i'
 $string = $string -replace 'Í','I'
 $string = $string -replace 'É','E'
 $string = $string -replace 'é','e'
 $string = $string -replace 'Ý','Y'
 $string = $string -replace 'ý','y'
 $string = $string -replace 'Ú','U'
 $string = $string -replace 'ú','u'
 $string = $string -replace 'Ó','O'
 $string = $string -replace 'ó','o'
 $string = $string -replace 'ö','o'
 $string = $string -replace 'Ö','O'
 $string = $string -replace 'Ð','D'
 $string = $string -replace 'ð','d'
 $string = $string -replace 'Æ','Ae'
 $string = $string -replace 'æ','ae'
 $string = $string -replace 'Þ','Th'
 $string = $string -replace 'þ','th'
 $string = $string.ToLower() #Það var hér sem ég fattaði að ég hefði allteins geta sleppt stóru stöfunum.....
 #skiptir þessu niður þannig að ég geti unnið með þetta sem array og þægilegri máta til að breyta stórum stöfum í byrjun
 $string = $string.Split()
 $cache = ""
 for($i = 0; $i -lt $string.Count; $i++){
 $cache += $string[$i][0]
 $cache = $cache.ToUpper()
 $string[$i] = $string[$i].Remove(0,1)
 $string[$i] = $string[$i].ToString().Insert(0,$cache[$i])
 }
 foreach($str in $string) {
 $string2 += $str +" "#bæti einu ljótu whitespacei við sem ég fjarlægi í lokinn
 }
 $string2 = $string2.Substring(0,$string2.Length-1)

 return $string2
} #hægt að hafa þetta fyrir utan en þetta sér til þess að þetta keyrist með og er þetta notað til að skipta út ÍSL stöfunum

if($nafn[-1] -eq " ") #þessi if setning kemur í veg fyrir að ef að CSV skráin er með auka bil eftir eftirnafninu að það verði meðtekið sem eftirnafn
{
while ($nafn[-1] -eq " ")
{
$nafn = $nafn.Substring(0,$nafn.Length -1)

}


}
$samname = $null #núllstillir stöðvar, hef þetta uppá öryggið
$eftirnafn = $null
$info = @{} #skilast sem hastafla sem kallar þá bara í fornafn: eftirnafn: usernafn: eftir þvúi hvað við á
$fornafn = $null
$nafnsplit = $nafn.Split() #splitta array til að vinna með
for ($i = 0; $i -ne $nafnsplit.Length -1 ; $i++){$fornafn += $nafnsplit[$i] + " " } #þessi forlúppa byr til fornafnið
$fornafn = $fornafn.Substring(0,$fornafn.Length -1) #þessi skipun fjarlægir þetta auka bil sem ég bjó til með forloopunni
$eftirnafn = $nafnsplit[-1] #eftirnafnið er bara síðasta indexið í nafninu sem við splittuðum
$samname = replaceISL -string $nafn #bless íslenskir stafir
$samname = $samname.Replace(' ','.') #þar sem er bil er sett punktur

if($samname.Length -gt 20) #ef að þetta er lengra en þessir 20 stafir þá bara týnum við aftasta út þangað til að við erum góðir
{
while ($samname.Length -gt 20)
{
$samname = $samname.Substring(0,$samname.Length -1)
}
}
if($samname[-1] -eq '.')
{
$samname = $samname.Substring(0,$samname.Length-1)
}

$samname = $samname.ToLower() #hendum í lowercase
#setjum upplýsingarnar í hastöflu
$info.Add("fornafn:", $fornafn)
$info.Add("eftirnafn:",$eftirnafn)
$info.Add("username:",$samname) 

return $info

}
#setur þetta eftir Import-csv þetta leyfir þér að navigate-a í gegnum file explorer þarft ekki að skrifa pathið
function Import-csvfile
{
Function Get-FileName($initialDirectory)
{
    ##ætlaði að búa þetta til en fann þetta hér:
    #Var frekar basic að skilja
    [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") | Out-Null
    
    $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $OpenFileDialog.initialDirectory = $initialDirectory
    $OpenFileDialog.filter = "CSV (*.csv)| *.csv"
    $OpenFileDialog.ShowDialog() | Out-Null
    $OpenFileDialog.filename
}
$csv = Get-FileName
Import-Csv $csv -Encoding Default -Delimiter ';'

}

function NetkortogForest
{
 param(
        [Parameter(Mandatory=$true, HelpMessage="Hvað á Domainið að heita? (1/5)")] #t.d Notandi-EEP, eða 2t osfrv...
        [string]$domain,
        [Parameter(Mandatory=$true, HelpMessage="Sláðu inn heitið á netkortinu sem þú vilt nota.(2/5) Ethernet eða Ethernet 2")] #þú vilt ekki nota 2t. netið getur verið Ethernet
        [string]$gamlanetkort,
        [Parameter(Mandatory=$true, HelpMessage="Sláðu inn nýtt nafn fyrir það (3/5)")] #Má vera hvað sem er
        [string]$nyjanetkort,
        [Parameter(Mandatory=$true, HelpMessage="Sláðu inn IP töluna sem þú vilt nota (4/5)")] #Hvaða Ip tölu á serverionn að vera með
        $ipaddress,
        [Parameter(Mandatory=$true, HelpMessage="Sláðu inn prefixið á iptölunni (5/5)")] ## prefix er þða /24 eða /26 fer eftir hvað subnet maskinn er
        [int]$prefix
        
    )

    $local = ".local" 
    $domainlocal = $domain+$local; #sækir domainnafnið og bætir við .local
   



try {
Rename-NetAdapter -Name $gamlanetkort -NewName $nyjanetkort #rename-ar netkoritð
New-NetIPAddress -InterfaceAlias $nyjanetkort -IPAddress $ipaddress -PrefixLength $prefix #-DefaultGateway 192.168.1.1 notum ekki default gateway en hægt að kommenta þetta aftur inn ef þess þarf
Set-DnsClientServerAddress -InterfaceAlias $nyjanetkort -ServerAddresses 127.0.0.1 #þetta 127.0.0.1 er að setja okkur á loopback semsagt við erum okkar eigin dns þjónn

Install-WindowsFeature -Name AD-Domain-Services –IncludeManagementTools
Install-ADDSForest –DomainName $domainlocal –InstallDNS -SafeModeAdministratorPassword (ConvertTo-SecureString -AsPlainText "pass.123" -Force) 
}
catch {$error, "Vandamál kom upp" }
if (!$error) {
$wshell = New-Object -ComObject Wscript.Shell
$wshell.Popup("Aðgerð Tókst, Vél mun endurræsa sig",0,"Okei",0x1)

}
}
function SetjauppDHCPscopeogClientADomain
{
 param(
        [Parameter(Mandatory=$true, HelpMessage="Hvað á scopeið að heita? (1/7)")]
        [string]$scopename,
        [Parameter(Mandatory=$true, HelpMessage="Á hvaða IP á scopeið að byrja?(2/7)")]
        $ipstart,
        [Parameter(Mandatory=$true, HelpMessage="Á hvaða Ip á scopeið að enda? (3/7)")]
        $ipend,
        [Parameter(Mandatory=$true, HelpMessage="Hver er subnet maskinn? (4/7)")]
        $subnet,
        [Parameter(Mandatory=$true, HelpMessage="DNS server IPtala og router? (5/7)")]
        $dnsserver,
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
Install-WindowsFeature -Name Web-server -IncludeManagementTools
Add-DhcpServerv4Scope -Name $scopename -StartRange $ipstart -EndRange $ipend -SubnetMask $subnet #setur upp dhcp scope
Set-DhcpServerv4OptionValue -DnsServer $dnsserver -Router $dnsserver #oft fyrsta nothæfa ip eða síðasta
Add-DhcpServerInDC -DnsName $domain2.DNSroot #t.d. $($env:computername + “.” $env:userdnsdomain)


Add-Computer -ComputerName $client -LocalCredential $client\Administrator -DomainName $dnsname -Credential $dnsname\Administrator


if (!$error) {
$wshell = New-Object -ComObject Wscript.Shell
$wshell.Popup("Aðgerð Tókst, Vél mun endurræsa sig",0,"Okei",0x1) 
 }
 }
 function BuaTilNotendur
{
 param(
        [Parameter(Mandatory=$true, HelpMessage="Hvar viltu búa til möppurnar?(C:\)")] #Sterkur leikur að gera t.d. C:\$domainnafn eða bara vera með sérstaka möppu
        [string]$path
   
    )

   $getdomain = Get-ADDomain
   $domainname  = $getdomain.Name

New-ADOrganizationalUnit -Name Notendur -ProtectedFromAccidentalDeletion $false #Býr til OU fyrir notendurnar 
New-ADGroup -Name NotendurAllir -Path "OU=Notendur,DC=$domainname,DC=local" -GroupScope Global #býr til Security gropu sem heldur um alla notendur
#Bý til möppuna
new-item $path\sameign -ItemType Directory -Force
 
#sæki núverandi réttindi
$rettindi = Get-Acl -Path $path\sameign 
 
#bý til þau réttindi sem ég ætla að bæta við möppuna
$nyrettindi = New-Object System.Security.AccessControl.FileSystemAccessRule "$domainname\NotendurAllir","Modify","Allow"
#Hver á að fá réttindin, hvaða réttindi á viðkomandi að fá, erum við að leyfa eða banna (allow eða deny)
 
#bæti nýju réttindunum við þau sem ég sótti áðan
$rettindi.AddAccessRule($nyrettindi)
 
#Set réttindin aftur á möppuna
Set-Acl -Path $path\sameign $rettindi
 
#Share-a möppunni
New-SmbShare -Name Sameign -Path $path\sameign -FullAccess $domainname\NotendurAllir, administrators 

Add-PrinterDriver -Name "Brother Color Type3 Class Driver" #setur inn driver fyrir prentarann ef allir eru að nota sama kemur það upp sem bara 1 prentari og þarf að hægri smella á hann til að fá hina upp, svo það er hægt að harðkóða aðra driveraa inn
Add-Printer -Name "Sameign prentari2" -Location "Sameign" -Shared -PortName LPT1: -Drivername "Brother Color Type3 Class Driver" -Published  #býr til sameigna prentarann og share-ar

$notendur = Import-csvfile

foreach($n in $notendur)
{$getdomain = Get-ADDomain
   $domainname  = $getdomain.Name
    $deild = $n.Deild
    $nafnamix = Nafnareglur -nafn $n.Nafn

    if((Get-ADOrganizationalUnit -Filter { name -eq $deild }).Name -ne $deild)
    {
        New-ADOrganizationalUnit -Name $n.Deild -Path "OU=Notendur,DC=$domainname,DC=local" -ProtectedFromAccidentalDeletion $false
        New-ADGroup -Name $deild -Path $("OU=" + $deild + ",OU=Notendur,DC=$domainname,DC=local") -GroupScope Global
        Add-ADGroupMember -Identity NotendurAllir -Members $deild

        #Bý til möppuna
        new-item $path\$deild -ItemType Directory -Force
 
        #sæki núverandi réttindi
        $rettindi = Get-Acl -Path $path\$deild
 
        #bý til þau réttindi sem ég ætla að bæta við möppuna
        $nyrettindi = New-Object System.Security.AccessControl.FileSystemAccessRule $domainname\$deild,"Modify","Allow"
        #Hver á að fá réttindin, hvaða réttindi á viðkomandi að fá, erum við að leyfa eða banna (allow eða deny)
 
        #bæti nýju réttindunum við þau sem ég sótti áðan
        $rettindi.AddAccessRule($nyrettindi)
 
        #Set réttindin aftur á möppuna
        Set-Acl -Path $path\$deild $rettindi
 
        #Share-a möppunni
        New-SmbShare -Name $deild -Path $path\$deild -FullAccess $domainname\$deild, administrators 

        Add-Printer -Name $($deild + " prentari") -Location $deild -Shared -PortName LPT1: -Drivername "Brother Color Type3 Class Driver" -Published

        
    }
    #hérna er tekið fram t.d. $n.Nafn því í csv skránni er dálkur sem heitir Nafn og þá er $n.Nafn að biðja um þær upplýsingar, eins með $n.Notendanafn eða $n.Titill, þetta þarf að vera skrifað eins og í CSV skránni og ef það er ekki til í CSV skránni kemur það ekki fram eins er hægt að bæta við fleiri parametrum ef þú færð nýja skrá með fleiri upplýsingum eins og land eða þannig er hægt að gera -Country $n.Land osfrv....
    New-ADUser -Name $n.Nafn -DisplayName $n.Nafn -GivenName $nafnamix['fornafn:'] -Surname $nafnamix['eftirnafn:'] -SamAccountName $nafnamix['username:'] -UserPrincipalName $($nafnamix['username:'] + "@"+$domainname+".Local") -Path $("OU=" + $deild + ",OU=Notendur,DC=$domainname,DC=local") -AccountPassword (ConvertTo-SecureString -AsPlainText "pass.123" -Force) -Enabled $true 
    Add-ADGroupMember -Identity $deild -Members $nafnamix['username:'] #setur deildar notendurnar í viðeigandi Security grúppur
}


}

New-Item "C:\bbp\Vefir\" -ItemType Directory
New-Item "C:\bbp\Vefir\bbp\index.html" -type file -force -value "Velkominn á vefsvæði bbp!! eða ddp fer eftir hvort þú vilt"
New-WebSite -Name "bbp.is" -Port 80 -HostHeader "bbp.is" -PhysicalPath "C:\bbp\Vefir\bbp\"
New-WebBinding -Name "bbp.is" -Port 80 -HostHeader "www.bbp.is" -IPAddress * 
Add-DnsServerPrimaryZone -Name "bbp.is" -ReplicationScope Domain
Add-DnsServerResourceRecordA -ZoneName "bbp.is" -Name "bbp.is" -IPv4Address 10.201.190.220
Add-DnsServerResourceRecordA -ZoneName "bbp.is" -Name "www" -IPv4Address 10.201.190.220
ipconfig /flushdns



function AllirFaSidur
{
$master = Get-ADOrganizationalUnit -Filter {name -like "Notendur"}
$deildir = Get-ADOrganizationalUnit -SearchBase $master -Filter *
foreach($d in $deildir)
{
$webname = replaceISL -string $d.Name
$pathname = "C:\bbp\Vefir\" + $d.Name
$name = $d.Name
$zonename = "$webname.bbp.is"
$wzonename = "www.$webname.bbp.is"
New-Item $pathname -ItemType Directory -Force
New-Item "$pathname\index.html" -type file -force -value "Velkominn á vefsvæði fyrir $name" 
New-WebSite -Name "$webname.bbp.is" -HostHeader "$webname.bbp.is" -PhysicalPath $pathname
New-WebBinding -Name "$webname.bbp.is" -IPAddress * -HostHeader "www.$webname.bbp.is"
Add-DnsServerPrimaryZone -Name "$webname.bbp.is" -ReplicationScope domain
Add-DnsServerResourceRecordA -ZoneName "$zonename" -Name "www" -IPv4Address 10.201.190.220
Add-DnsServerResourceRecordA -ZoneName "$zonename" -Name "$zonename" -IPv4Address 10.201.190.220

}
ipconfig /flushdns

}
