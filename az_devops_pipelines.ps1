# All available options in az pipeline command ----------------#
az pipelines -h

# Create a pipeline -------------------------------------------#
az pipelines create --name "test.CI" --repository https://github.com/chaitanyagm/AdventureWorks2016.git --branch master

# Show list of pipelines --------------------------------------#
az pipelines list
<#
ID    Path    Name      Status    Default Queue
----  ------  --------  --------  ------------------
16    \       test.CI   enabled   Hosted Ubuntu 1604
17    \       test.CI1  enabled   Hosted Ubuntu 1604
#>

# Show list with Status ---------------------------------------#
az pipelines runs list
<#
Run ID    Number      Status     Result     Pipeline ID    Pipeline Name    Source Branch    Queued Time                 Reason
--------  ----------  ---------  ---------  -------------  ---------------  ---------------  --------------------------  --------
23        20191103.1  completed  succeeded  17             test.CI1         master           2019-11-03 23:36:58.778131  manual
22        20191103.1  completed  succeeded  16             test.CI          master           2019-11-03 23:29:39.196786  manual
#>

# Status of a Pipeline with ID 23 -----------------------------#
az pipelines runs show --id 23
<#
Run ID    Number      Status     Result     Pipeline ID    Pipeline Name    Source Branch    Queued Time                 Reason
--------  ----------  ---------  ---------  -------------  ---------------  ---------------  --------------------------  --------
23        20191103.1  completed  succeeded  17             test.CI1         master           2019-11-03 23:36:58.778131  manual
#>
# -------------------------------------------------------------#
