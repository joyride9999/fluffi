:: ***************************************************************************
:: Copyright (c) 2017-2019 Siemens AG  All rights reserved.
:: ***************************************************************************/
::
::
:: Redistribution and use in source and binary forms, with or without
:: modification, are permitted provided that the following conditions are met:
::
:: * Redistributions of source code must retain the above copyright notice,
::   this list of conditions and the following disclaimer.
::
:: * Redistributions in binary form must reproduce the above copyright notice,
::   this list of conditions and the following disclaimer in the documentation
::   and/or other materials provided with the distribution.
::
:: THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
:: AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
:: IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
:: ARE DISCLAIMED. IN NO EVENT SHALL Siemens AG OR CONTRIBUTORS BE LIABLE
:: FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
:: DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
:: SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
:: CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
:: LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
:: OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH
:: DAMAGE.
:: 
:: Author(s): Thomas Riedmaier, Pascal Eckmann

RMDIR /Q/S include
RMDIR /Q/S bin
RMDIR /Q/S lib

MKDIR include
MKDIR include\siemens
MKDIR include\siemens\cpp
MKDIR include\siemens\csharp
MKDIR include\google
MKDIR include\google\protobuf
MKDIR bin
MKDIR bin\x64
MKDIR bin\x86
MKDIR lib
MKDIR lib\x64
MKDIR lib\x86

RMDIR /Q/S protobuf

REM Building windows protobof staticly. Dynamic builds don't work with /MT or /MTd - only with dll

git clone https://github.com/protocolbuffers/protobuf.git
cd protobuf
git checkout 106ffc04be1abf3ff3399f54ccf149815b287dd9
mkdir build64
mkdir build86

IF [%1]==[2017] (
	cd build64
	cmake -G "Visual Studio 15 2017 Win64" -Dprotobuf_BUILD_TESTS=OFF ../cmake
	powershell -Command "ls *.vcxproj -rec | %%{ $f=$_; (gc $f.PSPath) | %%{ $_ -replace 'MultiThreadedDebugDll', 'MultiThreadedDebug' } | sc $f.PSPath }"
	powershell -Command "ls *.vcxproj -rec | %%{ $f=$_; (gc $f.PSPath) | %%{ $_ -replace 'MultiThreadedDll', 'MultiThreaded' } | sc $f.PSPath }"
	"C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\MSBuild\15.0\Bin\MSBuild.exe" protobuf.sln /m /t:Build /p:Configuration=Release /p:Platform=x64 /property:VCTargetsPath="C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\Common7\IDE\VC\VCTargets"
	"C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\MSBuild\15.0\Bin\MSBuild.exe" protobuf.sln /m /t:Build /p:Configuration=Debug /p:Platform=x64 /property:VCTargetsPath="C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\Common7\IDE\VC\VCTargets"
	cd ..
	cd build86
	cmake -G "Visual Studio 15 2017" -Dprotobuf_BUILD_TESTS=OFF ../cmake
	powershell -Command "ls *.vcxproj -rec | %%{ $f=$_; (gc $f.PSPath) | %%{ $_ -replace 'MultiThreadedDebugDll', 'MultiThreadedDebug' } | sc $f.PSPath }"
	powershell -Command "ls *.vcxproj -rec | %%{ $f=$_; (gc $f.PSPath) | %%{ $_ -replace 'MultiThreadedDll', 'MultiThreaded' } | sc $f.PSPath }"
	"C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\MSBuild\15.0\Bin\MSBuild.exe" protobuf.sln /m /t:Build /p:Configuration=Release /p:Platform=Win32 /property:VCTargetsPath="C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\Common7\IDE\VC\VCTargets"
	"C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\MSBuild\15.0\Bin\MSBuild.exe" protobuf.sln /m /t:Build /p:Configuration=Debug /p:Platform=Win32 /property:VCTargetsPath="C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\Common7\IDE\VC\VCTargets"
) ELSE (
	cd build64
	cmake -G "Visual Studio 14 2015 Win64" -Dprotobuf_BUILD_TESTS=OFF ../cmake
	powershell -Command "ls *.vcxproj -rec | %%{ $f=$_; (gc $f.PSPath) | %%{ $_ -replace 'MultiThreadedDebugDll', 'MultiThreadedDebug' } | sc $f.PSPath }"
	powershell -Command "ls *.vcxproj -rec | %%{ $f=$_; (gc $f.PSPath) | %%{ $_ -replace 'MultiThreadedDll', 'MultiThreaded' } | sc $f.PSPath }"
	"C:\Program Files (x86)\MSBuild\14.0\Bin\MSBuild.exe" protobuf.sln /m /t:Build /p:Configuration=Release /p:Platform=x64 /property:VCTargetsPath="C:\Program Files (x86)\MSBuild\Microsoft.Cpp\v4.0\v140"
	"C:\Program Files (x86)\MSBuild\14.0\Bin\MSBuild.exe" protobuf.sln /m /t:Build /p:Configuration=Debug /p:Platform=x64 /property:VCTargetsPath="C:\Program Files (x86)\MSBuild\Microsoft.Cpp\v4.0\v140"
	cd ..
	cd build86
	cmake -G "Visual Studio 14 2015" -Dprotobuf_BUILD_TESTS=OFF ../cmake
	powershell -Command "ls *.vcxproj -rec | %%{ $f=$_; (gc $f.PSPath) | %%{ $_ -replace 'MultiThreadedDebugDll', 'MultiThreadedDebug' } | sc $f.PSPath }"
	powershell -Command "ls *.vcxproj -rec | %%{ $f=$_; (gc $f.PSPath) | %%{ $_ -replace 'MultiThreadedDll', 'MultiThreaded' } | sc $f.PSPath }"
	"C:\Program Files (x86)\MSBuild\14.0\Bin\MSBuild.exe" protobuf.sln /m /t:Build /p:Configuration=Release /p:Platform=Win32 /property:VCTargetsPath="C:\Program Files (x86)\MSBuild\Microsoft.Cpp\v4.0\v140"
	"C:\Program Files (x86)\MSBuild\14.0\Bin\MSBuild.exe" protobuf.sln /m /t:Build /p:Configuration=Debug /p:Platform=Win32 /property:VCTargetsPath="C:\Program Files (x86)\MSBuild\Microsoft.Cpp\v4.0\v140"
)
cd ..
cd ..

copy protobuf\build64\Release\protoc.exe bin\x64
copy protobuf\build64\Release\libprotobuf.lib lib\x64

copy protobuf\build64\Debug\libprotobufd.lib lib\x64
copy protobuf\build64\libprotobuf.dir\Debug\libprotobuf.pdb lib\x64

copy protobuf\build86\Release\protoc.exe bin\x86
copy protobuf\build86\Release\libprotobuf.lib lib\x86

copy protobuf\build86\Debug\libprotobufd.lib lib\x86
copy protobuf\build86\libprotobuf.dir\Debug\libprotobuf.pdb lib\x86


xcopy protobuf\src\*.h include /sy

waitfor SomethingThatIsNeverHappening /t 10 2>NUL
::reset errorlevel
ver > nul

RMDIR /Q/S protobuf

bin\x64\protoc.exe --cpp_out="include\siemens\cpp" --csharp_out="include\siemens\csharp" FLUFFI.proto

goto :eof

:err
exit /B 1

:eof
exit /B 0
