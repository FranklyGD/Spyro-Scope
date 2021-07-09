# run this script once after downloading the repo before trying to compile in beef
$lib_path = "$($env:BeefPath)/BeefLibs"
$client = new-object System.Net.WebClient

# get freetype beef api
$client.DownloadFile('https://github.com/FranklyGD/BasicFreeType-beef/archive/refs/heads/master.zip', './master.zip')
Expand-Archive -Path './master.zip' -DestinationPath $lib_path -Force
Remove-Item -Path './master.zip' -Force

# get freetype windows libraries
$freetype_lib_path = "$($lib_path)/BasicFreeType-beef-master/dist"
$winXX = @('win32', 'win64')
$dlllib = @('dll', 'lib')
$freetype_release_dll_url = 'https://github.com/ubawurinna/freetype-windows-binaries/raw/master/release%20dll'

for ($win = 0; $win -lt 2; $win++) {
    for ($lll = 0; $lll -lt 2; $lll++) {
        $endpoint = "/$($winXX[$win])/freetype.$($dlllib[$lll])"
        $client.DownloadFile("$($freetype_release_dll_url)$($endpoint)", "$($freetype_lib_path)$($endpoint)")
    }
}