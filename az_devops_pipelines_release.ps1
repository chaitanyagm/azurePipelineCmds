# To list the existing release Pipelines -------------------------------------------------------------------#
az pipelines release definition list
<#
ID    Name                  CreatedBy    Created On
----  --------------------  -----------  --------------------------------
4     New release pipeline  msd          2019-11-04T11:59:46.987000+00:00
#>

# To Create Release WHEN a RELEASE PIPELINE ALREADY EXISTS in Azure DevOps ----------------------------------#
az pipelines release create --definition-id 4
<#
ID    Name       Definition Name       Created By    Created On                  Status    Description
----  ---------  --------------------  ------------  --------------------------  --------  -------------
1     Release-1  New release pipeline  msd           2019-11-04 23:04:07.067000  active
#>
