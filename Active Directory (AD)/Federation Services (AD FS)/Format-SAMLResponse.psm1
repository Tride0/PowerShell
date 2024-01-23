Function Format-SAMLResponse {
    [alias('Format-SAML')]
    Param( 
        [String]$SAMLResponse,
        [Switch]$ToXML
    )
    
    #region Functions
    Function Format-XML {
        Param(
            [xml]$xml, 
            $Indent = 4
        )
        $StringWriter = New-Object System.IO.StringWriter
        $XmlWriter = New-Object System.XMl.XmlTextWriter $StringWriter
        $xmlWriter.Formatting = 'indented'
        $xmlWriter.Indentation = $Indent
        $xml.WriteContentTo($XmlWriter)
        $XmlWriter.Flush()
        $StringWriter.Flush()
        Write-Output $StringWriter.ToString()
    }

    Function Get-Cert {
        Param($CertBlob)
        $Cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2
        $Cert.Import([Convert]::FromBase64String($CertBlob))
        Return $Cert
    }
    #endregion Functions
    
    # Format SAML/XML
    If ($SAMLResponse -like '*<*' -and $SAMLResponse.GetType() -isnot [System.Xml.XmlDocument]) {
        $XML = [XML]$SAMLResponse
    }
    ElseIf ($SAMLResponse -like 'SAMLResponse=*' -and $SAMLResponse.GetType() -isnot [System.Xml.XmlDocument]) {

        [System.Reflection.Assembly]::LoadWithPartialName('System.Web') | Out-Null
        $Parsed_SAMLResponse = [System.Web.HttpUtility]::ParseQueryString($SAMLResponse)
        $base64encoded_SAMLResponse = $Parsed_SAMLResponse['SAMLResponse']

        [XML]$XML = [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($base64encoded_SAMLResponse))

        Remove-Variable Parsed_SAMLResponse, base64encoded_SAMLResponse -ErrorAction SilentlyContinue
    }

    # Cut function short if only XML is requested
    If ($ToXML.IsPresent) {
        Return (Format-XML -xml $XML)
    }

    # Status Code
    $StatusCode = $XML.Response.Status.StatusCode.Value.Split(':')[-1]

    # EndPoint Issuer
    Try {
        $EndPointIssuer = $XML.Response.Issuer.Innertext.Trim()
    }
    Catch {
        $EndPointIssuer = $XML.Response.Issuer
    }

    # Message Signature Certificate
    Try {
        $MessageSignature = Get-Cert -CertBlob $Xml.Response.Signature.KeyInfo.X509Data.X509Certificate
    }
    Catch {}

    $MessageDigestMethod = $XML.Response.Signature.SignedInfo.Reference.DigestMethod.Algorithm
    $MessageSignatureMethod = $XML.Response.Signature.SignedInfo.SignatureMethod.Algorithm

    # Assertion Signature Certificate
    Try {
        $AssertionSignature = Get-Cert -CertBlob $xml.Response.Assertion.Signature.KeyInfo.X509Data.X509Certificate
    }
    Catch {}

    $AssertionEncrypted = [Boolean]$xml.Response.EncryptedAssertion

    $AssertionDigestMethod = $XML.Response.Assertion.Signature.SignedInfo.Reference.DigestMethod.Algorithm
    $AssertionSignatureMethod = $XML.Response.Assertion.Signature.SignedInfo.SignatureMethod.Algorithm

    # Assertion URL
    $AssertionURL = $XML.Response.Destination

    # Identifier
    $SSOIdentifier = $XML.Response.Assertion.Conditions.AudienceRestriction.Audience
    
    # Attributes
    Try {
        $SubjectFormat = $XML.Response.Assertion.Subject.FirstChild.Format.Trim()
        $SubjectValue = $XML.Response.Assertion.Subject.FirstChild.InnerText.Trim()
        $SubjectName = $XML.Response.Assertion.Subject.FirstChild.Name.Trim()
    }
    Catch {
        $SubjectFormat = $XML.Response.Assertion.Subject.FirstChild.Format
        $SubjectValue = $XML.Response.Assertion.Subject.FirstChild.InnerText
        $SubjectName = $XML.Response.Assertion.Subject.FirstChild.Name
    }

    $AttributeHashTable = $XML.Response.Assertion.AttributeStatement.Attribute | ForEach-Object -Process {
        [PSCustomObject]@{
            Name           = $_.Name
            AttributeValue = $(
                If ([Boolean]$_.AttributeValue.InnerText) { $_.AttributeValue.InnerText.Trim() -join ', ' }
                ElseIf ([Boolean]$_.AttributeValue.Value) { $_.AttributeValue.Value.Trim() -join ', ' }
                ElseIf ([Boolean]$_.AttributeValue.'#text') { $_.AttributeValue.'#text'.Trim() -join ', ' }
                ElseIf ([Boolean]$_.AttributeValue -and $_.AttributeValue -isnot [System.Xml.XmlElement] ) { $_.AttributeValue -join ', ' }
            )
        }
    }

    # Populate Return variable
    $Return = [System.Collections.Specialized.OrderedDictionary]@{}
    $Return.Status = $StatusCode
    $Return.'EndPoint Issuer' = $EndPointIssuer
    $Return.'Destination (Assertion URL)' = $AssertionURL
    $Return.Identifier = $SSOIdentifier
    # Message Signature
    $Return.'MessageSignature Cert Subject' = $MessageSignature.Subject
    $Return.'MessageSignature Cert Issuer' = $MessageSignature.Issuer
    $Return.'MessageSignature Cert Thumbprint' = $MessageSignature.Thumbprint
    $Return.'MessageSignature Cert Not After' = $MessageSignature.NotAfter
    $Return.'MessageSignature Digest Method' = $MessageDigestMethod
    $Return.'MessageSignature Signature Method' = $MessageSignatureMethod
    # Is Assertion Encrypted
    $Return.'EncryptedAssertion' = $AssertionEncrypted
    # Assertion Signature
    $Return.'AssertionSignature Cert Subject' = $AssertionSignature.Subject
    $Return.'AssertionSignature Cert Issuer' = $AssertionSignature.Issuer
    $Return.'AssertionSignature Cert Thumbprint' = $AssertionSignature.Thumbprint
    $Return.'AssertionSignature Cert Not After' = $AssertionSignature.NotAfter
    $Return.'AssertionSignature Digest Method' = $AssertionDigestMethod
    $Return.'AssertionSignature Signature Method' = $AssertionSignatureMethod
    # Assertion Values
    $Return."$SubjectName`_$SubjectFormat" = $SubjectValue
    $AttributeHashTable | 
        ForEach-Object -Process {
            $PropName = $_.Name
            $I = 1
            While ($Return.Keys -Contains $PropName) {
                $PropName = "$($_.Name)$I"
                $I ++
            }
            $Return.$PropName = $_.AttributeValue
        }

    # Return Info
    Try {
        Return [PSCustomObject]$Return
    }
    Catch {
        Return $Return
    }
}
