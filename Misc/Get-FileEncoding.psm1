function Get-FileEncoding {
  [CmdletBinding()] 
  Param (
    [Parameter(Mandatory = $True, ValueFromPipelineByPropertyName = $True)] 
    [string]$Path
  )

  [byte[]]$byte = Get-Content -Encoding byte -ReadCount 4 -TotalCount 4 -Path $Path
  #Write-Host Bytes: $byte[0] $byte[1] $byte[2] $byte[3]

  # EF BB BF (UTF8)
  if ( $byte[0] -eq 0xef -and $byte[1] -eq 0xbb -and $byte[2] -eq 0xbf )
  { Write-Output 'UTF8' }

  # FE FF  (UTF-16 Big-Endian)
  elseif ($byte[0] -eq 0xfe -and $byte[1] -eq 0xff)
  { Write-Output 'Unicode UTF-16 Big-Endian' }

  # FF FE  (UTF-16 Little-Endian)
  elseif ($byte[0] -eq 0xff -and $byte[1] -eq 0xfe)
  { Write-Output 'Unicode UTF-16 Little-Endian' }

  # 00 00 FE FF (UTF32 Big-Endian)
  elseif ($byte[0] -eq 0 -and $byte[1] -eq 0 -and $byte[2] -eq 0xfe -and $byte[3] -eq 0xff)
  { Write-Output 'UTF32 Big-Endian' }

  # FE FF 00 00 (UTF32 Little-Endian)
  elseif ($byte[0] -eq 0xfe -and $byte[1] -eq 0xff -and $byte[2] -eq 0 -and $byte[3] -eq 0)
  { Write-Output 'UTF32 Little-Endian' }

  # 2B 2F 76 (38 | 38 | 2B | 2F)
  elseif ($byte[0] -eq 0x2b -and $byte[1] -eq 0x2f -and $byte[2] -eq 0x76 -and ($byte[3] -eq 0x38 -or $byte[3] -eq 0x39 -or $byte[3] -eq 0x2b -or $byte[3] -eq 0x2f) )
  { Write-Output 'UTF7' }

  # F7 64 4C (UTF-1)
  elseif ( $byte[0] -eq 0xf7 -and $byte[1] -eq 0x64 -and $byte[2] -eq 0x4c )
  { Write-Output 'UTF-1' }

  # DD 73 66 73 (UTF-EBCDIC)
  elseif ($byte[0] -eq 0xdd -and $byte[1] -eq 0x73 -and $byte[2] -eq 0x66 -and $byte[3] -eq 0x73)
  { Write-Output 'UTF-EBCDIC' }

  # 0E FE FF (SCSU)
  elseif ( $byte[0] -eq 0x0e -and $byte[1] -eq 0xfe -and $byte[2] -eq 0xff )
  { Write-Output 'SCSU' }

  # FB EE 28  (BOCU-1)
  elseif ( $byte[0] -eq 0xfb -and $byte[1] -eq 0xee -and $byte[2] -eq 0x28 )
  { Write-Output 'BOCU-1' }

  # 84 31 95 33 (GB-18030)
  elseif ($byte[0] -eq 0x84 -and $byte[1] -eq 0x31 -and $byte[2] -eq 0x95 -and $byte[3] -eq 0x33)
  { Write-Output 'GB-18030' }

  else
  { Write-Output 'ASCII' }
}