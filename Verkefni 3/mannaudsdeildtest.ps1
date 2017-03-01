
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
$error.Clear()
try {
if(!$error){
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
}
catch{$error}
if($error){
$wshell = New-Object -ComObject Wscript.Shell

$wshell.Popup("Aðgerð gekk ekki, hafðu samband við Administrator" ,0,"Password Reset")
}


}
# endurstillir passwordið í pass.123
function ResetPassword {
param(
[Parameter(Mandatory)]
$user
)
try {
if(!$error){
$aduser = Get-ADUser $user -Properties *
$aduser.SamAccountName | Set-ADAccountPassword -NewPassword (ConvertTo-SecureString -AsPlainText "pass.123" -Force)
$wshell = New-Object -ComObject Wscript.Shell

$wshell.Popup("Password reset at: " + $aduser.SamAccountName ,0,"Password Reset")
}
}
catch{$error}
if($error){
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
GUI