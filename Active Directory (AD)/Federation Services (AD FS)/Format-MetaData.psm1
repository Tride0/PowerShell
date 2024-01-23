Function Format-MetaData {
    Param($FilePath)
    Begin {
        $BeginCert = '-----BEGIN CERTIFICATE-----'
        $EndCert = '-----END CERTIFICATE-----'
    }
    Process {
        [xml]$XML = Get-Content -Path $FilePath
        $Return = [System.Collections.Specialized.OrderedDictionary]@{ }
        $Return.EntityID = $XMl.EntityDescriptor.entityID
        $Return.SingleSignOnService = $($XMl.EntityDescriptor.IDPSSODescriptor.SingleSignOnService.Location | Select-Object -Unique)
        $Return.AssertionConsumerService = $($XML.EntityDescriptor.SPSSODescriptor.AssertionConsumerService.Location | Select-Object -Unique)

        If (([array]$XML.EntityDescriptor.IDPSSODescriptor.KeyDescriptor).count -gt 0) {
            Foreach ($Cert in ([array]$XML.EntityDescriptor.IDPSSODescriptor.KeyDescriptor)) {
                $Return."IDP $($Cert.use) Cert" = "$BeginCert`n" + $Cert.KeyInfo.X509Data.X509Certificate + "`n$EndCert"
            }
        }

        If (([array]$XML.EntityDescriptor.SPSSODescriptor.KeyDescriptor).count -gt 0) {
            Foreach ($Cert in ([array]$XML.EntityDescriptor.SPSSODescriptor.KeyDescriptor)) {
                $Return."IDP $($Cert.use) Cert" = "$BeginCert`n" + $Cert.KeyInfo.X509Data.X509Certificate + "`n$EndCert"
            }
        }

                
        Write-Output ([PSCustomObject]$Return | Format-List)
    }
}

