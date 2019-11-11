function GetUrl() {
    param(
        [string]$orgUrl,
        [hashtable]$header,
        [string]$AreaId
    )

    # Build the URL for calling the org-level Resource Areas REST API for the RM APIs
    $orgResourceAreasUrl = [string]::Format("{0}/_apis/resourceAreas/{1}?api-preview=5.0-preview.1", $orgUrl, $AreaId)

    # Do a GET on this URL (this returns an object with a "locationUrl" field)
    $results = Invoke-RestMethod -Uri $orgResourceAreasUrl -Headers $header

    # The "locationUrl" field reflects the correct base URL for RM REST API calls
    if ("null" -eq $results) {
        $areaUrl = $orgUrl
    }
    else {
        $areaUrl = $results.locationUrl
    }

    return $areaUrl
}

$orgUrl = "https://dev.azure.com/"
$personalToken = ""

Write-Host "Initialize authentication context" -ForegroundColor Yellow
$token = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes(":$($personalToken)"))
$header = @{authorization = "Basic $token"}

# Area ids
# https://docs.microsoft.com/en-us/azure/devops/extend/develop/work-with-urls?view=azure-devops&tabs=http&viewFallbackFrom=vsts#resource-area-ids-reference

# DEMO 1 List of projects
Write-Host "Demo 1"
$coreAreaId = "79134c72-4a58-4b42-976c-04e7115f32bf"
$tfsBaseUrl = GetUrl -orgUrl $orgUrl -header $header -AreaId $coreAreaId

# https://docs.microsoft.com/en-us/rest/api/azure/devops/core/projects/list?view=azure-devops-rest-5.0
$projectsUrl = "$($tfsBaseUrl)_apis/projects?api-version=5.0"

$projects = Invoke-RestMethod -Uri $projectsUrl -Method Get -ContentType "application/json" -Headers $header

$projects.value | ForEach-Object {
    Write-Host $_.name
}

# DEMO 2 List of release definitions
Write-Host "Demo 2"
$projects.value | ForEach-Object {
    $project = $_.name
    $releaseManagementAreaId = "efc2f575-36ef-48e9-b672-0c6fb4a48ac5"
    $tfsBaseUrl = GetUrl -orgUrl $orgUrl -header $header -AreaId $releaseManagementAreaId

    # https://docs.microsoft.com/en-us/rest/api/azure/devops/release/definitions/list?view=azure-devops-rest-5.0
    $relDefUrl = "$tfsBaseUrl/$project/_apis/release/definitions?api-version=5.0"
    $result = Invoke-RestMethod $relDefUrl -Method Get -ContentType "application/json" -Headers $header
    $relDefs = $result.value

    if($relDefs.count -gt 0){
        Write-Host "$project $($relDefs.count) release def founds" -ForegroundColor Blue
        $relDefs | ForEach-Object {
            Write-host "`t$($_.name)" -ForegroundColor Green
        }
    }
}

# DEMO 3 List of releases for a given release definition
Write-Host "Demo 3"
$projects.value | ForEach-Object {
    $project = $_.name
    $releaseManagementAreaId = "efc2f575-36ef-48e9-b672-0c6fb4a48ac5"
    $tfsBaseUrl = GetUrl -orgUrl $orgUrl -header $header -AreaId $releaseManagementAreaId

    # https://docs.microsoft.com/en-us/rest/api/azure/devops/release/definitions/list?view=azure-devops-rest-5.0
    $relDefUrl = "$tfsBaseUrl/$project/_apis/release/definitions?api-version=5.0"
    $result = Invoke-RestMethod $relDefUrl -Method Get -ContentType "application/json" -Headers $header
    $relDefs = $result.value

    if($relDefs.count -gt 0){
        Write-Host "$project $($relDefs.count) release def founds" -ForegroundColor Blue
        $relDefs | ForEach-Object {
            $relDefId = $_.id
            Write-host "`t$($_.name)" -ForegroundColor Green

            # https://docs.microsoft.com/en-us/rest/api/azure/devops/release/releases/list?view=azure-devops-rest-5.0
            $relsUrl = "$tfsBaseUrl/$project/_apis/release/releases?definitionId=$relDefId&releaseCount=5&api-version=5.0"
            $result = Invoke-RestMethod $relsUrl -Method Get -ContentType "application/json" -Headers $header
            $rels = $result.releases

            if($rels.count -gt 0){
                Write-Host "`t`t$($rels.count) releases found" -ForegroundColor Blue
                $rels | ForEach-Object {
                    $rel = $_
                    Write-Host "`t`t`t$($rel.name)"
                }
            }
        }
    }
}

# DEMO 4 List of approvers for a release environment
Write-Host "Demo 4"
$projects.value | ForEach-Object {
    $project = $_.name
    $releaseManagementAreaId = "efc2f575-36ef-48e9-b672-0c6fb4a48ac5"
    $tfsBaseUrl = GetUrl -orgUrl $orgUrl -header $header -AreaId $releaseManagementAreaId

    # https://docs.microsoft.com/en-us/rest/api/azure/devops/release/definitions/list?view=azure-devops-rest-5.0
    $relDefUrl = "$tfsBaseUrl/$project/_apis/release/definitions?api-version=5.0"
    $result = Invoke-RestMethod $relDefUrl -Method Get -ContentType "application/json" -Headers $header
    $relDefs = $result.value

    if($relDefs.count -gt 0){
        Write-Host "$project $($relDefs.count) release def founds" -ForegroundColor Blue
        $relDefs | ForEach-Object {
            $relDefId = $_.id
            Write-host "`t$($_.name)" -ForegroundColor Green

            # https://docs.microsoft.com/en-us/rest/api/azure/devops/release/releases/list?view=azure-devops-rest-5.0
            $relsUrl = "$tfsBaseUrl/$project/_apis/release/releases?definitionId=$relDefId&releaseCount=5&api-version=5.0"
            $result = Invoke-RestMethod $relsUrl -Method Get -ContentType "application/json" -Headers $header
            $rels = $result.releases

            if($rels.count -gt 0){
                Write-Host "`t`t$($rels.count) releases found" -ForegroundColor Blue
                $rels | ForEach-Object {
                    $rel = $_
                    $rel.Environments | ForEach-Object {
                        $envName = $_.name
                        #Write-Host "        $envName" -ForegroundColor Green
                        $env = $_
                        $env.preDeployApprovals | ForEach-Object {
                            $approval = $_
                            if (-not $approval.isAutomated -and $approval.status -eq "approved") {
                                Write-host "`t`t`tRelease $($rel.name) ($envName) was approved By $($approval.approvedBy.displayName) on $($approval.modifiedOn)" -ForegroundColor Green
                            }
                        }
                    }
                }
            }
        }
    }
}

# DEMO 5 Update an environement release variable
Write-Host "Demo 5"


$projects.value | ForEach-Object {
    $project = $_.name
    $releaseManagementAreaId = "efc2f575-36ef-48e9-b672-0c6fb4a48ac5"
    $tfsBaseUrl = GetUrl -orgUrl $orgUrl -header $header -AreaId $releaseManagementAreaId

    # https://docs.microsoft.com/en-us/rest/api/azure/devops/release/definitions/list?view=azure-devops-rest-5.0
    $relDefUrl = "$tfsBaseUrl/$project/_apis/release/definitions?api-version=5.0"
    $result = Invoke-RestMethod $relDefUrl -Method Get -ContentType "application/json" -Headers $header
    $relDefs = $result.value

    if($relDefs.count -gt 0){
        Write-Host "$project $($relDefs.count) release def founds" -ForegroundColor Blue
        $relDefs | ForEach-Object {
            $relDef = $_
            # https://docs.microsoft.com/en-us/rest/api/azure/devops/release/definitions/get?view=azure-devops-rest-5.0
            $relDefExpanded = Invoke-RestMethod "$($relDef.url)?`$Expand=Environments&api-version=5.0" -Method Get -ContentType "application/json" -Headers $header <#
            $relDefExpanded.environments | ForEach-Object {
                $env = $_
                if ($null -ne $env.variables.DEMO) {
                    Write-host "Variable value before: $($env.variables.DEMO.value)" -ForegroundColor Green
                    $env.variables.DEMO.value = "New Value"
                }
                $body = $relDefExpanded | ConvertTo-Json -Depth 100 -Compress
                $body = [System.Text.Encoding]::UTF8.GetBytes($body)
                # https://docs.microsoft.com/en-us/rest/api/azure/devops/release/definitions/update?view=azure-devops-rest-5.0
                $updateResult = Invoke-RestMethod "$($relDef.url)?api-version=5.0" -Method Put -ContentType "application/json" -body $body -Headers $header 
                Write-host "Variable value after: $($updateResult.environments.variables.DEMO.value)" -ForegroundColor Green
            } #>
        }
    }
}



<#
# DEMO 6 Update a work item title
Write-Host "Demo 6"


$workAreaId = "1d4f49f9-02b9-4e26-b826-2cdb6195f2a9"
$tfsBaseUrl = GetUrl -orgUrl $orgUrl -header $header -AreaId $workAreaId

$workItemId = 1
# https://docs.microsoft.com/en-us/rest/api/azure/devops/wit/work%20items/get%20work%20item?view=azure-devops-rest-5.0
$wisUrl = "$($tfsBaseUrl)/Demos/_apis/wit/workitems/$($workItemId)?api-version=5.0"

$workitem = Invoke-RestMethod -Uri $wisUrl -Method Get -ContentType "application/json" -Headers $header
Write-Host "Before: $($workitem.fields.'System.Title')"

$body = @"
[
  {
    "op": "add",
    "path": "/fields/System.Title",
    "value": "$($workitem.fields.'System.Title')+DEMO"
  },
  {
    "op": "add",
    "path": "/fields/System.History",
    "value": "Changing Title"
  }
]
"@


# $workitem = Invoke-RestMethod -Uri $wisUrl -Method Patch -ContentType "application/json-patch+json" -Headers $header -Body $body
# Write-Host "After: $($workitem.fields.'System.Title')"


#>

$body = @'
{
    "source": "restApi",
    "description": "Test Description",
    "createdBy": {
        "displayName": "JSON API Test",
        "url": "https://spsprodeau1.vssps.visualstudio.com/A570ed644-76a0-48c9-bba8-08cf2d1a912a/_apis/Identities/ea013986-0de7-6675-8d2e-70905d2c5cf1",
        "_links": {
            "avatar": {
                "href": "https://dev.azure.com/msdtestdevops/_apis/GraphProfile/MemberAvatars/msa.ZWEwMTM5ODYtMGRlNy03Njc1LThkMmUtNzA5MDVkMmM1Y2Yx"
            }
        },
        "descriptor": "msa.ZWEwMTM5ODYtMGRlNy03Njc1LThkMmUtNzA5MDVkMmM1Y2Yx"
    },
    "environments": [
        {
            "id": "restApi",
            "name": "Stage 1",
            "rank": 1,
            "owner": {
                "displayName": "JSON API Test",
                "url": "https://spsprodeau1.vssps.visualstudio.com/A570ed644-76a0-48c9-bba8-08cf2d1a912a/_apis/Identities/ea013986-0de7-6675-8d2e-70905d2c5cf1",
                "_links": {
                    "avatar": {
                        "href": "https://dev.azure.com/msdtestdevops/_apis/GraphProfile/MemberAvatars/msa.ZWEwMTM5ODYtMGRlNy03Njc1LThkMmUtNzA5MDVkMmM1Y2Yx"
                    }
                },
                "descriptor": "msa.ZWEwMTM5ODYtMGRlNy03Njc1LThkMmUtNzA5MDVkMmM1Y2Yx"
            },
            "preDeployApprovals": {
                "approvals": [
                    {
                        "rank": 1,
                        "isAutomated": true,
                        "isNotificationOn": false,
                        "id": 22
                    }
                ],
                "approvalOptions": {
                    "requiredApproverCount": null,
                    "releaseCreatorCanBeApprover": false,
                    "autoTriggeredAndPreviousEnvironmentApprovedCanBeSkipped": false,
                    "enforceIdentityRevalidation": false,
                    "timeoutInMinutes": 0,
                    "executionOrder": 1
                }
            },
            "deployStep": {
                "id": 23
            },
            "postDeployApprovals": {
                "approvals": [
                    {
                        "rank": 1,
                        "isAutomated": true,
                        "isNotificationOn": false,
                        "id": 24
                    }
                ],
                "approvalOptions": {
                    "requiredApproverCount": null,
                    "releaseCreatorCanBeApprover": false,
                    "autoTriggeredAndPreviousEnvironmentApprovedCanBeSkipped": false,
                    "enforceIdentityRevalidation": false,
                    "timeoutInMinutes": 0,
                    "executionOrder": 2
                }
            },
            "deployPhases": [
                {
                    "deploymentInput": {
                        "parallelExecution": {
                            "parallelExecutionType": 0
                        },
                        "agentSpecification": {
                            "identifier": "vs2017-win2016"
                        },
                        "skipArtifactsDownload": false,
                        "artifactsDownloadInput": {
                            "downloadInputs": []
                        },
                        "queueId": 9,
                        "demands": [],
                        "enableAccessToken": false,
                        "timeoutInMinutes": 0,
                        "jobCancelTimeoutInMinutes": 1,
                        "condition": "succeeded()",
                        "overrideInputs": {}
                    },
                    "rank": 1,
                    "phaseType": 1,
                    "name": "Agent job",
                    "refName": null,
                    "workflowTasks": [
                        {
                            "environment": {},
                            "taskId": "e213ff0f-5d5c-4791-802d-52ea3e7be1f1",
                            "version": "2.*",
                            "name": "PowerShell Script",
                            "refName": "",
                            "enabled": true,
                            "alwaysRun": false,
                            "continueOnError": false,
                            "timeoutInMinutes": 0,
                            "definitionType": "task",
                            "overrideInputs": {},
                            "condition": "succeeded()",
                            "inputs": {
                                "targetType": "inline",
                                "filePath": "",
                                "arguments": "",
                                "script": "# Purpose: This script performs the deployment of the SSIS solution to the Azure DB\n# In-Parameters:\n# \t- etl_password_param: password of the SSISDB object\n\n#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------\n\n#Parameter to retrieve encrypted password\n#Param\n#(\n#   [string]\"H7787@kdskdjksj1\"\n#)\n\n# Variables\n$ProjectFilePath = \"$(System.DefaultWorkingDirectory)/_ssisdemo/drop/03-claims_migration/ETL/bin/Development/ETL.ispac\"\n$SSISDBServerEndpoint = \"azdevopsdeploy.database.windows.net\"\n$SSISDBServerAdminUserName = \"azdevopsdeploy\"\n$SSISDBServerAdminPassword = \"H7787@kdskdjksj1\"\n$SSISFolderName = \"SSISDBFolder\"\n$SSISDescription = \"SSISDBFolder\"\n\nWrite-Host \"**********************************************************\"\nWrite-Host \"*******************  Script starts  **********************\"\nWrite-Host \"**********************************************************\"\n\n# Load the IntegrationServices Assembly\n[System.Reflection.Assembly]::LoadWithPartialName(\"Microsoft.SqlServer.Management.IntegrationServices\") | Out-Null;\n\n# Store the IntegrationServices Assembly namespace to avoid typing it every time\n$ISNamespace = \"Microsoft.SqlServer.Management.IntegrationServices\"\n\nWrite-Host \"Connecting to SSIS Instance server ...\"\n\n# Create a connection to the server\n$sqlConnectionString = \"Data Source=\" + $SSISDBServerEndpoint + \";User ID=\"+ $SSISDBServerAdminUserName +\";Password=\"+ $SSISDBServerAdminPassword + \";Initial Catalog=SSISDB\"\n$sqlConnection = New-Object System.Data.SqlClient.SqlConnection $sqlConnectionString\n\nWrite-Host \"slq connection set:\" $sqlConnection\n\n# Create the Integration Services object\n$integrationServices = New-Object $ISNamespace\".IntegrationServices\" $sqlConnection\n\nWrite-Host \"Integration Services object set:\" $integrationServices\n\n# Get the catalog\n$catalog = $integrationServices.Catalogs['SSISDB']\nWrite-Host \"The catalog is:\" $catalog\n\n$ssisFolder = $catalog.Folders.Item($SSISFolderName)\nWrite-Host \"SSIS Folder is:\" $ssisFolder\n\n# Verify if we have already this folder\nif (!$ssisFolder)\n{\n    write-host \"Create folder on Catalog SSIS instance\"\n    $folder = New-Object Microsoft.SqlServer.Management.IntegrationServices.CatalogFolder($catalog, $SSISFolderName, $SSISDescription) \n\twrite-host \"New folder on catalog:\" $folder\n    $folder.Create()\n    $ssisFolder = $catalog.Folders.Item($SSISFolderName)\n\twrite-host \"Newly created SSIS folder:\" $ssisFolder\n}\n\nwrite-host \"Enumerating all folders in the project code\"\n\n$folders = ls -Path $ProjectFilePath -File\nwrite-host \"The folders in the project code are:\" $folders\n\n# If we have some folders to treat\nif ($folders.Count -gt 0)\n{\n\t#Treat one by one them\n    foreach ($filefolder in $folders)\n    {\n\t\twrite-host \"File folder:\" $filefolder\n        $projects = ls -Path $filefolder.FullName -File -Filter *.ispac\n\t\twrite-host \"Projects:\" $projects\n        if ($projects.Count -gt 0)\n        {\n            foreach($projectfile in $projects)\n            {\n\t\t\t\twrite-host \"Project File:\" $projectfile\n\t\t\t\twrite-host \"ISPAC File ==> \"$projectfile.Name.Replace(\".ispac\", \"\")\n                write-host \"Project File Name Fullname ==> \"$projectfile.FullName\n\t\t\t\t\n\t\t\t\t$projectfilename = $projectfile.Name.Replace(\".ispac\", \"\")\n\t\t\t\t$ssisProject = $ssisFolder.Projects.Item($projectfilename)\n                write-host \"SSIS project:\" $ssisProject\n                # Dropping old project \n                if(![string]::IsNullOrEmpty($ssisProject))\n                {\n                    write-host \"Drop Old SSIS Project ==> \"$ssisProject.Name\n                    $ssisProject.Drop()\n                }\n\n                Write-Host \"Deploying \" $projectfilename \" project ...\"\n\n                # Read the project file, and deploy it to the folder\n                [byte[]] $projectFileContent = [System.IO.File]::ReadAllBytes($projectfile.FullName)\n\t\t\t\twrite-host \"Project File Content:\" $projectfile.FullName\n                $ssisFolder.DeployProject($projectfilename, $projectFileContent)\n            }\n        }\n    }\n}\n\nWrite-Host \"All done.\"",
                                "errorActionPreference": "continue",
                                "failOnStderr": "false",
                                "ignoreLASTEXITCODE": "false",
                                "pwsh": "false",
                                "workingDirectory": ""
                            }
                        }
                    ]
                }
            ],
            "environmentOptions": {
                "emailNotificationType": "OnlyOnFailure",
                "emailRecipients": "release.environment.owner;release.creator",
                "skipArtifactsDownload": false,
                "timeoutInMinutes": 0,
                "enableAccessToken": false,
                "publishDeploymentStatus": true,
                "badgeEnabled": false,
                "autoLinkWorkItems": false,
                "pullRequestDeploymentEnabled": false
            },
            "demands": [],
            "conditions": [
                {
                    "name": "ReleaseStarted",
                    "conditionType": 1,
                    "value": ""
                }
            ],
            "executionPolicy": {
                "concurrencyCount": 1,
                "queueDepthCount": 0
            },
            "schedules": [],
            "currentRelease": {
                "id": 26,
                "url": "https://vsrm.dev.azure.com/msdtestdevops/a181d34e-541d-472b-b477-f42d392f64b7/_apis/Release/releases/26",
                "_links": {}
            },
            "retentionPolicy": {
                "daysToKeep": 30,
                "releasesToKeep": 3,
                "retainBuild": true
            },
            "processParameters": {},
            "properties": {
                "BoardsEnvironmentType": {
                    "$type": "System.String",
                    "$value": "unmapped"
                },
                "LinkBoardsWorkItems": {
                    "$type": "System.String",
                    "$value": "False"
                }
            },
            "preDeploymentGates": {
                "id": 0,
                "gatesOptions": null,
                "gates": []
            },
            "postDeploymentGates": {
                "id": 0,
                "gatesOptions": null,
                "gates": []
            },
            "environmentTriggers": [],
            "badgeUrl": "https://vsrm.dev.azure.com/msdtestdevops/_apis/public/Release/badge/a181d34e-541d-472b-b477-f42d392f64b7/8/8"
        }
    ],
    "artifacts": [
        {
            "sourceId": "a181d34e-541d-472b-b477-f42d392f64b7:24",
            "type": "Build",
            "alias": "_ssisdemo",
            "definitionReference": {
                "artifactSourceDefinitionUrl": {
                    "id": "https://dev.azure.com/msdtestdevops/_permalink/_build/index?collectionId=fd174a4a-63b7-4db9-ae36-dadaac3eca24&projectId=a181d34e-541d-472b-b477-f42d392f64b7&definitionId=24",
                    "name": ""
                },
                "defaultVersionBranch": {
                    "id": "",
                    "name": ""
                },
                "defaultVersionSpecific": {
                    "id": "",
                    "name": ""
                },
                "defaultVersionTags": {
                    "id": "",
                    "name": ""
                },
                "defaultVersionType": {
                    "id": "latestType",
                    "name": "Latest"
                },
                "definition": {
                    "id": "24",
                    "name": "ssisdemo"
                },
                "definitions": {
                    "id": "",
                    "name": ""
                },
                "IsMultiDefinitionType": {
                    "id": "False",
                    "name": "False"
                },
                "project": {
                    "id": "a181d34e-541d-472b-b477-f42d392f64b7",
                    "name": "test"
                },
                "repository": {
                    "id": "",
                    "name": ""
                }
            },
            "isPrimary": true,
            "isRetained": false
        }
    ],
    "triggers": [],
    "releaseNameFormat": "hdkhfjkhfjkhfjkhfsdhfjkhfjkfhjkedh",
    "tags": [],
    "properties": {
        "DefinitionCreationSource": {
            "$type": "System.String",
            "$value": "ReleaseNew"
        },
        "IntegrateBoardsWorkItems": {
            "$type": "System.String",
            "$value": "False"
        },
        "IntegrateJiraWorkItems": {
            "$type": "System.String",
            "$value": "false"
        }
    },
    "name": "TALReleaseAPITest",
    "path": "\\",
    "projectReference": null,
    "url": "https://vsrm.dev.azure.com/msdtestdevops/a181d34e-541d-472b-b477-f42d392f64b7/_apis/Release/definitions/8",
    "_links": {
        "self": {
            "href": "https://vsrm.dev.azure.com/msdtestdevops/a181d34e-541d-472b-b477-f42d392f64b7/_apis/Release/definitions/8"
        },
        "web": {
            "href": "https://dev.azure.com/msdtestdevops/a181d34e-541d-472b-b477-f42d392f64b7/_release?definitionId=8"
        }
    }
}
'@

# DEMO 3 List of releases for a given release definition
Write-Host "Demo Post Release Definition"
$projects.value | ForEach-Object {
    $project = $_.name
    $releaseManagementAreaId = "efc2f575-36ef-48e9-b672-0c6fb4a48ac5"
    $tfsBaseUrl = GetUrl -orgUrl $orgUrl -header $header -AreaId $releaseManagementAreaId

    # https://docs.microsoft.com/en-us/rest/api/azure/devops/release/definitions/list?view=azure-devops-rest-5.0
    $relDefUrl = "$tfsBaseUrl/$project/_apis/release/definitions?api-version=5.0"
    $result = Invoke-RestMethod -Uri $relDefUrl -Method Post -ContentType "application/json" -Headers $header -Body $body
    $relDefs = $result

    Write-Host "Post API For Release Def Result : $($relDefs)"

}