param
(
    [Parameter(Mandatory=$true)]
    [string]$RequestType,
    [string]$SubID,
    [string]$EnvType,
    [string]$ResType
)

$ErrorActionPreference = "SilentlyContinue" 
$WarningPreference = "SilentlyContinue"
$Sub_WhiteList = (Get-AutomationVariable -Name 'Sub_Whitelist') -split ','
$MgtGroupList = (Get-AutomationVariable -Name 'Mgt_GroupList') -split ','


try {
    Connect-AzAccount -Environment AzureChinaCloud -Identity | Out-Null -ErrorAction Stop
}
catch {
    Write-Error -Message $_.ErrorDetails
}
function GetSubList {
    param (
        $EnvType
    )
    Write-Output "Sundown application subscriptions will not contained."
    if ( $EnvType.Replace(‘ ’,‘’) -eq '') { 
        foreach ($CurEnv in $MgtGroupList) {
            Get-AzManagementGroup -GroupName $CurEnv -Expand -Recurse | ForEach-Object {$_.Children} | Where-Object -FilterScript { $_.Name -notin $Sub_WhiteList}
        }
    }else{
        foreach ($CurEnv in ($EnvType -split ',')) {
            Get-AzManagementGroup -GroupName $CurEnv -Expand -Recurse | ForEach-Object {$_.Children} | Where-Object -FilterScript { $_.Name -notin $Sub_WhiteList}
    }
    }    
}

function GetBasicBlob{
    param(
        [string]$SubID,
        [string]$EnvType
    )
    foreach ( $Sub in ($SubID -split ',') ) {
        Set-AzContext -SubscriptionId  $Sub | Out-Null
        if ($EnvType.Replace(' ','' ) -eq '') {
            Get-AzStorageAccount | Where-Object -FilterScript {$_.StorageAccountName -like '*29' -or $_.StorageAccountName -like '*30'}
        }else {
            foreach ( $Env in ( $EnvType -split ',') ) {
                Get-AzStorageAccount | Where-Object -FilterScript {$_.StorageAccountName -like $Env -and ($_.StorageAccountName -like '*29' -or $_.StorageAccountName -like '*30')}
            }
        }
    }
}


（$item in $collection）  100 

function GetVMList {
    param (
        [string]$SubID,
        [string]$EnvType
    )
    foreach ($Sub in ($SubID -split ',')) {
        Set-AzContext -SubscriptionId $Sub | Out-Null
        if ($EnvType.Replace(' ','' ) -ne '') {
            foreach ($Env in ( $EnvType -split ',' )) {
                Get-AzVM | Where-Object -FilterScript { $_.Name -like $Env } | ForEach-Object { Get-AzVM -ResourceGroupName $_.ResourceGroupName -Name $_.Name }
            }else{
                Get-AzVM | ForEach-Object { Get-AzVM -ResourceGroupName $_.ResourceGroupName -Name $_.Name }
            }
        }
    }
}

function GetStorageAccount{
    param(
        [string]$SubID,
        [string]$EnvType
    )
    foreach ( $Sub in ($SubID -split ',') ) {
        Set-AzContext -SubscriptionId  $Sub | Out-Null
        if ($EnvType.Replace(' ','' ) -eq '') {
            Get-AzStorageAccount 
        }else {
            foreach ( $Env in ( $EnvType -split ',') ) {
                Get-AzStorageAccount | Where-Object -FilterScript {$_.StorageAccountName -like $Env }
            }
        }
    }
}

function CallFeature{
    param (
        [string]$RequestType,
        [string]$SubID,
        [string]$EnvType,
        [string]$ResType
    )
    if ( $RequestType -eq "SubList" ) {
        GetSubList $EnvType
    }elseif ($RequestType -eq "ResInfor" -and $ResType -eq "BasicBlob") {
        GetBasicBlob $SubID $EnvType
    }elseif ($RequestType -eq "ResInfor" -and $ResType -eq "VMList") {
        GetVMList $SubID $EnvType
    }elseif ($RequestType -eq "ResInfor" -and $ResType -eq "StorageAccount") {
        GetStorageAccount $SubID $EnvType
    }
}

function InputCheck{
    param (
        [string]$RequestType,
        [string]$SubID,
        [string]$EnvType,
        [string]$ResType
    )
    if ($RequestType -ne 'ResInfor' -and $RequestType -ne 'SubList'){
        Write-Output "Unknow RequestType,The supported RequestType should be ResInfor or SubList."
        Exit-PSHostProcess
    }elseif ( $RequestType -eq "ResInfor" -and $ResType.Replace(' ','' ) -eq '') {
        Write-Output "No Restype found. runbook existed. The supported Restype should be BasicBlob,LogAWorkSpace,BackupVault,VMList,ResGrpList and SubTags."
        Exit-PSHostProcess
    }elseif ( $RequestType -eq "ResInfor" -and $SubID.Replace(' ','' ) -eq '') {
        Write-Output "No SubID found, runbook existed."
        Exit-PSHostProcess
    }else { 
        if ($EnvType.Replace(' ','' ) -eq '') {
            Write-Output "No EnvType specified, will get all resources in the Sub or show all the Sub in ITT management group."
        } 
        CallFeature $RequestType $SubID $EnvType $ResType
    }
}

InputCheck $RequestType $SubID $EnvType $ResType