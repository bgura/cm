@echo off
setlocal

:::::::::::::::::::::::::::::::::::::::::::::
:: Script will get all the changes in the current git repo
:: and iterate over them in an interactive manner
::
:: Script uses the following internal variables to execute
:: _cmd_git_diff - Command to get the list of changes in git repo
:: _cmd_git_root - Command to get the root of current git repo
::
:: _cm_p_skip_count - Number of changes to skip while looping over "_cmd_git_diff"
:: _cm_p_git_root - Absolute path to current git repo root
:: _cm_p_change_count - Total number of changes remaining to process
:: _cm_p_loop - Parameters to pass to for loop iterating over changes
:: _cm_p_summary_row - Repo relative path to current change being processed
:: _cm_p_full_path - Absolute path to current change being processed
:: _cm_p_input - Current user input
:::::::::::::::::::::::::::::::::::::::::::::

:: Go to Entry Point
goto :_func_main

:::::::::::::::::::::::::::::::::::::::::::::
:: Function: Main
::
:: Main entry point, setup the required env
:::::::::::::::::::::::::::::::::::::::::::::
:_func_main
  :: Setup the global commands used later
  SET _cmd_git_diff=git diff --name-only
  SET _cmd_git_root=git rev-parse --show-toplevel
  SET _cm_p_skip_count=0
  
  :: Resolve the root of our git repo and verify that it exists
  FOR /F %%r IN ('%_cmd_git_root%') DO SET _cm_p_git_root=%%r
  IF NOT EXIST %_cm_p_git_root% GOTO :_func_exit

  :: Get the number of changes
  FOR /F %%r IN ('git diff --name-only ^| find /v /c ""') DO SET _cm_p_change_count=%%r
  
  :: Process!
  goto :_func_process

:::::::::::::::::::::::::::::::::::::::::::::
:: Function: Process
::
:: Gets a list of all the changes in the current git repo
:: itearates them and allow interactive actions on the 
:: current change set
:::::::::::::::::::::::::::::::::::::::::::::
:_func_process
  :: Are we are the end?
  IF %_cm_p_skip_count% geq %_cm_p_change_count% (
    goto :_func_exit
  )

  :: Check if we should skip any records
  IF %_cm_p_skip_count% geq 1 (
    SET _cm_p_loop=skip=%_cm_p_skip_count% delims=
  ) ELSE (
    SET _cm_p_loop=delims=
  )

  FOR /F "%_cm_p_loop%" %%p IN ('%_cmd_git_diff%') DO (
    SET _cm_p_summary_row=%%p
    goto :_func_call_process_row
  )

:::::::::::::::::::::::::::::::::::::::::::::
:: Function: Process Row
::
:: Process a single change in our current git repo
:::::::::::::::::::::::::::::::::::::::::::::
:_func_process_row
  :: Display the correct prompt for this file based on its change
  IF "%_cm_p_change_type%"=="DELETE" (
    SET /P _cm_p_input="Would you like to [A]ccept Delete(s), [S]kip the file(s), [R]evert the file(s), [Q]uit?"
  ) ELSE IF "%_cm_p_change_type%"=="MODIFY" (
    git diff %_cm_p_full_path%
    SET /P _cm_p_input="Would you like to [A]ccept Change(s), [S]kip the file(s), [M]odify the file(s), [R]evert the file(s), [Q]uit?"
  ) ELSE IF "%_cm_p_change_type%"=="ADD" (
    git diff %_cm_p_full_path%
    SET /P _cm_p_input="Would you like to [A]ccept Change(s), [S]kip the file(s), [M]odify the file(s), [R]evert the file(s), [Q]uit?"
  ) ELSE (
    ECHO "Skipping file..."
    SET /a _cm_p_skip_count=_cm_p_skip_count+1
    :: Go back to our process loop and find the next file with changes
    goto :_func_process
  )

  IF "%_cm_p_input%"=="a" (
    
    :: If the file was deleted, do an rm, else do an add
    IF  "%_cm_p_change_type%"=="DELETE" (
      git rm %_cm_p_full_path%
    ) ELSE (
      git add %_cm_p_full_path%
    )

    ECHO "Accepted File Change^(s^)..."
    SET /a _cm_p_change_count=_cm_p_change_count-1

  ) ELSE IF "%_cm_p_input%"=="A" (
    
    :: If the file was deleted, do an rm, else do an add
    IF  "%_cm_p_change_type%"=="DELETE" (
      git rm %_cm_p_full_path%
    ) ELSE (
      git add %_cm_p_full_path%
    )

    git add %_cm_p_full_path%
    ECHO "Accepted File Change^(s^)..."
    SET /a _cm_p_change_count=_cm_p_change_count-1

  ) ELSE IF "%_cm_p_input%"=="r" (
    git checkout %_cm_p_full_path%
    ECHO "File reverted..."
    SET /a _cm_p_change_count=_cm_p_change_count-1
  ) ELSE IF "%_cm_p_input%"=="R" (
    git checkout %_cm_p_full_path%
    ECHO "File reverted..."
    SET /a _cm_p_change_count=_cm_p_change_count-1
  ) ELSE IF "%_cm_p_input%"=="M" (
    notepad %_cm_p_full_path%
    GOTO :_func_process_row
  ) ELSE IF "%_cm_p_input%"=="m" (
    notepad %_cm_p_full_path%
    GOTO :_func_process_row
  ) ELSE IF "%_cm_p_input%"=="Q" (
    GOTO :_func_exit
  ) ELSE IF "%_cm_p_input%"=="q" (
    GOTO :_func_exit
  ) ELSE (
    ECHO "Skipping file..."
    SET /a _cm_p_skip_count=_cm_p_skip_count+1
  )

  cls
  :: Go back to our process loop and find the next file with changes
  goto :_func_process

::::::::::::::::::::::::::::::::::::::::::::::::
:: Function: Call process row
::
:: Set's up meta data/paramters for the process_row function and then invokes it 
:_func_call_process_row
  :: Get the full path to this change and display it
  SET _cm_p_full_path=%_cm_p_git_root%/%_cm_p_summary_row%

  :: Resolve what type of change this is
  git status %_cm_p_full_path% --short | findstr /I /C:" D "
  IF %errorlevel% == 0 (
    SET _cm_p_change_type=DELETE
    goto :_func_process_row
  )

  git status %_cm_p_full_path% --short | findstr /I /C:" M "
  IF %errorlevel% == 0 (
    SET _cm_p_change_type=MODIFY
    goto :_func_process_row
  )

  git status %_cm_p_full_path% --short | findstr /I /C:"MM "
  IF %errorlevel% == 0 (
    SET _cm_p_change_type=MODIFY
    goto :_func_process_row
  )

  git status %_cm_p_full_path% --short | findstr /I /C:"UU "
  IF %errorlevel% == 0 (
    SET _cm_p_change_type=MODIFY
    goto :_func_process_row
  )

  git status %_cm_p_full_path% --short | findstr /I /C:" A "
  IF %errorlevel% == 0 (
    SET _cm_p_change_type=ADD
    goto :_func_process_row
  )

  goto :_func_process_row

:_func_exit
  ECHO cm complete
