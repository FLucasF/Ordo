; Windows installer of Tarefas, for Inno Setup 6 (https://jrsoftware.org/isinfo.php).
; Build it with windows\installer\build_installer.ps1: it builds the app, puts the Visual C++ runtime
; next to it and compiles this script.
; The installer goes to build\installer\TarefasSetup-<version>.exe.
;
; It installs for the current user only (no administrator), in %LOCALAPPDATA%\Programs\Tarefas.
; The data (database, attachments, calendars) lives in the user's AppData and is kept when the app is
; updated or removed.

#define AppName "Tarefas"
#define AppVersion "1.5.1"
#define AppExe "task_manager.exe"

[Setup]
AppId={{E8FC1625-378E-4016-B181-A938F16BD25E}
AppName={#AppName}
AppVersion={#AppVersion}
AppVerName={#AppName} {#AppVersion}
DefaultDirName={localappdata}\Programs\{#AppName}
DefaultGroupName={#AppName}
DisableProgramGroupPage=yes
PrivilegesRequired=lowest
OutputDir=..\..\build\installer
OutputBaseFilename=TarefasSetup-{#AppVersion}
Compression=lzma2
SolidCompression=yes
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
WizardStyle=modern
UninstallDisplayIcon={app}\{#AppExe}

[Languages]
Name: "brazilianportuguese"; MessagesFile: "compiler:Languages\BrazilianPortuguese.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
; The app, with the Visual C++ runtime DLLs next to it (build_installer.ps1 copies them into Release),
; so it also runs on a Windows without the runtime.
Source: "..\..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Registry]
; The window's last size and position (saved by the app); removed with the app, unlike the data.
Root: HKCU; Subkey: "Software\dev.lucasfelipe"; Flags: uninsdeletekeyifempty
Root: HKCU; Subkey: "Software\dev.lucasfelipe\Tarefas"; Flags: uninsdeletekey
; "Iniciar com o Windows" (set by the app): the startup entry goes with the app.
Root: HKCU; Subkey: "Software\Microsoft\Windows\CurrentVersion\Run"; ValueType: none; ValueName: "Tarefas"; Flags: uninsdeletevalue dontcreatekey

[Icons]
Name: "{group}\{#AppName}"; Filename: "{app}\{#AppExe}"
Name: "{autodesktop}\{#AppName}"; Filename: "{app}\{#AppExe}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#AppExe}"; Description: "{cm:LaunchProgram,{#AppName}}"; Flags: nowait postinstall skipifsilent

[Code]
// The app keeps running in the tray when its window is closed. Before removing its files, the
// uninstaller asks it to quit (the message windows/runner/flutter_window.h names) and waits for its
// single-instance mutex to go.
const
  AppMutex = 'Local\dev.lucasfelipe.Tarefas';

function RegisterWindowMessage(lpString: String): Cardinal;
  external 'RegisterWindowMessageW@user32.dll stdcall';

procedure CloseRunningApp();
var
  I: Integer;
begin
  if not CheckForMutexes(AppMutex) then
    Exit;
  PostBroadcastMessage(RegisterWindowMessage('dev.lucasfelipe.Tarefas.Quit'), 0, 0);
  for I := 1 to 40 do
  begin
    if not CheckForMutexes(AppMutex) then
      Exit;
    Sleep(250);
  end;
end;

function InitializeUninstall(): Boolean;
begin
  CloseRunningApp();
  Result := True;
end;
