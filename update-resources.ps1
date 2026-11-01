$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$manifestPath = Join-Path $root "resource-manifest.js"

$subjectInfo = @{
  lf = @{
    Title = "Logique Formelle"
    Intro = "Cours, TD et corrections."
  }
  algbr = @{
    Title = "Structures Alg\u00e9briques"
    Intro = "Cours, s\u00e9ries d'exercices et documents compl\u00e9mentaires."
  }
  anal = @{
    Title = "Analyse"
    Intro = "R\u00e9sum\u00e9 du cours et travaux dirig\u00e9s."
  }
  asd = @{
    Title = "Algorithmique et structures de donn\u00e9es"
    Intro = "Cours et travaux dirig\u00e9s."
  }
  "prog-c" = @{
    Title = "Programmation C"
    Intro = "Chapitres du cours et travaux pratiques."
  }
  sl = @{
    Title = "Syst\u00e8mes logiques"
    Intro = "Cours, travaux dirig\u00e9s et corrig\u00e9."
  }
}

function Convert-ToJsString([string]$value) {
  return ($value.Replace("'", "\'").Replace("`r", "").Replace("`n", "\n"))
}

function New-Manifest {
  $groupPrefixes = @{
    algbr = @{
      "Série 1" = "resource_algbr_Série 1_"
    }
    anal = @{
      "Résumé Analyse 1" = "resource_anal_Résumé Analyse 1_"
      "TD N°1" = "resource_anal_TD N°1_"
    }
    lf = @{
      "corc td 1" = "resource_lf_corc td 1_"
    }
  }

  $subjects = foreach ($subject in $subjectInfo.Keys | Sort-Object) {
    $info = $subjectInfo[$subject]
    $prefix = "resource_${subject}_"
    $files = @(Get-ChildItem -LiteralPath $root -File | Where-Object { $_.Name.StartsWith($prefix) } | Sort-Object Name)
    $subjectGroups = if ($groupPrefixes.ContainsKey($subject)) { $groupPrefixes[$subject] } else { @{} }
    $groups = @()

    $documentFiles = @($files | Where-Object {
      $isGrouped = $false
      foreach ($groupPrefix in $subjectGroups.Values) {
        if ($_.Name.StartsWith($groupPrefix)) {
          $isGrouped = $true
        }
      }
      -not $isGrouped
    })
    if ($documentFiles.Count -gt 0) {
      $paths = @($documentFiles | ForEach-Object {
        "'$(Convert-ToJsString $_.Name)'"
      })
      $groups += "['Documents',[$($paths -join ',')]]"
    }

    foreach ($group in $subjectGroups.GetEnumerator() | Sort-Object Name) {
      $groupFiles = @($files | Where-Object { $_.Name.StartsWith($group.Value) })
      if ($groupFiles.Count -gt 0) {
        $paths = @($groupFiles | ForEach-Object {
          "'$(Convert-ToJsString $_.Name)'"
        })
        $groups += "['$(Convert-ToJsString $group.Name)',[$($paths -join ',')]]"
      }
    }

    if ($groups.Count -gt 0) {
      "  '$subject':{title:'$(Convert-ToJsString $info.Title)',intro:'$(Convert-ToJsString $info.Intro)',groups:[$($groups -join ',')]}"
    }
  }

  $content = "window.subjects={`n$($subjects -join ",`n")`n};`n"
  Set-Content -LiteralPath $manifestPath -Value $content -Encoding utf8 -NoNewline
  Write-Host "Updated resource-manifest.js"
}

New-Manifest

if ($args -contains "-Watch") {
  $watcher = New-Object IO.FileSystemWatcher $root
  $watcher.Filter = "resource_*"
  $watcher.EnableRaisingEvents = $true
  $action = {
    Start-Sleep -Milliseconds 250
    New-Manifest
  }
  Register-ObjectEvent $watcher Created -Action $action | Out-Null
  Register-ObjectEvent $watcher Changed -Action $action | Out-Null
  Register-ObjectEvent $watcher Deleted -Action $action | Out-Null
  Register-ObjectEvent $watcher Renamed -Action $action | Out-Null
  Write-Host "Watching resource folders. Press Ctrl+C to stop."
  while ($true) {
    Wait-Event -Timeout 1 | Out-Null
  }
}
