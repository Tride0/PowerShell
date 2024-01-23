class FolderSelectDialog {
	$OFD = $null
	FolderSelectDialog() {
		$This.OFD = New-Object System.Windows.Forms.OpenFileDialog
		$This.OFD.CheckFileExists = $False
		$This.OFD.DereferenceLinks = $True
		$This.OFD.Multiselect = $True
	}

	[Boolean] ShowDialog() {
		$HWNDOwner = [IntPtr]::Zero
		[bool]$Flag = $False

		If ([Environment]::OSVersion.Version.Major -ge 6) {
			$NameSpace = 'System.Windows.Forms'
			$Assembly = [System.Reflection.Assembly]::LoadWithPartialName($NameSpace)	
			
			[uint32]$Num = 0
			$TypeIFileDialog = $null
			
			[string[]]$Names = 'FileDialogNative.IFileDialog'.Split('.')

			If ($Names.Length -gt 0) {
				$TypeIFileDialog = $Assembly.GetType("$($NameSpace).$($Names[0])")
			}
			For ($i = 1; $i -lt $Names.Length; ++$i) {
				$TypeIFileDialog = $TypeIFileDialog.GetNestedType($Names[$i], [System.Reflection.BindingFlags]::NonPublic)
			}

			[System.Reflection.MethodInfo]$MethodInfo = $This.OFD.GetType().GetMethod('CreateVistaDialog', 
				[System.Reflection.BindingFlags]::Instance -bor [System.Reflection.BindingFlags]::Public -bor [System.Reflection.BindingFlags]::NonPublic)
			$Dialog = $MethodInfo.Invoke($This.OFD, $null)

			[System.Reflection.MethodInfo]$MethodInfo = $This.OFD.GetType().GetMethod('OnBeforeVistaDialog', 
				[System.Reflection.BindingFlags]::Instance -bor [System.Reflection.BindingFlags]::Public -bor [System.Reflection.BindingFlags]::NonPublic)
			$MethodInfo.Invoke($This.OFD, $Dialog)


			[System.Reflection.MethodInfo]$MethodInfo = $Assembly.GetType("$NameSpace.FileDialog").GetMethod('GetOptions', 
				[System.Reflection.BindingFlags]::Instance -bor [System.Reflection.BindingFlags]::Public -bor [System.Reflection.BindingFlags]::NonPublic)
			$Options = $MethodInfo.Invoke($This.OFD, $null)


			$Type = $null
			[string[]]$Names = 'FileDialogNative.FOS'.Split('.')
			If ($Names.Length -gt 0) {
				$Type = $Assembly.GetType("$($NameSpace).$($Names[0])")
			}
			For ($i = 1; $i -lt $Names.Length; ++$i) {
				$Type = $Type.GetNestedType($Names[$i], [System.Reflection.BindingFlags]::NonPublic)
			}
			[System.Reflection.FieldInfo]$FieldInfo = $Type.GetField('FOS_PICKFOLDERS')
			$Options = $FieldInfo.GetValue($Null)

			$Options.Value__ += $Type.GetField('FOS_ALLOWMULTISELECT').GetValue($Null).Value__

			[System.Reflection.MethodInfo]$MethodInfo = $TypeIFileDialog.GetMethod('SetOptions', 
				[System.Reflection.BindingFlags]::Instance -bor [System.Reflection.BindingFlags]::Public -bor [System.Reflection.BindingFlags]::NonPublic)
			$MethodInfo.Invoke($Dialog, $Options)

			$PFDE = $Type = $null
			[string[]]$Names = 'FileDialog.VistaDialogEvents'.Split('.')
			If ($Names.Length -gt 0) {
				$Type = $Assembly.GetType("$($NameSpace).$($Names[0])")
			}
			For ($i = 1; $i -lt $Names.Length; ++$i) {
				$Type = $Type.GetNestedType($Names[$i], [System.Reflection.BindingFlags]::NonPublic)
			}

			$ConstructorInfos = $Type.GetConstructors()
			Foreach ($CI in $ConstructorInfos) {
				Try { $PFDE = $CI.Invoke($This.OFD) } 
				Catch { }
			}
			[object[]]$Parameters = [object[]]($PFDE, $Num)


			[System.Reflection.MethodInfo]$MethodInfo = $TypeIFileDialog.GetMethod('Advise', 
				[System.Reflection.BindingFlags]::Instance -bor [System.Reflection.BindingFlags]::Public -bor [System.Reflection.BindingFlags]::NonPublic)
			$MethodInfo.Invoke($Dialog, $Parameters)

			$Num = [int]$Parameters[1]
			
			Try {
				[System.Reflection.MethodInfo]$MethodInfo = $TypeIFileDialog.GetMethod('Show', 
					[System.Reflection.BindingFlags]::Instance -bor [System.Reflection.BindingFlags]::Public -bor [System.Reflection.BindingFlags]::NonPublic)
				[int]$Num2 = $MethodInfo.Invoke($Dialog, $HWNDOwner)
				$Flag = $Num2
			}
			Finally {
				[System.Reflection.MethodInfo]$MethodInfo = $TypeIFileDialog.GetMethod('Unadvise', 
					[System.Reflection.BindingFlags]::Instance -bor [System.Reflection.BindingFlags]::Public -bor [System.Reflection.BindingFlags]::NonPublic)
				$MethodInfo.Invoke($Dialog, $Num)
				[System.GC]::KeepAlive($PFDE)
			}
		}
		Else {
			$FBD = New-System Windows.Forms.FolderBrowserDialog
			If ($FBD.ShowDialog() -ne 'OK') { $Flag = $False }
			Else { $Flag = $True }
			$This.OFD.FileName = $FBD.SelectedPath
		}
		Return $Flag
	}
}

($FS = New-Object FolderSelectDialog).ShowDialog()
$FS
$FS.OFD
$FS.OFD.FileName