:: Copyright 2017-2019 Siemens AG
:: 
:: Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
:: 
:: The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
:: 
:: THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
:: 
:: Author(s): Thomas Riedmaier, Pascal Eckmann
RMDIR /Q/S include
RMDIR /Q/S lib

MKDIR include
MKDIR lib
MKDIR lib\x64
MKDIR lib\x86

REM Getting easylogging

RMDIR /Q/S easyloggingpp

git clone https://github.com/zuhd-org/easyloggingpp.git
cd easyloggingpp
git checkout 5181b4039c04697aac7eac0bde44352cd8901567

REM Writing our config
powershell -Command " @('#define ELPP_NO_DEFAULT_LOG_FILE', '//#define ELPP_DISABLE_INFO_LOGS', '//#define ELPP_NO_LOG_TO_FILE', '#define ELPP_THREAD_SAFE', '#if !defined(_DEBUG) && !defined(DEBUG)', '#define ELPP_DISABLE_DEBUG_LOGS','#endif') + (Get-Content 'src\easylogging++.h') | Set-Content 'src\easylogging++.h'"

REM Apply patches for windows colorfull output

"C:\Program Files\Git\usr\bin\patch.exe" src\easylogging++.cc ..\enableWinColor.patch

REM Building easylogging lib

mkdir build64
mkdir build86
cd build64
IF [%1]==[2017] (
	cmake -G "Visual Studio 15 2017 Win64" -Dbuild_static_lib=ON ..
	powershell -Command "ls *.vcxproj -rec | %%{ $f=$_; (gc $f.PSPath) | %%{ $_ -replace 'MultiThreadedDebugDll', 'MultiThreadedDebug' } | sc $f.PSPath }"
	powershell -Command "ls *.vcxproj -rec | %%{ $f=$_; (gc $f.PSPath) | %%{ $_ -replace 'MultiThreadedDll', 'MultiThreaded' } | sc $f.PSPath }"
	"C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\MSBuild\15.0\Bin\MSBuild.exe" Easyloggingpp.sln /m /t:Build /p:Configuration=Release /p:Platform=x64 /property:VCTargetsPath="C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\Common7\IDE\VC\VCTargets"
	powershell -Command "ls *.vcxproj -rec | %%{ $f=$_; (gc $f.PSPath) | %%{ $_ -replace 'easyloggingpp</TargetName>', 'easyloggingppd</TargetName>' } | sc $f.PSPath }"
	powershell -Command "ls *.vcxproj -rec | %%{ $f=$_; (gc $f.PSPath) | %%{ $_ -replace 'easyloggingpp.lib', 'easyloggingppd.lib' } | sc $f.PSPath }"
	"C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\MSBuild\15.0\Bin\MSBuild.exe" Easyloggingpp.sln /m /t:Build /p:Configuration=Debug /p:Platform=x64 /property:VCTargetsPath="C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\Common7\IDE\VC\VCTargets"
	cd ..
	cd build86
	cmake -G "Visual Studio 15 2017" -Dbuild_static_lib=ON ..
	powershell -Command "ls *.vcxproj -rec | %%{ $f=$_; (gc $f.PSPath) | %%{ $_ -replace 'MultiThreadedDebugDll', 'MultiThreadedDebug' } | sc $f.PSPath }"
	powershell -Command "ls *.vcxproj -rec | %%{ $f=$_; (gc $f.PSPath) | %%{ $_ -replace 'MultiThreadedDll', 'MultiThreaded' } | sc $f.PSPath }"
	"C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\MSBuild\15.0\Bin\MSBuild.exe" Easyloggingpp.sln /m /t:Build /p:Configuration=Release /p:Platform=Win32 /property:VCTargetsPath="C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\Common7\IDE\VC\VCTargets"
	powershell -Command "ls *.vcxproj -rec | %%{ $f=$_; (gc $f.PSPath) | %%{ $_ -replace 'easyloggingpp</TargetName>', 'easyloggingppd</TargetName>' } | sc $f.PSPath }"
	powershell -Command "ls *.vcxproj -rec | %%{ $f=$_; (gc $f.PSPath) | %%{ $_ -replace 'easyloggingpp.lib', 'easyloggingppd.lib' } | sc $f.PSPath }"
	"C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\MSBuild\15.0\Bin\MSBuild.exe" Easyloggingpp.sln /m /t:Build /p:Configuration=Debug /p:Platform=Win32 /property:VCTargetsPath="C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\Common7\IDE\VC\VCTargets"
) ELSE (
	cmake -G "Visual Studio 14 2015 Win64" -Dbuild_static_lib=ON ..
	powershell -Command "ls *.vcxproj -rec | %%{ $f=$_; (gc $f.PSPath) | %%{ $_ -replace 'MultiThreadedDebugDll', 'MultiThreadedDebug' } | sc $f.PSPath }"
	powershell -Command "ls *.vcxproj -rec | %%{ $f=$_; (gc $f.PSPath) | %%{ $_ -replace 'MultiThreadedDll', 'MultiThreaded' } | sc $f.PSPath }"
	"C:\Program Files (x86)\MSBuild\14.0\Bin\MSBuild.exe" Easyloggingpp.sln /m /t:Build /p:Configuration=Release /p:Platform=x64 /property:VCTargetsPath="C:\Program Files (x86)\MSBuild\Microsoft.Cpp\v4.0\v140"
	powershell -Command "ls *.vcxproj -rec | %%{ $f=$_; (gc $f.PSPath) | %%{ $_ -replace 'easyloggingpp</TargetName>', 'easyloggingppd</TargetName>' } | sc $f.PSPath }"
	powershell -Command "ls *.vcxproj -rec | %%{ $f=$_; (gc $f.PSPath) | %%{ $_ -replace 'easyloggingpp.lib', 'easyloggingppd.lib' } | sc $f.PSPath }"
	"C:\Program Files (x86)\MSBuild\14.0\Bin\MSBuild.exe" Easyloggingpp.sln /m /t:Build /p:Configuration=Debug /p:Platform=x64 /property:VCTargetsPath="C:\Program Files (x86)\MSBuild\Microsoft.Cpp\v4.0\v140"
	cd ..
	cd build86
	cmake -G "Visual Studio 14 2015" -Dbuild_static_lib=ON ..
	powershell -Command "ls *.vcxproj -rec | %%{ $f=$_; (gc $f.PSPath) | %%{ $_ -replace 'MultiThreadedDebugDll', 'MultiThreadedDebug' } | sc $f.PSPath }"
	powershell -Command "ls *.vcxproj -rec | %%{ $f=$_; (gc $f.PSPath) | %%{ $_ -replace 'MultiThreadedDll', 'MultiThreaded' } | sc $f.PSPath }"
	"C:\Program Files (x86)\MSBuild\14.0\Bin\MSBuild.exe" Easyloggingpp.sln /m /t:Build /p:Configuration=Release /p:Platform=Win32 /property:VCTargetsPath="C:\Program Files (x86)\MSBuild\Microsoft.Cpp\v4.0\v140"
	powershell -Command "ls *.vcxproj -rec | %%{ $f=$_; (gc $f.PSPath) | %%{ $_ -replace 'easyloggingpp</TargetName>', 'easyloggingppd</TargetName>' } | sc $f.PSPath }"
	powershell -Command "ls *.vcxproj -rec | %%{ $f=$_; (gc $f.PSPath) | %%{ $_ -replace 'easyloggingpp.lib', 'easyloggingppd.lib' } | sc $f.PSPath }"
	"C:\Program Files (x86)\MSBuild\14.0\Bin\MSBuild.exe" Easyloggingpp.sln /m /t:Build /p:Configuration=Debug /p:Platform=Win32 /property:VCTargetsPath="C:\Program Files (x86)\MSBuild\Microsoft.Cpp\v4.0\v140"
)

cd ..
cd ..


copy easyloggingpp\build64\Release\easyloggingpp.lib lib\x64

copy easyloggingpp\build64\Debug\easyloggingppd.lib lib\x64
copy easyloggingpp\build64\easyloggingpp.dir\Debug\easyloggingpp.pdb lib\x64

copy easyloggingpp\build86\Release\easyloggingpp.lib lib\x86

copy easyloggingpp\build86\Debug\easyloggingppd.lib lib\x86
copy easyloggingpp\build86\easyloggingpp.dir\Debug\easyloggingpp.pdb lib\x86

copy "easyloggingpp\src\easylogging++.h" include


waitfor SomethingThatIsNeverHappening /t 10 2>NUL
::reset errorlevel
ver > nul

RMDIR /Q/S easyloggingpp

goto :eof

:err
exit /B 1

:eof
exit /B 0
