#define MyAppName "HorsePos Launcher"
#ifndef MyAppVersion
  #define MyAppVersion "1.1.0"
#endif
#define MyAppPublisher "HorsePos"
#define MyAppExeName "HorseLauncher.exe"

[Setup]
AppId={{A57F4C9D-5CF2-4895-81E0-85C5B0380CC4}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName={localappdata}\HorsePos\Launcher
DisableDirPage=yes
DisableProgramGroupPage=yes
PrivilegesRequired=lowest
OutputDir=output
OutputBaseFilename=HorseLauncher_Setup
Compression=lzma
SolidCompression=yes
WizardStyle=modern
ArchitecturesInstallIn64BitMode=x64
UninstallDisplayIcon={app}\{#MyAppExeName}

[Files]
Source: "..\dist_launcher\*"; DestDir: "{localappdata}\HorsePos\Launcher"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "..\dist_app\*"; DestDir: "{localappdata}\HorsePos\App"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autodesktop}\HorsePos"; Filename: "{localappdata}\HorsePos\Launcher\{#MyAppExeName}"
Name: "{userprograms}\HorsePos"; Filename: "{localappdata}\HorsePos\Launcher\{#MyAppExeName}"

[Run]
Filename: "{localappdata}\HorsePos\Launcher\{#MyAppExeName}"; Description: "Abrir HorsePos Launcher"; Flags: nowait postinstall skipifsilent
