#define MyAppName "P41 Bootstrap"
#ifndef MyAppVersion
  #define MyAppVersion "1.1.0"
#endif
#define MyAppPublisher "P41"
#define MyAppExeName "P41Bootstrap.exe"

[Setup]
AppId={{A57F4C9D-5CF2-4895-81E0-85C5B0380CC4}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName={localappdata}\P41\Bootstrap
DisableDirPage=yes
DisableProgramGroupPage=yes
PrivilegesRequired=lowest
OutputDir=output
OutputBaseFilename=P41Bootstrap_Setup
Compression=lzma
SolidCompression=yes
WizardStyle=modern
ArchitecturesInstallIn64BitMode=x64
UninstallDisplayIcon={app}\{#MyAppExeName}

[Files]
Source: "..\dist_launcher\*"; DestDir: "{localappdata}\P41\Bootstrap"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "..\dist_app\*"; DestDir: "{localappdata}\P41\App"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autodesktop}\P41"; Filename: "{localappdata}\P41\Bootstrap\{#MyAppExeName}"
Name: "{userprograms}\P41"; Filename: "{localappdata}\P41\Bootstrap\{#MyAppExeName}"

[Run]
Filename: "{localappdata}\P41\Bootstrap\{#MyAppExeName}"; Description: "Abrir P41"; Flags: nowait postinstall skipifsilent
