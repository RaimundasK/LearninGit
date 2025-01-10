## Script to generate SAS token for Azure Storage account by RK

using namespace System.Net
using namespace Microsoft.WindowsAzure.Storage.Blob

param($Request, $TriggerMetadata)

$storageAccountName = $Request.Query.StorageAccountName
$storageAccountKey = $Request.Query.StorageAccountKey
$containerName = $Request.Query.ContainerName

try {
    $ctx = New-AzStorageContext -StorageAccountName $storageAccountName -StorageAccountKey $storageAccountKey
    $container = Get-AzStorageContainer -Name $containerName -Context $ctx

    if ($container -eq $null) {
        throw "Container not found"
    }

    $sasToken = New-AzStorageContainerSASToken -Context $ctx -Name $containerName -Permission rl -ExpiryTime (Get-Date).AddHours(8)

    if ($sasToken -eq $null) {
        throw "Failed to generate SAS token"
    }

    $response = @{
        "sasToken" = $sasToken
        "sasUrl" = "$($container.CloudBlobContainer.Uri)?$sasToken"
    } | ConvertTo-Json

    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::OK
        Body = $response
    })
}
catch {
    Write-Error $_
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::InternalServerError
        Body = $_.Exception.Message
    })
}
