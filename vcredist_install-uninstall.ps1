# VS Redist 2005...
vcredist2005_x86.exe /q
MsiExec.exe /X{837b34e3-7c30-493c-8f6a-2b0f04e2912c}
HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\{837b34e3-7c30-493c-8f6a-2b0f04e2912c}
8.0.59193

vcredist2005_x64.exe /q
MsiExec.exe /X{6ce5bae9-d3ca-4b99-891a-1dc6c118a5fc}
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{6ce5bae9-d3ca-4b99-891a-1dc6c118a5fc}
8.0.59192


# VS Redist 2008...
vcredist2008_x86.exe /qb
MsiExec.exe /X{9BE518E6-ECC6-35A9-88E4-87755C07200F}
HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\{9BE518E6-ECC6-35A9-88E4-87755C07200F}
9.0.30729.6161

vcredist2008_x64.exe /qb
MsiExec.exe /X{5FCE6D76-F5DC-37AB-B2B8-22AB8CEDB1D4}
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{5FCE6D76-F5DC-37AB-B2B8-22AB8CEDB1D4}
9.0.30729.6161



# VS Redist 2010...
vcredist2010_x86.exe /silent /norestart
MsiExec.exe /X{F0C3E5D1-1ADE-321E-8167-68EF0DE699A5}
HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\{F0C3E5D1-1ADE-321E-8167-68EF0DE699A5}
10.0.40219

vcredist2010_x64.exe /silent /norestart
MsiExec.exe /X{1D8E6291-B0D5-35EC-8441-6616F567A0F7}
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{1D8E6291-B0D5-35EC-8441-6616F567A0F7}
10.0.40219



# VS Redist 2012...
vcredist2012_x86.exe /quiet /norestart
vcredist2012_x86.exe /silent /uninstall /norestart
HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\{33d1fd90-4274-48a1-9bc1-97e33d9c2d6f}
11.0.61030.0
/uninstall

vcredist2012_x64.exe /silent /norestart
MsiExec.exe /X{CF2BEA3C-26EA-32F8-AA9B-331F7E34BA97}
vcredist2012_x64.exe /silent /uninstall /norestart
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{CF2BEA3C-26EA-32F8-AA9B-331F7E34BA97}
11.0.61030



# VS Redist 2013...
vcredist2013_x86.exe /silent /norestart
HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\{8122DAB1-ED4D-3676-BB0A-CA368196543E}
vcredist2013_x86.exe /silent /uninstall /norestart
12.0.40664

vcredist2013_x64.exe /silent /norestart
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{53CF6934-A98D-3D84-9146-FC4EDF3D5641}
vcredist2013_x64.exe /silent /uninstall /norestart
12.0.40664



# VS Redist 2015, 2017 ^& 2019...
vcredist2015_2017_2019_x86.exe /silent /norestart
HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\{2BC3BD4D-FABA-4394-93C7-9AC82A263FE2}
MsiExec.exe /I{2BC3BD4D-FABA-4394-93C7-9AC82A263FE2}
vcredist2015_2017_2019_x86.exe /silent /uninstall /norestart
14.25.28508

vcredist2015_2017_2019_x64.exe /silent /norestart
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{EEA66967-97E2-4561-A999-5C22E3CDE428}
vcredist2015_2017_2019_x64.exe /silent /uninstall /norestart
14.25.28508



# just the uninstall commands
MsiExec.exe /X{837b34e3-7c30-493c-8f6a-2b0f04e2912c} /qn
MsiExec.exe /X{6ce5bae9-d3ca-4b99-891a-1dc6c118a5fc} /qn
MsiExec.exe /X{9BE518E6-ECC6-35A9-88E4-87755C07200F} /qn
MsiExec.exe /X{5FCE6D76-F5DC-37AB-B2B8-22AB8CEDB1D4} /qn
MsiExec.exe /X{F0C3E5D1-1ADE-321E-8167-68EF0DE699A5} /qn
MsiExec.exe /X{1D8E6291-B0D5-35EC-8441-6616F567A0F7} /qn

vcredist2012_x86.exe /silent /uninstall /norestart
vcredist2012_x64.exe /silent /uninstall /norestart

vcredist2013_x86.exe /silent /uninstall /norestart
vcredist2013_x64.exe /silent /uninstall /norestart

vcredist2015_2017_2019_x86.exe /silent /uninstall /norestart
vcredist2015_2017_2019_x64.exe /silent /uninstall /norestart
