Set-ExecutionPolicy unrestricted
#get-service winrm -ComputerName Win3b-w81-07 
#set-Service winrm -ComputerName WIN3B-W81-07 -Status running
#Invoke-Command -ComputerName Win3b-w81-07 -ScriptBlock {ipconfig}
#Enable-PSRemoting -Force
#winrm s winrm/config/client '@{TrustedHosts="WIN3B-W81-07"}'
#winrm quickconfig
#Restart-Service WinRM
#Get-Service winrm


function userexists{
param(
[parameter(Mandatory = $true)]
$username
)
$ou  =Get-ADOrganizationalUnit -Filter {name -like "*Notendur*"} 
$users = Get-ADUser -Filter * -SearchBase $ou | Get-ADUser -Properties * | select samaccountname

foreach($user in $users)
{
    if($user -notmatch $username)
    {
    }
    else
    {
    $exists = $true
    }
}

if($exists -eq $false)
{
    Write-Host "ekki til"
    return $username
}
else
{
$i = 1
while($exists -ne $false)
{
    if($username.Length -lt 20)
    {
    $username += $i
    }
    else
    {
    Write-Host "laga nafn"
        if($i -lt 10)
        {
        $username = $username.Substring(0,$username.Length -1)
        $username += $i
        }
        else
        {
        $username = $username.Substring(0,$username.Length -2)
        $username += $i
        }
    Write-Host $username
    
    }
    foreach($user in $users)
    {
    if($user -match $username)
    {
    Write-Host "match"
    }
    else
    {
    $exists = $false

    }

    }
$i++
}

}

return $username
}

function Nafnareglur{
param(
[parameter(Mandatory = $true)]
$nafn
)#tekur inn fullt nafn sem parameter


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

# $samname = userexists -username $samname



$samname = $samname.ToLower() #hendum í lowercase
#setjum upplýsingarnar í hastöflu
$info.Add("fornafn:", $fornafn)
$info.Add("eftirnafn:",$eftirnafn)
$info.Add("username:",$samname) 

return $info

} #þessi fylgir nafnareglunum og var bætt við aðferð að ef að svo ólíklega vill til að notendanafn sé til þá fjarlægir það aftasta stafinn og bætir við
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
} #þetta notað til að skipta út ÍSL stöfunum
function stofnaNotenda{
param(
[Parameter(Mandatory)]
$name,
[Parameter(Mandatory)]
$deild
)


$getdomain = Get-ADDomain
$domainname  = $getdomain.Name
$nafnamix = Nafnareglur $name

Write-Host $nafnamix['username:'] "stofna"
New-ADUser -Name $name -DisplayName $name -GivenName $nafnamix['fornafn:'] -Surname $nafnamix['eftirnafn:'] -SamAccountName $nafnamix['username:'] -UserPrincipalName $($nafnamix['username:'] + "@"+$domainname+".Local") -Path $("OU=" + $deild + ",OU=Notendur,DC=$domainname,DC=local") -AccountPassword (ConvertTo-SecureString -AsPlainText "pass.123" -Force) -Enabled $true -ChangePasswordAtLogon $true
Add-ADGroupMember -Identity $deild -Members $nafnamix['username:'] #setur deildar notendurnar í viðeigandi Security grúppur

}
function sidafyrirnotenda{
param(
[Parameter(Mandatory)]
$name,
[Parameter(Mandatory)]
$vefslod
)
if (Get-Command replaceISL -ErrorAction SilentlyContinue)
{
$webname = replaceISL -string $vefslod
$pathname = "\\WIN3B-07\Vefir\" + $vefslod
$zonename = "$webname.bbp.is"
$wzonename = "www.$webname.bbp.is"
New-Item $pathname -ItemType Directory -Force
New-Item "$pathname\index.html" -type file -force -value "Velkominn á vefsvæði fyrir $name <br> Slóðin er: $zonename" 
New-WebSite -Name "$webname.bbp.is" -HostHeader "$webname.bbp.is" -PhysicalPath $pathname -Port 80 
#New-WebBinding -Name "$webname.bbp.is" -IPAddress * -HostHeader "www.$webname.bbp.is"
Add-DnsServerPrimaryZone -Name "$webname.bbp.is" -ReplicationScope Domain -ComputerName 10.201.190.220
#Add-DnsServerResourceRecordA -ZoneName "$zonename" -Name "www" -IPv4Address 10.201.190.220
Add-DnsServerResourceRecordA -ZoneName "$zonename" -Name "$zonename" -IPv4Address 10.201.190.220 -ComputerName 10.201.190.220

ipconfig /flushdns

}
else{
$wshell = New-Object -ComObject Wscript.Shell

$wshell.Popup("Það vantar replaceISL functionið, keyrðu það fyrst")
}


}
function Synaou{

$master = Get-ADOrganizationalUnit -Filter {name -like "notendur"}
$Script:ou = Get-ADOrganizationalUnit -SearchScope OneLevel -SearchBase $master -Filter *
foreach($o in $Script:ou)
{
if($o.Name -ne "Tölvur"){
$listb.Items.add($o.Name)
}

}

}
function villapopup{
param(
[Parameter(Mandatory)]
$message

)
$wshell = New-Object -ComObject Wscript.Shell

$wshell.Popup($message)}
#býr til label með staðsettum texta og staðsetningu
function labelmaker{
param(
[Parameter(Mandatory)]
$text,
[Parameter(Mandatory)]
$location
)

$label = New-Object System.Windows.Forms.Label
$label.Text = $text
$label.Location = New-Object System.Drawing.Size($location[0],$location[1])
return $label


}
#Býr til textbox með stærð og staðsetningu
function tbmaker{
param(
[Parameter(Mandatory)]
$size,
[Parameter(Mandatory)]
$location
)

$textbox = New-Object System.Windows.Forms.TextBox
$textbox.Size = New-Object System.Drawing.Size($size[0],$size[1])
$textbox.Location = New-Object System.Drawing.Size($location[0],$location[1])
return $textbox

}

function mannaudsdeildargui{
import-Module webadministration
[System.Reflection.Assembly]::LoadWithPartialName("System.Drawing") 
[System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")


$controls = @()
#checkboxið
$chkboxv = New-Object System.Windows.Forms.CheckBox
$chkboxv.size = New-Object System.Drawing.Size(51,17)
$chkboxv.Location = New-Object System.Drawing.Size(72,75)
$controls += $chkboxv


#græja mainformið sem heldur utan um þetta
$mainform = New-Object System.Windows.Forms.Form
#Græja stærðina
$mainform.ClientSize = New-Object System.Drawing.Size(388,212)
$mainform.Text = "Mannauðsdeild"


$tbnafn = tbmaker -size (100,20) -location (72,15)
$controls+= $tbnafn
$tbslod = tbmaker -size (100,20) -location (72,41)
$controls+= $tbslod



$lblnafn = labelmaker -text "Nafn" -location (17,18)
$controls += $lblnafn
$lblslod = labelmaker -text "Slóð" -location (17,44)
$controls+= $lblslod
$lblvefur = labelmaker -text "Vefsíða" -location (17,76)
$controls += $lblvefur


#buttoninn
$btn = new-Object System.Windows.Forms.Button
$btn.Text = "Stofna Notanda"
$btn.Location = New-Object System.Drawing.Size(72,98)
$btn.Size = New-Object System.Drawing.Size(100,35)
$controls += $btn

#listboxið
$listb = New-Object System.Windows.Forms.ListBox
$listb.Location = New-Object System.Drawing.Size(211,12)
$controls += $listb



foreach($c in $controls)
{
$mainform.Controls.Add($c)
}
Synaou
$btn.Add_Click({
$usercreated = $false
$websitecreated =$false
if($tbnafn.Text -eq "" -or $tbnafn.Text.Split() -le 2)
{
villapopup -message "Reitir mega ekki vera tómir og nafn verður að vera fullt nafn"
}


elseif($chkboxv.Checked -and $tbslod.Text -eq "")
{
villapopup -message "Slóð má ekki vera tóm"
}
elseif($listb.SelectedIndex -eq -1)
{
villapopup -message "Vinsamlega veldu OU til að setja notenda í"
}
else{
$newname = $tbnafn.Text
$newweb = $tbslod.Text
$deild = $Script:ou[$listb.SelectedIndex].name

$a = new-object -comobject wscript.shell
if($chkboxv.Checked){ $svar = $a.popup("Notandi: $newname Deild: $deild Vefslóð: $newweb.bbp.is", `
0,"Staðfesta",4)}
else{$svar = $a.popup("Notandi: $newname Deild: $deild ?", `
0,"Staðfesta",4)}

If ($svar -eq 6) {
$Error.Clear()
try{

stofnaNotenda -name $newname -deild $deild
$Error.Clear()
$usercreated = $true
$newusername = get-aduser -Filter {name -like $newname} -Properties samaccountname,name
if($chkboxv.Checked -and $usercreated -eq $true)
{
sidafyrirnotenda -name $newname -vefslod $newweb
}

if($newusername[-1].SamAccountName -eq $null)
{
$message = $newusername.SamAccountName
}
else
{
$message = $newusername[-1].SamAccountName
}

  $a.popup("Það tókst,notendanafnið er: " + $message)
}
catch{
villapopup -message "Skráning notanda $newname mistókst"
write-host $Error

}
} else {
  $a.popup("Þú hættir við")
  write-host $Error
}

}

}

)
$mainform.ShowDialog()

}
mannaudsdeildargui

