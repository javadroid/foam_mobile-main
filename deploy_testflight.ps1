# ─────────────────────────────────────────────────────────────────────────────
# 🚀 Foam Mobile — TestFlight Build & Deployment Trigger
# ─────────────────────────────────────────────────────────────────────────────
# Usage:
#   .\testflight.ps1
#   .\testflight.ps1 -CommitMessage "Release beta v1.0.2"
#   .\testflight.ps1 -CheckSecretsOnly
#   .\testflight.ps1 -NoWait
# ─────────────────────────────────────────────────────────────────────────────

[CmdletBinding()]
param (
    [Parameter(Position = 0)]
    [string]$CommitMessage = "",

    [Parameter()]
    [string]$Branch = "",

    [Parameter()]
    [switch]$AutoCommit,

    [Parameter()]
    [switch]$CheckSecretsOnly,

    [Parameter()]
    [switch]$NoWait
)

$ErrorActionPreference = "Stop"

# 1. Determine Repository Path
$repoPath = $PSScriptRoot
if (Test-Path "$PSScriptRoot\foam_mobile-main\.git") {
    $repoPath = "$PSScriptRoot\foam_mobile-main"
} elseif (-not (Test-Path "$PSScriptRoot\.git")) {
    Write-Host "❌ Error: Could not locate .git repository in $PSScriptRoot" -ForegroundColor Red
    exit 1
}

Push-Location $repoPath

try {
    Write-Host "`n╔══════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║        🚀 Foam Mobile — GitHub Actions TestFlight Deployment         ║" -ForegroundColor Cyan
    Write-Host "╚══════════════════════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan

    # 2. Read GITHUB_TOKEN
    $token = $env:GITHUB_TOKEN
    $envFile = Join-Path $repoPath ".env"
    if (-not $token -and (Test-Path $envFile)) {
        Get-Content $envFile | ForEach-Object {
            if ($_ -match 'GITHUB_TOKEN\s*=\s*(.+)') {
                $token = $matches[1].Trim().Trim('"').Trim("'")
            }
        }
    }

    if (-not $token) {
        Write-Host "⚠️  GITHUB_TOKEN not found in environment or .env." -ForegroundColor Yellow
        Write-Host "   Tag trigger will still work via Git, but workflow dispatch API & status tracking require a token." -ForegroundColor DarkGray
    }

    $repoOwner = "javadroid"
    $repoName = "foam_mobile-main"
    $headers = @{
        "User-Agent" = "PowerShell-TestFlight-Deployer"
        "Accept"     = "application/vnd.github+json"
    }
    if ($token) {
        $headers["Authorization"] = "token $token"
    }

    # 3. Check GitHub Secrets
    if ($token) {
        Write-Host "🔍 Verifying required GitHub Actions secrets on $repoOwner/$repoName..." -ForegroundColor Cyan
        try {
            $secResponse = Invoke-RestMethod -Uri "https://api.github.com/repos/$repoOwner/$repoName/actions/secrets" -Headers $headers -Method Get
            $existingSecrets = @($secResponse.secrets.name)

            $requiredSecrets = @(
                "IOS_DISTRIBUTION_CERTIFICATE_BASE64",
                "IOS_CERTIFICATE_PASSWORD",
                "IOS_PROVISION_PROFILE_BASE64",
                "APP_STORE_CONNECT_API_KEY_ID",
                "APP_STORE_CONNECT_ISSUER_ID",
                "APP_STORE_CONNECT_PRIVATE_KEY"
            )

            $missing = @()
            foreach ($sec in $requiredSecrets) {
                if ($existingSecrets -contains $sec) {
                    Write-Host "  ✅ Secret configured: $sec" -ForegroundColor Green
                } else {
                    Write-Host "  ❌ Missing secret:   $sec" -ForegroundColor Red
                    $missing += $sec
                }
            }

            if ($missing.Count -gt 0) {
                Write-Host "`n⚠️  Attention: $($missing.Count) required secret(s) are missing in GitHub repository settings!" -ForegroundColor Yellow
                Write-Host "   Set them at: https://github.com/$repoOwner/$repoName/settings/secrets/actions" -ForegroundColor Cyan
                if ($CheckSecretsOnly) {
                    exit 1
                }
            } else {
                Write-Host "  🎉 All required code-signing & App Store Connect secrets are present!`n" -ForegroundColor Green
            }
        } catch {
            Write-Host "  ⚠️  Could not inspect secrets via API: $($_.Exception.Message)" -ForegroundColor DarkGray
        }
    }

    if ($CheckSecretsOnly) {
        exit 0
    }

    # 4. Git Branch & Status Check
    $currentBranch = (git branch --show-current).Trim()
    if (-not $currentBranch) {
        $currentBranch = "ios"
    }
    if ($Branch) {
        $targetBranch = $Branch
    } else {
        $targetBranch = $currentBranch
    }

    Write-Host "📌 Working on branch: " -NoNewline
    Write-Host $targetBranch -ForegroundColor Yellow

    # Check uncommitted changes
    $status = git status --porcelain
    if ($status) {
        Write-Host "`n📝 Uncommitted local changes detected:" -ForegroundColor Yellow
        git status -s
        
        $shouldCommit = $AutoCommit
        if (-not $shouldCommit) {
            $choice = Read-Host "`nWould you like to commit and push these changes before deploying? (Y/n)"
            if ($choice -eq "" -or $choice -match "^[yY]") {
                $shouldCommit = $true
            }
        }

        if ($shouldCommit) {
            if (-not $CommitMessage) {
                $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm"
                $CommitMessage = "chore: prepare build for TestFlight deployment ($timestamp)"
            }
            Write-Host "💾 Committing changes with message: '$CommitMessage'..." -ForegroundColor Cyan
            git add -A
            git commit -m $CommitMessage
        } else {
            Write-Host "⚠️  Continuing without committing local changes (only remote commits will be built)." -ForegroundColor DarkGray
        }
    }

    # 5. Push branch to remote
    Write-Host "`n⬆️  Pushing branch '$targetBranch' to origin..." -ForegroundColor Cyan
    git push origin $targetBranch

    # 6. Create & Push TestFlight Tag
    $tagTimestamp = Get-Date -Format "yyyy.MM.dd-HHmmss"
    $tagName = "testflight-$tagTimestamp"
    Write-Host "🏷️  Creating TestFlight release tag: $tagName..." -ForegroundColor Cyan
    git tag $tagName
    git push origin $tagName

    # 7. Trigger Workflow Dispatch via GitHub API
    Write-Host "`n⚡ Triggering GitHub Actions TestFlight workflow..." -ForegroundColor Cyan
    $dispatched = $false
    if ($token) {
        try {
            $body = @{
                ref = $targetBranch
                inputs = @{
                    upload_to_testflight = $true
                }
            } | ConvertTo-Json

            Invoke-RestMethod -Uri "https://api.github.com/repos/$repoOwner/$repoName/actions/workflows/deploy_ios_signed.yml/dispatches" `
                -Headers $headers `
                -Method Post `
                -Body $body

            $dispatched = $true
            Write-Host "✅ Workflow dispatch triggered successfully on branch '$targetBranch'!" -ForegroundColor Green
        } catch {
            Write-Host "ℹ️  Workflow dispatch API note: $($_.Exception.Message)" -ForegroundColor DarkGray
            Write-Host "   (Tag push '$tagName' has already triggered the build via Git tag trigger.)" -ForegroundColor Green
        }
    }

    # 8. Locate Running Workflow and Monitor
    Write-Host "`n🔗 Tracking workflow run..." -ForegroundColor Cyan
    Start-Sleep -Seconds 4

    $runUrl = "https://github.com/$repoOwner/$repoName/actions"
    $runId = $null

    if ($token) {
        for ($attempt = 1; $attempt -le 6; $attempt++) {
            try {
                $runsResponse = Invoke-RestMethod -Uri "https://api.github.com/repos/$repoOwner/$repoName/actions/runs?per_page=5" -Headers $headers -Method Get
                $matchedRun = $runsResponse.workflow_runs | Where-Object {
                    ($_.head_branch -eq $targetBranch -or $_.head_branch -eq $tagName) -and
                    ($_.status -eq "queued" -or $_.status -eq "in_progress")
                } | Select-Object -First 1

                if ($matchedRun) {
                    $runId = $matchedRun.id
                    $runUrl = $matchedRun.html_url
                    break
                }
            } catch {}
            Start-Sleep -Seconds 3
        }
    }

    Write-Host "`n======================================================================" -ForegroundColor Green
    Write-Host "  🚀 TestFlight Build Triggered Successfully!" -ForegroundColor Green
    Write-Host "  🏷️  Tag:      $tagName" -ForegroundColor Cyan
    Write-Host "  🌿 Branch:   $targetBranch" -ForegroundColor Cyan
    Write-Host "  🔗 Live Run: $runUrl" -ForegroundColor Yellow
    Write-Host "======================================================================`n" -ForegroundColor Green

    if ($NoWait -or -not $runId -or -not $token) {
        Write-Host "💡 Build is executing on GitHub Actions macOS runner." -ForegroundColor DarkGray
        Write-Host "   Open the link above to watch live Xcode logs or download the IPA.`n" -ForegroundColor DarkGray
        exit 0
    }

    # Optional: Live Status Polling
    Write-Host "⏳ Following live build progress (Press Ctrl+C to disconnect anytime without stopping build)...`n" -ForegroundColor DarkGray
    $startTime = Get-Date

    while ($true) {
        Start-Sleep -Seconds 15
        try {
            $runStatus = Invoke-RestMethod -Uri "https://api.github.com/repos/$repoOwner/$repoName/actions/runs/$runId" -Headers $headers -Method Get
            $elapsed = (Get-Date) - $startTime
            $elapsedStr = "{0:D2}m {1:D2}s" -f [int]$elapsed.TotalMinutes, $elapsed.Seconds

            $statusText = $runStatus.status
            $conclusion = $runStatus.conclusion

            if ($statusText -eq "completed") {
                if ($conclusion -eq "success") {
                    Write-Host "`n🎉 SUCCESS! ($elapsedStr)" -ForegroundColor Green
                    Write-Host "   The iOS IPA was successfully signed and uploaded to Apple TestFlight!" -ForegroundColor Green
                    Write-Host "   Apple processing usually takes 5-10 minutes before appearing on your device.`n" -ForegroundColor Cyan
                } else {
                    Write-Host "`n❌ Workflow completed with result: $conclusion ($elapsedStr)" -ForegroundColor Red
                    Write-Host "   Inspect logs at: $runUrl`n" -ForegroundColor Yellow
                }
                break
            } else {
                # Get current step
                try {
                    $jobsResponse = Invoke-RestMethod -Uri "https://api.github.com/repos/$repoOwner/$repoName/actions/runs/$runId/jobs" -Headers $headers -Method Get
                    $currentStep = $jobsResponse.jobs[0].steps | Where-Object { $_.status -eq "in_progress" } | Select-Object -First 1
                    $stepName = if ($currentStep) { $currentStep.name } else { "Building..." }
                    Write-Host "  [$elapsedStr] Status: $statusText | Current Step: $stepName" -ForegroundColor Gray
                } catch {
                    Write-Host "  [$elapsedStr] Status: $statusText..." -ForegroundColor Gray
                }
            }
        } catch {
            Write-Host "  [Poll error, retrying...]" -ForegroundColor DarkGray
        }
    }
} finally {
    Pop-Location
}
