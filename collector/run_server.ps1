# Starts the Vreteno backend (collector + clustering + JSON API) and logs to server.log.
# Used by the "Vreteno server" scheduled task (see README); can also be run by hand.
Set-Location -Path $PSScriptRoot
python -u server.py *> server.log
