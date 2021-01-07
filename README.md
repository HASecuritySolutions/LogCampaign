# LogCampaign
Provides detection capabilities and log conversion to evtx or syslog capabilities

## Quickstart
Download this github repo to a Windows box. Also, download autoruns binaries (https://docs.microsoft.com/en-us/sysinternals/downloads/autoruns) and place them in the Binaries folder. Then run the following:

```powershell
Get-ChildItem . -Recurse | Unblock-File
.\log_campaign.ps1
.\log_campaign.ps1 -ListCampaigns
.\log_campaign.ps1 -Campaign Autoruns
```

If you are looking to only log differences from one campaign to another, try this instead:

```powershell
.\log_campaign.ps1 -Campaign Autoruns -Diff
```

**-Diff** will only log when there are changes from the last run compared to the most recent run. For example, log autoruns information daily. Then find differences and ship those to a SIEM for long tail analysis.
