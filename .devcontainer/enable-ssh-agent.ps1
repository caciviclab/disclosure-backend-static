# To use git in the dev container, you have to enable ssh agent on Windows.  Try running the following in a PowerShell as Administrator.
# Make sure you're running as an Administrator
Set-Service ssh-agent -StartupType Automatic
Start-Service ssh-agent
Get-Service ssh-agent
