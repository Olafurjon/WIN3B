#Það var smávægileg villa í csv skránni sem þið fenguð, þeir sem voru skráðir í Tæknideild á
#Akureyri áttu að vera skráðir í Tæknideild í Kópavogi og þeir sem voru skráðir í Tæknideildina í
#Kópavogi áttu að vera í Tæknideildinni á Akureyri. Þið þurfið að leiðrétta þetta gagnvart OU-um,
#hópum og starfsmannanúmerum

function switchadeildum #hægt væri að implementa breytur svo að deildir væru ekki harðkóðaðar inn, en til að sýna hvernig virkar er kommentað inni
{
Import-Module ActiveDirectory
$AK = Get-ADOrganizationalUnit -Filter {name -like "Akureyri"} #finna og einangra AK OU
$AKtaeknideild = Get-ADOrganizationalUnit -SearchBase $AK -Filter {name -like "Tæknideild"} -Properties * #finna og einangra tæknideildina inní AK 
$AKCache = Get-ADUser -SearchBase $AKtaeknideild -Filter * #Sækja alla usera og setja í cache
$AKgroup= Get-ADGroup -SearchBase $AKtaeknideild -Filter {name -like "*tæknideild*"} #sækir AK grúppuna
$AKGroupmembers =  $AKgroup | Get-ADGroupMember

$KOP = Get-ADOrganizationalUnit -Filter {name -like "Kópavögur"} #endurtekið það sem er fyrir ofan nema með nýrri deild
$KOPtaeknideild = Get-ADOrganizationalUnit -SearchBase $KOP -Filter {name -like "Tæknideild"} -Properties *
$KopCache = Get-ADUser -SearchBase $KOPtaeknideild -Filter *
$KOPgroup= Get-ADGroup -SearchBase $KOPtaeknideild -Filter {name -like "*tæknideild*"}
$KOPgroupmembers = $KOPgroup | Get-ADGroupMember

foreach ($A in $AKGroupmembers) #Foreach lykkjur til að losa okkur við þessa úr grúppunum
{
Remove-ADGroupMember -Identity $AKgroup -Members $A.SamAccountName #
}

foreach ($K in $KOPgroupmembers) #sama og að ofan nema með Kóp
{
Remove-ADGroupMember -Identity $KOPgroup -Members $K.SamAccountName 
}

foreach($Akuser in $AKCache) #vinnur úr AK notendunum og gefur þeim ný employee númer og færir þá í veiðeigandi grúppu og OU
{
$empnumb = $Akuser.EmployeeNumber;  
$empnumb = $empnumb -replace 'Ak','Kó' #skiptir út employeenumber sem var t.d. AkSala2 í KóSala2
$Akuser.EmployeeNumber = $empnumb #virkaði ekki? / Virkar núna það er víst ekki í lagi að nota " frekar nota '
$Akuser | Move-ADObject -TargetPath $KOPtaeknideild
Add-ADGroupMember -Identity $KOPgroup -Members $Akuser
}

foreach($Kopuser in $KopCache) #sama og að ofan nema öfugt
{
$empnumb = $Kopuser.EmployeeNumber;
$empnumb = $empnumb -replace 'Kó','A'
$Kopuser.EmployeeNumber = $empnumb
$Kopuser | Move-ADObject -TargetPath $AKtaeknideild
Add-ADGroupMember -Identity $AKgroup -Members $Kopuser
}

$AKtaeknideild = Get-ADOrganizationalUnit -SearchBase $AK -Filter {name -like "Tæknideild"} -Properties * #finna og einangra tæknideildina inní AK 
$newAk = Get-ADUser -SearchBase $AKtaeknideild -Filter * -Properties * #Sækja alla usera og setja í cache

$KOPtaeknideild = Get-ADOrganizationalUnit -SearchBase $KOP -Filter {name -like "Tæknideild"} -Properties *
$newKop = Get-ADUser -SearchBase $KOPtaeknideild -Filter * -Properties *

foreach($new in $newAk) #Notaðist því hitt var að stríða því ég var með " en ekki ' en hitt virkar eins og það er en skil þetta eftir hér að gamni...
{
$new.EmployeeNumber = $new.EmployeeNumber -replace 'Kó','Ak'
$new.EmployeeNumber
}

foreach($new in $newKop)
{
$new.EmployeeNumber = $new.EmployeeNumber -replace 'Ak','Kó'
$new.EmployeeNumber
}



}
#Búið til hópa (e. group) fyrir alla sem eru í sömu deild en á mismunandi skrifstofum. Það eru til
#dæmis tölvudeildir á Ísafirði og í Reykjavík, við viljum fá nýjan hóp sem heitir AllarTölvudeildir og
#inniheldur hópana úr tölvudeildunum á Ísafirði og Reykjavík.

function EveryBodyGetsAGroup #býr til Allar deildir fyrir sameignileg svið og bætir við réttu fólki í réttar deildir
{
$masterou = Get-ADOrganizationalUnit -Filter {name -like "Notendur"} #Master ou hérna er aðal OU með það hér fyrir aukin þægindi
$groupstobe = Get-ADOrganizationalUnit -SearchBase $masterou -filter {name -notlike "Notendur"} ##þessi sér um að finna hvern einasta grúp og mun vinna úr þeim til að búa til viðeigandi deildir 

$groups = @()
$gruppa = ""


foreach ($g in $groupstobe) #hjólar í gegnum nöfnin á OU sem eru til 
{

$gname = Get-ADOrganizationalUnit -SearchBase $g -Properties name -filter *
$groups += $gname.name #bætir í grúps því í raun þarf ég bara að vinna með nöfnin á þessu


}

$groups = $groups | select -Unique #það eru til nokkrar ***tæknideild*** undir t.d. RVKtæknideild og þannig svo þar sem ég er bara vinna með einn overall group nota ég unique til að finna bara 1 nafn af hverju


foreach($g in $groups)
{
if(((Get-ADGroup -Filter{name -eq $g}).name -ne $g) -and $g -ne "Tolvur") #smá dirty hérna með Tolvur... 
{

$nafndeildar = "Allar$g" + "ir" #Verkefnið vildi að þetta hét AllarXir svo svona geri ég það
$name = "*$g*" #vildi ekki virka nema ég útfærði þetta svona
$members =  Get-ADGroup -SearchBase $masterou -Filter {name -like $name} ##grípur deildirnar sem innihalda þá tæknideild,mannauðsdeild etc til að færa yfir í grúppuna
New-ADGroup -Name $nafndeildar -Path $masterou.DistinguishedName -GroupScope Global 
$gruppa = Get-ADGroup -Filter {name -like $nafndeildar} #var með þetta pipelineað en það var að skila villum, en þetta virkaði svona síðan
Add-ADGroupMember -Identity $gruppa -Members $members
"Grúppa " + $nafndeildar + " Stofnuð"

}

}


}
#Mannauðsdeildin á Egilsstöðum sér um notendaumsjón. Þið þurfið að gefa þeim réttindi til þess
#(e. delegation) (þarf ekki að leysa með Powershell). Þið þurfið svo að skrifa lítið GUI forrit í
#Powershell fyrir þá þar sem þeir geta fundið notendur eftir nafni, breytt lykilorðum og
#disable/enable notendur.

function GUI #Notast er við gögn guið sem kennarinn útveigaði ásamt breytum
{
#Hleð inn klösum fyrir GUI, svipað og References í C#
[System.Reflection.Assembly]::LoadWithPartialName("System.Drawing") 
[System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")

#Breytan notendur er hashtafla sem heldur utan um alla notendur sem finnast, 
#breytan þarf að vera "global" innan skriptunnar
$Script:notendur = @{} 
$Script:BoxInfo = @() #! Bætti við global array sem meðhöndlar dynamic tb generatorinn

##kóðinn að neðan keyrir textbox inní boxinfo arrayin í for slaufu    
    $x = 80
    $y = 160
    for ($i = 0; $i -le 4; $i++){
    $box = New-Object System.Windows.Forms.TextBox
    $box.Location = New-Object System.Drawing.Point($x,$y)
    $box.Size = New-Object System.Drawing.Size(210,30)
    $box.Text = $info
    $box.Enabled = $false
    $box.BringToFront() = $true
    $Script:BoxInfo += $box
    $y += 30
   

}


# ef að notandi er enabled þá disablear þetta hann ef hann er disabled þá enable-ar þetta hann
function changeActiveStatus {
param(
[Parameter(Mandatory)]
$user
)
try {
$aduser = Get-ADUser $user
if ($aduser.Enabled -eq $True)
{
$aduser | Set-ADUser -Enabled $False
$wshell = New-Object -ComObject Wscript.Shell

$wshell.Popup($aduser.SamAccountName + " Disabled",0,"Enable/Disable")
}
else
{
$aduser | Set-ADUser -Enabled $True
$wshell = New-Object -ComObject Wscript.Shell

$wshell.Popup($aduser.SamAccountName + " Enabled",0,"Enable/Disable")
}
}
catch{
$wshell = New-Object -ComObject Wscript.Shell

$wshell.Popup("Aðgerð gekk ekki, hafðu samband við Administrator" ,0,"Enable/Disable Error")
}


}
# endurstillir passwordið í pass.123
function ResetPassword {
param(
[Parameter(Mandatory)]
$user
)
try {
$aduser = Get-ADUser $user -Properties *
$aduser.SamAccountName | Set-ADAccountPassword -NewPassword (ConvertTo-SecureString -AsPlainText "pass.123" -Force)
$wshell = New-Object -ComObject Wscript.Shell

$wshell.Popup("Password reset at: " + $aduser.SamAccountName ,0,"Password Reset")
}
catch{
$wshell = New-Object -ComObject Wscript.Shell

$wshell.Popup("Aðgerð gekk ekki, hafðu samband við Administrator" ,0,"Password Reset")
}



}
# er ekki að nota þetta þar sem það var ekki nauðsynjað, ef ég hef tíma þá mun ég setja þetta inn og láta koma popup sem biður um nýtt password
function ChangePassword {
param(
[Parameter(Mandatory)]
$user,
[Parametur(Mandatory)]
$pass
)
$aduser = Get-ADUser $user -Properties *
$aduser.SamAccountName | Set-ADAccountPassword -NewPassword (ConvertTo-SecureString -AsPlainText $pass -Force)



}
#notar Boxinfo arrayin til að skila upplýsinunum í boxin
function birtaInfo{
param(
[parameter(Mandatory)]
$activeuser
)



$user  = Get-ADUser $activeuser -Properties Name, Enabled, SamAccountName, Distinguishedname
$name = $user.Name
$enabled = $user.Enabled
$username = $user.samaccountname
$dn = $user.distinguishedname
$dn = $dn.Split(',')
$city = $dn[2].Substring(3)
$depart = $dn[1].Substring(3)
$userinfo = ($name,$enabled,$username,$city,$depart)

$i = 0
$x = 80
$y = 161
foreach($box in $Script:BoxInfo)
{

$lbl = New-Object System.Windows.Forms.Label

$lbl.Location = New-Object System.Drawing.Point(20,$y)
$lbl.Size = New-Object System.Drawing.Size(60,30)
#ég veit að þetta er megaljót forritun en nennti ekki að implimenta þetta á annan hátt... ekki dæma mig
if($i -eq 0){
$lbl.Text = "Nafn:"
}
if($i -eq 1){
$lbl.Text = "Enabled:"
}
if($i -eq 2){
$lbl.Text = "Username:"
}
if($i -eq 3){
$lbl.Text = "Staður:"
}
if($i -eq 4){
$lbl.Text = "Deild:"
}
#Set label-inn á formið
$frmLeita.Controls.Add($lbl)



$box.text = $userinfo[$i]
$frmleita.Controls.Add($box)
$y+= 30
$i++
}


}


#Fall sem sér um að leita að notendum og skilar niðurstöðunni í ListBox-ið
function LeitaAdNotendum  {
    $lstNidurstodur.Items.Clear() 
    #útbý leitarstrenginn set * sitthvoru megin við það sem er í textaboxinu
    $leitarstrengur = "*" + $txtLeita.Text + "*"
    #finn alla notendur þar sem leitarstrengurinn kemur fram í nafninu, tek nafnið
    #og samaccountname, nafnið birti ég en nota svo samaccount til að fá frekari
    #upplýsingar um notanda sem valinn er. Set þetta í global notendur breytuna
    $Script:notendur = Get-ADUser -Filter { name -like $leitarstrengur } | select name, samaccountname
    #set svo niðurstöðurnar í listboxið
    foreach($notandi in $Script:notendur) {
        $lstNidurstodur.Items.Add($notandi.name)
    }
}

#fall sem keyrir þegar eitthvað er valið úr listboxinu
function NotandiValinn {
    #TODO hér væri einhver virkni sem keyrði þegar notandi er valinn í listbox-inu
    Write-Host $Script:notendur[$lstNidurstodur.SelectedIndex].samaccountname
    $userinfo = birtaInfo -activeuser  $Script:notendur[$lstNidurstodur.SelectedIndex].samaccountname

}

#Aðalglugginn 
#Bý til tilvik af Form úr Windows Forms
$frmLeita = New-Object System.Windows.Forms.Form
#Set stærðina á forminu
$frmLeita.ClientSize = New-Object System.Drawing.Size(410,320)
#Set titil á formið
$frmLeita.Text = "Leita að notendum"

#Leita takkinn
#Bý til tilvik af Button
$btnLeita = New-Object System.Windows.Forms.Button
#Set staðsetningu á takkanum
$btnLeita.Location = New-Object System.Drawing.Point(300,25)
#Set stærðina á takkanum
$btnLeita.Size = New-Object System.Drawing.Size(95,30)
#Set texta á takkann
$btnLeita.Text = "Leita"
#Bý til event sem keyrir þegar smellt er á takkann. Þegar smellt er á takkan á að kalla í fallið LeitaAdNotendum
$btnLeita.add_Click({ LeitaAdNotendum })
#Sett takkann á formið
$frmLeita.Controls.Add($btnLeita)

#Skiptir á milli enabled/disabled
#Bý til tilvik af Button
$btnLeita = New-Object System.Windows.Forms.Button
#Set staðsetningu á takkanum
$btnLeita.Location = New-Object System.Drawing.Point(300,55)
#Set stærðina á takkanum
$btnLeita.Size = New-Object System.Drawing.Size(95,30)
#Set texta á takkann
$btnLeita.Text = "Enable/Disable"
#Bý til event sem keyrir þegar smellt er á takkann. Þegar smellt er á takkan á að kalla í fallið LeitaAdNotendum
$btnLeita.add_Click({ changeActiveStatus -user $Script:notendur[$lstNidurstodur.SelectedIndex].samaccountname; birtaInfo -activeuser $Script:notendur[$lstNidurstodur.SelectedIndex].samaccountname })
#Sett takkann á formið
$frmLeita.Controls.Add($btnLeita)

#Skiptir á milli enabled/disabled
#Bý til tilvik af Button
$btnLeita = New-Object System.Windows.Forms.Button
#Set staðsetningu á takkanum
$btnLeita.Location = New-Object System.Drawing.Point(300,85)
#Set stærðina á takkanum
$btnLeita.Size = New-Object System.Drawing.Size(95,30)
#Set texta á takkann
$btnLeita.Text = "Reset Password"
#Bý til event sem keyrir þegar smellt er á takkann. Þegar smellt er á takkan á að kalla í fallið LeitaAdNotendum
$btnLeita.add_Click({ ResetPassword -user $Script:notendur[$lstNidurstodur.SelectedIndex].samaccountname })
#Sett takkann á formið
$frmLeita.Controls.Add($btnLeita)


#Label Nafn:
#Bý til tilvik af Label
$lblNafn = New-Object System.Windows.Forms.Label
#Set staðsetningu á label-inn
$lblNafn.Location = New-Object System.Drawing.Point(30,30)
#Set stærðina
$lblNafn.Size = New-Object System.Drawing.Size(50,20)
#Set texta á 
$lblNafn.Text = "Nafn:"
#Set label-inn á formið
$frmLeita.Controls.Add($lblNafn)

#Textabox fyrir leitarskilyrðin
#Bý til tilvik af TextBox
$txtLeita = New-Object System.Windows.Forms.TextBox
#Set staðsetninguna
$txtLeita.Location = New-Object System.Drawing.Point(80,30)
#Set stærðina
$txtLeita.Size = New-Object System.Drawing.Size(210,30)
#Set textboxið á formið
$frmLeita.Controls.Add($txtLeita)

#Listbox fyrir leitarniðurstöður
#Bý til tilvik af ListBox
$lstNidurstodur = New-Object System.Windows.Forms.ListBox
#Set staðsetningu
$lstNidurstodur.Location = New-Object System.Drawing.Point(80,60)
#Set stærðina
$lstNidurstodur.Size = New-Object System.Drawing.Size(210,100)
#Bý til event sem keyrir þegar eitthvað er valið í listboxinu, kalla þá í fallið NotandiValinn
$lstNidurstodur.add_SelectedIndexChanged( {  NotandiValinn; } )
#Set listboxið á formið
$frmLeita.Controls.Add($lstNidurstodur)

#Birti formið
$frmLeita.ShowDialog()

}



