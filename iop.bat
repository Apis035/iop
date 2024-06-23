@echo off

title Init Odin Project

setlocal EnableDelayedExpansion

:: Delete the colon (:) below before `goto` to disable color
:goto disable-color
	set r=[0m
	set i=[91m
	set o=[94m
	set p=[96m
	set ri=[101;30m
	set ro=[104;30m
	set rp=[106;30m
	set g=[90m
	set y=[33m
	set yb=[43;97m
	set rb=[41;97m
:disable-color

set FoundOdin=false
set FoundGit=false
set OdinRoot=nil

set ProjectType=nil
set ProjectName=nil

set CreateSrc=false
set CreateBuildScript=false
set CreateSublimeProject=false
set CreateGitRepo=false

:main
	where odin >nul
	if !errorlevel! == 0 set FoundOdin=true
	where git >nul
	if !errorlevel! == 0 set FoundGit=true

	if !FoundOdin! == true (
		for /f %%` in ('odin root') do set OdinRoot=%%`
	)

	echo       %i%_
	echo      %i%(_)%o%____   %p%____
	echo     %i%/ /%o%/ __ \ %p%/ __ \
	echo    %i%/ /%o%/ /_/ /%p%/ /_/ /
	echo   %i%/_/ %o%\____/%p%/ .___/
	echo            %p%/_/
	echo                 %ri% Init %ro% Odin %rp% Project %r%

	echo What kind of Odin project you want to create?
	echo %g%1.%r% Basic
	echo %g%2.%r% Raylib (static)
	echo %g%3.%r% Raylib (dynamic)
	echo %g%4.%r% Exit
	<nul set /p=^>%g% & choice /c 1234 /n
	if !errorlevel! == 1 set ProjectType=basic
	if !errorlevel! == 2 set ProjectType=raylibStatic
	if !errorlevel! == 3 set ProjectType=raylibDynamic
	if !errorlevel! == 4 exit /b

	:reenter
		echo.
		echo %r%Enter project name:
		set /p ProjectName=^> %g%
		if not "!ProjectName!" == "!ProjectName: =_!" (
			set ProjectName=!ProjectName: =_!
			echo.
			echo %yb% Warning: %r% Project name must not contain spaces.
			echo            It will be changed into "!ProjectName!".
		)
		if exist !ProjectName! (
			echo.
			echo %rb% Fail: %r% A directory with the name "!ProjectName!" already exist.
			echo         Please enter another name.
			goto reenter
		)

	echo.
	echo %r%Do you want to use src folder to put source files? [y/n]
	<nul set /p=^>%g% & choice /n
	if !errorlevel! == 1 set CreateSrc=true

	echo.
	echo %r%Do you want to create build.bat? [y/n]
	<nul set /p=^>%g% & choice /n
	if !errorlevel! == 1 set CreateBuildScript=true

	echo.
	echo %r%Do you want to create Sublime Text project file? [y/n]
	<nul set /p=^>%g% & choice /n
	if !errorlevel! == 1 set CreateSublimeProject=true

	if %FoundGit% == true (
		echo.
		echo %r%Initialize a Git repository?
		<nul set /p=^>%g% & choice /n
		if !errorlevel! == 1 set CreateGitRepo=true
	)

	echo.
	mkdir !ProjectName!
	pushd !ProjectName!
		if !CreateSrc! == true mkdir src

		set _pushsrc=if !CreateSrc! == true pushd src
		set _popsrc=if !CreateSrc! == true popd

		if !ProjectType! == basic         call :create-basic-template
		if !ProjectType! == raylibStatic  call :create-raylib-template static
		if !ProjectType! == raylibDynamic call :create-raylib-template dynamic
		if !CreateBuildScript! == true    call :create-build-script
		if !CreateSublimeProject! == true call :create-sublime-project
		if !CreateGitRepo! == true        call :create-git-repo
	popd

	echo.
	echo %o%Finished generating.%r%
	pause>nul
exit /b

:create-basic-template
setlocal
	echo %r%* %y%Creating template Odin file...
	%_pushsrc%
    for %%` in (
        "package !ProjectName!"
        "."
        "import 'core:fmt'"
        "."
        "main :: proc() {"
        "   fmt.println('Hellope^^^!')"
        "}"
    ) do (
        set _=%%~`
        (if "!_!" == "." (
            echo.
        ) else (
            echo !_:'="!
        )) >> main.odin
    )
	%_popsrc%
exit /b

:create-raylib-template [static/dynamic]
setlocal
	echo %r%* %y%Creating template Odin-raylib file...
	%_pushsrc%
    for %%i in (
        "package !ProjectName!"
        "."
        "import rl 'vendor:raylib'"
        "."
        "SCREEN_WIDTH :: 800"
        "SCREEN_HEIGHT :: 450"
        "."
        "main :: proc() {"
        "   rl.InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, 'raylib template (%~1)')"
        "   defer rl.CloseWindow()"
        "."
        "   rl.SetTargetFPS(60)"
        "."
        "   for ^^^!rl.WindowShouldClose() {"
        "       rl.BeginDrawing()"
        "           rl.ClearBackground(rl.RAYWHITE)"
        "           rl.DrawText('Congrats^^^! You created your first window^^^!', 190, 200, 20, rl.LIGHTGRAY)"
        "       rl.EndDrawing()"
        "   }"
        "}"
    ) do (
        set _=%%~i
        (if "!_!" == "." (
            echo.
        ) else (
            echo !_:'="!
        )) >> main.odin
    )
	%_popsrc%

	if %~1 == dynamic (
		copy "!OdinRoot!vendor\raylib\windows\raylib.dll" raylib.dll >nul
	)
exit /b

:generate-build-command [opt]
setlocal
	set sourceDir=.
	set raylibShared=
	if !CreateSrc! == true set sourceDir=src
	if !ProjectType! == raylibDynamic set raylibShared=-define:RAYLIB_SHARED=true
	set result=odin build !sourceDir! -out:!ProjectName!.exe -o:%~1 !raylibShared!
endlocal & (
	set result=%result%
)
exit /b

:create-build-script
	echo %r%* %y%Creating build.bat script...
	call :generate-build-command speed
	>> build.bat echo !result!
exit /b

:create-sublime-project
setlocal
	echo %r%* %y%Creating Sublime Text project...
	call :generate-build-command none
	for %%` in (
		"{"
		"	'folders':"
		"	["
		"		{"
		"			'path': '.'"
		"		},"
		"		{"
		"			'path': '!OdinRoot:\=\\!core'"
		"		},"
		"		{"
		"			'path': '!OdinRoot:\=\\!vendor'"
		"		},"
		"	],"
		"	'build_systems':"
		"	["
		"		{"
		"			'name': 'Run',"
		"			'cmd': '!result!',"
		"			'working_dir': '$folder',"
		"			'file_regex': '^^(.+)\\(([0-9]+):([0-9]+)\\) (.+)$'"
		"		}"
		"	],"
		"}"
	) do (
		set _=%%~`
		>> !ProjectName!.sublime-project echo !_:'="!
	)
exit /b

:create-git-repo
	echo %r%* %y%Creating .gitignore...
	>> .gitignore echo .vscode/
	for %%` in (
		"exp"
		"exe"
		"obj"
		"pdb"
		"sublime-workspace"
	) do >> .gitignore echo *.%%~`
	echo %r%* %y%Creating git repository...
	git init >nul
exit /b