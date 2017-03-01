function Info-Tolvur
{
param(
[Parameter(Mandatory)]
$tolva
)
$htafla = @{}
$array = @()
foreach($t in $tolva){
$os = Get-wmiobject Win32_OperatingSystem -ComputerName $t | Select-Object Caption
$name =Get-WmiObject -Class Win32_computerSystem -ComputerName $t | Select-Object Name
$ip = Get-WmiObject -Class Win32_NetworkAdapterConfiguration  -ComputerName $t | Select-Object IpAddress
$diskur = Get-WmiObject -Class Win32_LogicalDisk -ComputerName $t | Select-Object size
$laust = Get-WmiObject -Class Win32_LogicalDisk -ComputerName $t| Select-Object FreeSpace
$ram = Get-WMIObject Win32_PhysicalMemory -ComputerName $t | Select-Object Capacity
foreach($r in $ram)
{
$ramsum = $ramsum + $r.Capacity;

}

$ramsum = [math]::round($ramsum /1gb, 3);
$diskaplass = [math]::round($diskur[1].size /1gb, 3)
$lausplass = [math]::round($laust[1].FreeSpace /1gb, 3)

$htafla.Add("Nafn Tölvu:",[string]$name.Name)
$htafla.Add("Stýrikerfi:",[string]$os.Caption)
$htafla.Add("Diskur:",[string]$diskaplass+" GB")
$htafla.Add("Laust:",[string]$lausplass +" GB")
$htafla.Add("Vinnsluminni:", [string]$ramsum+" GB")
$info = New-Object PSObject -Property $htafla
$array += $info
$htafla = @{}
}


$array | Export-Csv -Path "C:\Users\Administrator\Desktop\skra2.csv" -NoTypeInformation -Encoding Unicode
$array


}