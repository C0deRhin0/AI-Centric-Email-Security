<# 
.SYNOPSIS
    ESL Automation — n8n Setup Script (Windows)
.DESCRIPTION
    Installs n8n and configures it for the ESL email security automation workflow.
    Optionally sets up Windows Task Scheduler for auto-start on login.
.NOTES
    Version: 1.0
    Author: ESL Automation Project
#>

Write-Host "============================================" -ForegroundColor Blue
Write-Host "  ESL Automation — n8n Setup Script" -ForegroundColor Blue
Write-Host "============================================" -ForegroundColor Blue
Write-Host ""

# ----------------------------------------------------------
# Step 1: Check for Node.js
# ----------------------------------------------------------
Write-Host "[1/5] Checking Node.js installation..." -ForegroundColor Yellow

try {
    $nodeVersion = node --version
    Write-Host "  ✓ Node.js found: $nodeVersion" -ForegroundColor Green
} catch {
    Write-Host "  ✗ Node.js is not installed." -ForegroundColor Red
    Write-Host "  Please install Node.js LTS from: https://nodejs.org"
    Write-Host "  After installing, restart PowerShell and run this script again."
    exit 1
}

# Extract major version
$nodeMajor = [int]($nodeVersion -replace '[v.]', '').Substring(0, 2)
if ($nodeMajor -lt 18) {
    Write-Host "  ✗ Node.js 18+ is required. Found version $nodeVersion" -ForegroundColor Red
    exit 1
}

# ----------------------------------------------------------
# Step 2: Install n8n globally
# ----------------------------------------------------------
Write-Host "[2/5] Installing n8n globally..." -ForegroundColor Yellow

try {
    npm install -g n8n
    Write-Host "  ✓ n8n installed successfully" -ForegroundColor Green
} catch {
    Write-Host "  ✗ Failed to install n8n. Error: $_" -ForegroundColor Red
    exit 1
}

# ----------------------------------------------------------
# Step 3: Verify installation
# ----------------------------------------------------------
Write-Host "[3/5] Verifying n8n installation..." -ForegroundColor Yellow

try {
    $n8nCheck = Get-Command n8n -ErrorAction Stop
    Write-Host "  ✓ n8n is installed at: $($n8nCheck.Source)" -ForegroundColor Green
} catch {
    Write-Host "  ✗ n8n command not found after install" -ForegroundColor Red
    Write-Host "  Check your npm global path: npm root -g"
    exit 1
}

# ----------------------------------------------------------
# Step 4: Set up Windows Task Scheduler (optional)
# ----------------------------------------------------------
Write-Host "[4/5] Windows Task Scheduler setup (optional)..." -ForegroundColor Yellow

$setupTask = Read-Host "  Do you want n8n to start automatically when you log in? (y/n)"

if ($setupTask -eq 'y' -or $setupTask -eq 'Y') {
    $taskName = "Start n8n on Login"
    $taskExists = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue

    if ($taskExists) {
        Write-Host "  ⚠ Task '$taskName' already exists." -ForegroundColor Yellow
        $overwrite = Read-Host "  Overwrite? (y/n)"
        if ($overwrite -ne 'y' -and $overwrite -ne 'Y') {
            Write-Host "  ⏭ Skipping Task Scheduler setup." -ForegroundColor Yellow
        } else {
            Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
        }
    }

    # Get the full path to n8n.cmd
    $n8nPath = (Get-Command n8n).Source

    $action = New-ScheduledTaskAction -Execute "cmd.exe" -Argument "/c $n8nPath"
    $trigger = New-ScheduledTaskTrigger -AtLogon
    $principal = New-ScheduledTaskPrincipal -UserId "$env:USERDOMAIN\$env:USERNAME" -LogonType S4U -RunLevel Limited

    Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Principal $principal -Force

    if ($?) {
        Write-Host "  ✓ Task Scheduler entry created: '$taskName'" -ForegroundColor Green
        Write-Host "  n8n will start automatically when you log in." -ForegroundColor Green
    } else {
        Write-Host "  ✗ Failed to create scheduled task." -ForegroundColor Red
    }
} else {
    Write-Host "  ⏭ Skipping Task Scheduler setup." -ForegroundColor Yellow
    Write-Host "  To set up later, run this script again or configure manually:"
    Write-Host "  - Open Task Scheduler → Create Basic Task"
    Write-Host "  - Trigger: At log on"
    Write-Host "  - Action: Start cmd.exe with argument '/c n8n'"
}

# ----------------------------------------------------------
# Step 5: Final instructions
# ----------------------------------------------------------
Write-Host "[5/5] Setup complete!" -ForegroundColor Yellow
Write-Host ""
Write-Host "  Quick start instructions:" -ForegroundColor Green
Write-Host "  ─────────────────────────" -ForegroundColor Green
Write-Host ""
Write-Host "  1. Start n8n:" -ForegroundColor White
Write-Host "     n8n"
Write-Host ""
Write-Host "  2. Open n8n editor:" -ForegroundColor White
Write-Host "     http://localhost:5678"
Write-Host ""
Write-Host "  3. Create your local account:" -ForegroundColor White
Write-Host "     Enter any email and password (local only)"
Write-Host ""
Write-Host "  4. Import the ESL workflow:" -ForegroundColor White
Write-Host "     In n8n: Workflows → Import from File"
Write-Host "     Select: approach-b-n8n/workflow.json"
Write-Host ""
Write-Host "  5. Configure OAuth for Outlook:" -ForegroundColor White
Write-Host "     See: docs/oauth-setup.md"
Write-Host "     You will need IT Admin consent for the Azure App Registration"
Write-Host ""
Write-Host "  6. Set up templates:" -ForegroundColor White
Write-Host "     All 4 HTML templates are in: approach-b-n8n/templates/"
Write-Host "     These are built into the imported workflow"
Write-Host ""
Write-Host "============================================" -ForegroundColor Blue
Write-Host "  n8n setup complete! Happy automating! 🚀" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Blue

pause
