; Script generated by the Inno Setup Script Wizard.
; SEE THE DOCUMENTATION FOR DETAILS ON CREATING INNO SETUP SCRIPT FILES!

#define MyAppName "Auto Screenshot"
#define MyAppVersion "1.8"
#define MyAppPublisher "Artem Demin"
#define MyAppURL "https://github.com/artem78/AutoScreenshot#readme"
#define MyAppExeName "AutoScreenshot.exe"

[Setup]
; NOTE: The value of AppId uniquely identifies this application.
; Do not use the same AppId value in installers for other applications.
; (To generate a new GUID, click Tools | Generate GUID inside the IDE.)
AppId={{E91D6BA8-641A-49F1-B724-A61B934F6522}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
;AppVerName={#MyAppName} {#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}
DefaultDirName={pf}\AutoScreenshot
DisableProgramGroupPage=yes
LicenseFile=LICENSE.txt
OutputDir=build\setup
OutputBaseFilename=autoscreenshot_{#MyAppVersion}_setup
Compression=lzma
SolidCompression=yes

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"
Name: "russian"; MessagesFile: "compiler:Languages\Russian.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "AutoScreenshot.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "lang\*"; DestDir: "{app}\lang"; Flags: ignoreversion recursesubdirs createallsubdirs; Excludes: "*.bak"
; NOTE: Don't use "Flags: ignoreversion" on any shared system files
; ToDo: Remove config.ini when uninstall or make this optional

[Icons]
Name: "{commonprograms}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{commondesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent

[Registry]
; Remove autorun
Root: "HKCU"; Subkey: "Software\Microsoft\Windows\CurrentVersion\Run"; ValueName: "Auto Screenshot"; Flags: uninsdeletekey

[UninstallDelete]
Type: files; Name: "{app}\config.ini"
