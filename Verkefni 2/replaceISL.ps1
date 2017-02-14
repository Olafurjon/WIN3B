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
}