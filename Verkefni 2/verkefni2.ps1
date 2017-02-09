#Fyrsti liður
New-NetIPAddress -InterfaceAlias "Boom" -IPAddress 172.16.24.0 -PrefixLength 21 #-DefaultGateway 192.168.1.1 notum ekki default gateway
Set-DnsClientServerAddress -InterfaceAlias "Boom" -ServerAddresses 127.0.0.1 
#
$domain2 = Get-ADDomain
$local = $domain2.DNSroot
$domainname = $domain2.name
$dnsname = $domainname+".local"
Add-DhcpServerv4Scope -Name newscope -StartRange 172.16.24.1 -EndRange 172.16.30.64 -SubnetMask 255.255.248.0
Set-DhcpServerv4OptionValue -DnsServer 172.16.24.0 -Router 172.16.24.0
Add-DhcpServerInDC -DnsName $domain2.DNSroot #t.d. $($env:computername + “.” $env:userdnsdomain)

#vélin var núeþgar á domaini svo ég þarf þetta ekki
#Add-Computer -ComputerName WIN3B-W81-07 -LocalCredential WIN3B-W81-07\Administrator -DomainName $domainname -Credential EEP-Olafur.local\Administrator








Invoke-Command -ComputerName WIN3B-W81-07 -ScriptBlock {"ipconfig /renew"} -Credential EEP-Olafur.local\Administrator

