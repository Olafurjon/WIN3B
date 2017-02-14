
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
} # Skriptan til að búa til nöfn án Íslenska stafi, tengist liðnum með usernameið


function BuaTilGPO #Búa til GPO með powershell
{
 param( 
 [Parameter(Mandatory=$true)]
 $oudistname,
 [Parameter(Mandatory=$true)]
 $GPOname
 )
import-module GroupPolicy
$gpo = $GPOname
New-GPO $gpo
New-GPLink -Target $oudistname -Order 1 -Name $GPOname
return $gpo
}

#Fyrsti liður 
New-NetIPAddress -InterfaceAlias "Boom" -IPAddress 172.16.24.1 -PrefixLength 21 #-DefaultGateway 192.168.1.1 notum ekki default gateway
Remove-NetIPAddress -InterfaceAlias "Boom" -IpAddress 192.168.0.1
Set-DnsClientServerAddress -InterfaceAlias "Boom" -ServerAddresses 127.0.0.1 
#
$domain2 = Get-ADDomain
$local = $domain2.DNSroot
$domainname = $domain2.name
$dnsname = $domainname+".local"
Add-DhcpServerv4Scope -Name newscope -StartRange 172.16.24.1 -EndRange 172.16.30.64 -SubnetMask 255.255.248.0
Set-DhcpServerv4OptionValue -DnsServer 172.16.24.1 -Router 172.16.24.1
Add-DhcpServerInDC -DnsName $domain2.DNSroot #t.d. $($env:computername + “.” $env:userdnsdomain)
#vélin var núeþgar á domaini svo ég þarf þetta ekki
#Add-Computer -ComputerName WIN3B-W81-07 -LocalCredential WIN3B-W81-07\Administrator -DomainName $domainname -Credential EEP-Olafur.local\Administrator
$w81 = Get-ADComputer -Filter {name -like "Win3b-w81-07"} 
Set-Service winrm -Status Running -PassThru -ComputerName 10.201.190.205
$env:Path += ";C:\Windows\System32\PSTools" #Sótti pstools til að einfalda lífið, hér er ég að segja hvar pathið er svo það sé hægt að nota það /slóð https://technet.microsoft.com/en-us/sysinternals/bb896649.Aspx
psexec \\WIN3B-W81-07\ ipconfig /renew   #hægt að nota þetta til að endurnýja IP töluna
Get-ADComputer -Filter {name -like "Win3b-w81-07"} | Invoke-Command  -ScriptBlock {"ipconfig /release"} -Credential EEP-Olafur.local\Administrator #einnig þetta með viðgeigandi GP stillingar
$gp = BuaTilGPO -oudistname "OU=Tolvur,OU=Notendur,DC=EEP-Olafur,DC=local" -GPOname "gpoTolvur"

 function BuaTilNotendur #Sér um að búa til notendurnar og allt annað er dekkað hér held ég
{

$path = "C:\EEP"
   $getdomain = Get-ADDomain
   $domainname  = $getdomain.Name

New-ADOrganizationalUnit -Name Notendur -ProtectedFromAccidentalDeletion $false
New-ADGroup -Name NotendurAllir -Path "OU=Notendur,DC=$domainname,DC=local" -GroupScope Global
New-ADOrganizationalUnit -Name Tolvur -Path "OU=Notendur,DC=$domainname,DC=local" -ProtectedFromAccidentalDeletion $false
$tolvuou = Get-ADOrganizationalUnit -Filter {name -like "Tolvur"}
$w81vel = Get-ADComputer -Filter {Name -like "*W81*"}
$w81vel | Move-ADObject -TargetPath $tolvuou.DistinguishedName
#Bý til möppuna
new-item $path\Sameign -ItemType Directory -Force
new-item $path\Homedir -ItemType Directory -Force #Stofna Homedir fyrir user home folder
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
New-SmbShare -Name Homedir -Path $path\Homedir -FullAccess $domainname\NotendurAllir, administrators #sharing is caring

Add-PrinterDriver -Name "Brother Color Type3 Class Driver"
Add-Printer -Name "Sameign prentari2" -Location "Sameign" -Shared -PortName LPT1: -Drivername "Brother Color Type3 Class Driver" -Published 
$notendur = Import-Csv "C:\Users\Administrator\OneDrive\Tskoli2017\WIN3B3U\Verkefni 2\v2notendur_u.csv" -Encoding UTF8


foreach($n in $notendur)
{


$getdomain = Get-ADDomain
   $domainname  = $getdomain.Name
    $Deild = $n.Deild
    $Skrifstofa = $n.Skrifstofa
    
    $Deild
    $Skrifstofa

       if((Get-ADOrganizationalUnit -Filter { name -eq $Skrifstofa }).name -ne $Skrifstofa) #ef það er ekki til Skrifstofuou bý ég það til
        {
            
            New-ADOrganizationalUnit -Name $Skrifstofa -Path "OU=Notendur,DC=$domainname,DC=local" -ProtectedFromAccidentalDeletion $false #þá er það komið
            $skrifstofupath = Get-ADOrganizationalUnit -Filter { name -eq $Skrifstofa }
            $skrifstofupath = $skrifstofupath.DistinguishedName
            New-ADGroup -Name $Skrifstofa -Path "OU=$Skrifstofa,OU=Notendur,DC=$domainname,DC=local" -GroupScope Global
            #Bý til möppuna
            new-item $path\$Skrifstofa -ItemType Directory
 
            #sæki núverandi réttindi
            $rettindi = Get-Acl -Path $path\$Skrifstofa
 
            #bý til þau réttindi sem ég ætla að bæta við möppuna
            $nyrettindi = New-Object System.Security.AccessControl.FileSystemAccessRule $domainname\$Skrifstofa,"Modify","Allow"
            #Hver á að fá réttindin, hvaða réttindi á viðkomandi að fá, erum við að leyfa eða banna (allow eða deny)
 
            #bæti nýju réttindunum við þau sem ég sótti áðan
            $rettindi.AddAccessRule($nyrettindi)
 
            #Set réttindin aftur á möppuna
            Set-Acl -Path $path\$Skrifstofa $rettindi
 
            #Share-a möppunni
            New-SmbShare -Name $Skrifstofa -Path $path\$Skrifstofa -FullAccess $domainname\$Skrifstofa, administrators 

            Add-Printer -Name $($Skrifstofa + " prentari") -Location $Skrifstofa -Shared -PortName LPT1: -Drivername "Brother Color Type3 Class Driver" -Published
        } 

            if((Get-ADOrganizationalUnit -SearchBase "OU=$Skrifstofa,OU=Notendur,DC=$domainname,DC=Local" -Filter {name -like $Deild}).Name -ne $Deild) #ef Deild er ekki til í OU sem heitir skrifstofunafni þá búum við það til
            {
            $group = $Skrifstofa+$Deild #ekki var hægt að hafa group með sama nafni þrátt fyrir að það væri í sitthvoru OU svo þetta var lausnin mín
            $skrifstofupath = Get-ADOrganizationalUnit -Filter { name -eq $Skrifstofa }
            $skrifstofupath = $skrifstofupath.DistinguishedName
            New-ADOrganizationalUnit -Name $Deild -Path "OU=$Skrifstofa,OU=Notendur,DC=$domainname,DC=local" -ProtectedFromAccidentalDeletion $false #Búið til Deildinu undir OU skrifstofunni sem er undir OU Notendur
            
            New-ADGroup -Name $group -Path "OU=$Deild,OU=$Skrifstofa,OU=Notendur,DC=$domainname,DC=local" -GroupScope Global #Búið til security groupuna og staðsett í viðeigandi deild
            Add-ADGroupMember -Identity NotendurAllir -Members $Skrifstofa #skrifstofan sett í Notendur allir
            Add-ADGroupMember -Identity $Skrifstofa -Members $group #og grouppan sett í skrifstofu grouppið

            

        
        }
        
  
    $Deild = $n.Deild
    $nafn = $n.Nafn.Split() #vinnur úr nafninu yfir í array
    $kt = $n.Kennitala
    $usernafn = $nafn[0]+$nafn[1].Substring(0,1)+$kt.Substring(7) #Bý hér til notendanafnið samansett úr fornafni og fyrsta staf í milli/eftirnafni og stöfum í kt, ætlaði ekki að vera með þetta svona leiðinlega langt en það fyndna var fólk er greinilega með rosa lík nöfn og kt ef ég notaði bara fornafn og öftustu 4-1 staf í kt þá kom duplicate error...
    $givenname = $nafn[0]
    $surname = $nafn[1]+" "+$nafn[2]
    $usernafn = replaceISL $usernafn #Lætur replaceISL functionið losa alla íslensku stafi úr ef þeir eru tilstaðar

    
    New-ADUser -Name $n.Nafn -DisplayName $n.Nafn -GivenName $givenname -Surname $surname -SamAccountName $usernafn -UserPrincipalName $($usernafn + "@eep.is") -EmailAddress $($usernafn + "@ddp.is") -Path "OU=$Deild,OU=$Skrifstofa,OU=Notendur,DC=$domainname,DC=local" -AccountPassword (ConvertTo-SecureString -AsPlainText "pass.123" -Force) -Enabled $true -Country "IS" -EmployeeNumber $n.Starfsmannanr -Department $Deild -State $n.Sveitarfelag -Title $n.Titill -StreetAddress $n.Heimilisfang -HomeDrive "H" -HomeDirectory "\\WIN3B-07\Homedir\$usernafn" #hérna í lokinn er græjað homedir partinn
    Get-ADGroup -Filter {name -like $group} | Add-ADGroupMember -Members $usernafn
    
}

}


#aukadót 
Get-ADComputer -Filter {name -like "*W81*"} | Move-ADObject -TargetPath "CN=Computers,DC=EEP-Olafur,DC=local" #þegar ég var að debugga var þetta bara notað til að færa vél úr tolvur ou í computers ou
#eyddi óvart W81 tölvunni en fann síðan hvernig það var hægt að kalla í hana aftur
Get-ADObject -Filter {Deleted -eq $True -and Name -like "*W81*" -and ObjectClass -eq "Computer"} -IncludeDeletedObjects | Restore-ADObject -NewName "WIN3B-W81-07" -TargetPath "CN=Computers,DC=EEP-Olafur,DC=local"




