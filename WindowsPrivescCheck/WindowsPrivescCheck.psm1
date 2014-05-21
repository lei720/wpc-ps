$trusted_users=@("BUILTIN\Rendszergazdák","BUILTIN\Administrators","NT AUTHORITY\SYSTEM","NT SERVICE\TrustedInstaller")
$dangerous_service_rights=@("FullControl","Write","Modify","ChangePermissions","WriteAttributes","WriteExtendedAttributes","AppendData","Delete")
<#
.SYNOPSIS
   Windows Privesc Check
.DESCRIPTION
   Windows Privesc Check

.EXAMPLE
   TODO

#>
# http://msdn.microsoft.com/en-us/library/aa392727(v=vs.85).aspx
function Get-ServicePaths
{
	Begin
	{
	}
	Process
	{
		$services = get-wmiobject -query 'select * from Win32_Service';
		$paths=@()
		$services | ForEach-Object {
			$path=$_.PathName
			if ($path.StartsWith('"')){
				$parts=$path.Split('"')
				$p=$parts[1]
				if (!($paths -contains $p)){
					$paths+=$p
				}
			}else{
				$p=$path.Split(" ")[0]
				if (!($paths -contains $p)){
					$paths+=$p
				}
			}
		}

		$paths | ForEach-Object{
			$current_path=$_
			(Get-Acl $_).Access | ForEach-Object{
				$danger=$FALSE
				$_.FileSystemRights.ToString().Replace(" ","").Split(",") | ForEach-Object{
					if ($dangerous_service_rights -contains $_){
						$danger=$TRUE
					}
				}
				if  ($danger -and !($trusted_users -contains $_.IdentityReference) -and ($_.AccessControlType -eq "Allow")){
					echo $current_path
					echo $_.IdentityReference 
					echo $_.FileSystemRights
					echo $_.AccessControlType
				}
			}
		}
	}
	End
	{
	}
}
