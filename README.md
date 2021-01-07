# LogCampaign
Provides detection capabilities and log conversion to evtx or syslog capabilities

## Quickstart
Download this github repo to a Windows box. Also, download autoruns binaries and place them in the Binaries folder. Then run the following

```powershell
Get-ChildItem . -Recurse | Unblock-File
.\log_campaign.ps1
.\log_campaign.ps1 -ListCampaigns
.\log_campaign.ps1 -Campaign Autoruns
```
