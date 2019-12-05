::   Copyright 2017-2019 Siemens AG
::
::   Licensed under the Apache License, Version 2.0 (the "License");
::   you may not use this file except in compliance with the License.
::   You may obtain a copy of the License at
::
::       http://www.apache.org/licenses/LICENSE-2.0
::
::   Unless required by applicable law or agreed to in writing, software
::   distributed under the License is distributed on an "AS IS" BASIS,
::   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
::   See the License for the specific language governing permissions and
::   limitations under the License.
:: 
:: Author(s): Thomas Riedmaier, Pascal Eckmann

RMDIR /Q/S include
RMDIR /Q/S lib

MKDIR include
MKDIR include\libhfcommon
MKDIR lib
MKDIR lib\x64
MKDIR lib\x86

RMDIR /Q/S honggfuzz

REM Getting honggfuzz

git clone https://github.com/google/honggfuzz.git
cd honggfuzz
git checkout 589a9fb92c843ce5d44645e58457f7c041a33238

Rem Apply patch that allows us to integrate the honggfuzz mutations into FLUFFI

"C:\Program Files\Git\usr\bin\patch.exe" -p0 -i ..\honggfuzz.patch

REM Building honggfuzz

mkdir build64
mkdir build86

IF [%1]==[2017] (
	SETLOCAL
	cd build64
	call "C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\VC\Auxiliary\Build\vcvarsall.bat" x64

	cl.exe /MT /c /TP /EHsc ..\mangle.c ..\libhfcommon\util.c ..\input.c
	LIB.EXE /OUT:honggfuzz.LIB mangle.obj util.obj input.obj
	cl.exe /MTd /Debug /c /TP /EHsc ..\mangle.c ..\libhfcommon\util.c ..\input.c
	LIB.EXE /OUT:honggfuzzd.LIB mangle.obj util.obj input.obj
	cd ..
	ENDLOCAL

	SETLOCAL
	cd build86
	call "C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\VC\Auxiliary\Build\vcvarsall.bat" x86

	cl.exe /MT /c /TP /EHsc ..\mangle.c ..\libhfcommon\util.c ..\input.c
	LIB.EXE /OUT:honggfuzz.LIB mangle.obj util.obj input.obj
	cl.exe /MTd /Debug /c /TP /EHsc ..\mangle.c ..\libhfcommon\util.c ..\input.c
	LIB.EXE /OUT:honggfuzzd.LIB mangle.obj util.obj input.obj
	cd ..
	ENDLOCAL
) ELSE (
	SETLOCAL
	cd build64
	call "C:\Program Files (x86)\Microsoft Visual Studio 14.0\VC\vcvarsall.bat" x64

	cl.exe /MT /c /TP /EHsc ..\mangle.c ..\libhfcommon\util.c ..\input.c
	LIB.EXE /OUT:honggfuzz.LIB mangle.obj util.obj input.obj
	cl.exe /MTd /Debug /c /TP /EHsc ..\mangle.c ..\libhfcommon\util.c ..\input.c
	LIB.EXE /OUT:honggfuzzd.LIB mangle.obj util.obj input.obj
	cd ..
	ENDLOCAL

	SETLOCAL
	cd build86
	call "C:\Program Files (x86)\Microsoft Visual Studio 14.0\VC\vcvarsall.bat" x86

	cl.exe /MT /c /TP /EHsc ..\mangle.c ..\libhfcommon\util.c ..\input.c
	LIB.EXE /OUT:honggfuzz.LIB mangle.obj util.obj input.obj
	cl.exe /MTd /Debug /c /TP /EHsc ..\mangle.c ..\libhfcommon\util.c ..\input.c
	LIB.EXE /OUT:honggfuzzd.LIB mangle.obj util.obj input.obj
	cd ..
	ENDLOCAL
)

cd ..


copy honggfuzz\build64\honggfuzz.LIB lib\x64

copy honggfuzz\build64\honggfuzzd.LIB lib\x64

copy honggfuzz\build86\honggfuzz.LIB lib\x86

copy honggfuzz\build86\honggfuzzd.LIB lib\x86

copy honggfuzz\mangle.h include
copy honggfuzz\honggfuzz.h include
copy honggfuzz\libhfcommon\util.h include\libhfcommon

waitfor SomethingThatIsNeverHappening /t 10 2>NUL
::reset errorlevel
ver > nul

RMDIR /Q/S honggfuzz

goto :eof

:err
exit /B 1

:eof
exit /B 0
