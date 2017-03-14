
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