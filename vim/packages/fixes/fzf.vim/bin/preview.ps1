if ($args.Count -lt 1)
{
  echo "usage: $PSCommandPath FILENAME[:LINENO][:IGNORED]"
  exit 1
}

if ($args[0] -match '^([A-Z]:)?([^:]*)(:([^:]*))?(:(.*))?$')
{
  $file = $Matches[1]+$Matches[2]
  $lineno = $Matches[4]
  $ignored = $Matches[6]
}
else
{
  $file = $args[0]
  $center = ''
  $ignored = ''
}

if ($lineno -and -not ($linenno -match '^[0-9]*$' ))
{
  echo "Argument LINENO='$center' is not a number"
  exit 20
}

$homedir = Get-Variable HOME -valueOnly 
if (-not $homedir)
{
  $homedir = (Get-Variable HOMEDRIVE -valueOnly) + (Get-Variable HOMEPATH -valueOnly)
}
if (-not ($homedir -match '\\$')) { $homedir = $homedir + '\' }


$file = ((($file -replace '\\\\', '\') -replace '\/', '\') -replace '~\\',$homedir)

if (-not (Test-Path $file -PathType Leaf))
{
  echo "File not found $file"
  exit 1
}

if (-not $lineno) { $lineno = '0' }

$batcmd = Get-Command "batcat" -ErrorAction SilentlyContinue
if ($batcmd -eq $null) { $batcmd = Get-Command "bat" -ErrorAction SilentlyContinue }
if ($batcmd -ne $null) { $bat = $batcmd.Name }

$batstyle = Get-Variable BAT_STYLE -valueOnly -ErrorAction SilentlyContinue
if (-not $batstyle) { $batstyle = 'numbers' }
$cmd = """$bat"" --style=""$batstyle"" --color=always --pager=never --highlight-line=$lineno ""$file"""

Invoke-Expression "& $cmd"
