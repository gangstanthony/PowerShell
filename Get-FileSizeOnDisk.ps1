# https://www.opentechguides.com/how-to/article/powershell/133/size-on-disk-ps.html

<#

.SYNOPSIS
  Powershell script to get file size and size on disk of all files
  in a directory.
  
.DESCRIPTION
  This PowerShell script gets file size and size on disk in bytes
  of all files in a directory.
  
.PARAMETER <path>
   Directory path of the files to check. If this parameter is not
   specified the default value is current directory.
 
.NOTES
  Version:        1.0
  Author:         Open Tech Guides
  Creation Date:  06-Feb-2017
 
.LINK
    www.opentechguides.com
    
.EXAMPLE
  Get-FileSizeOnDisk c:\myfolder

#>

function Get-FileSizeOnDisk {
    param (
     [string]$path = '.',
     [switch]$recurse
    )


    $source = '
     using System;
     using System.Runtime.InteropServices;
     using System.ComponentModel;
     using System.IO;

     namespace Win32
      {
    
        public class Disk {
	
        [DllImport("kernel32.dll")]
        static extern uint GetCompressedFileSizeW([In, MarshalAs(UnmanagedType.LPWStr)] string lpFileName,
        [Out, MarshalAs(UnmanagedType.U4)] out uint lpFileSizeHigh);	
        
        public static ulong GetSizeOnDisk(string filename)
        {
          uint HighOrderSize;
          uint LowOrderSize;
          ulong size;

          FileInfo file = new FileInfo(filename);
          LowOrderSize = GetCompressedFileSizeW(file.FullName, out HighOrderSize);

          if (HighOrderSize == 0 && LowOrderSize == 0xffffffff)
           {
	     throw new Win32Exception(Marshal.GetLastWin32Error());
          }
          else { 
	     size = ((ulong)HighOrderSize << 32) + LowOrderSize;
	     return size;
           }
        }
      }
    }
    '

    Add-Type -TypeDefinition $source

    if ($recurse) {
        Get-ChildItem $path -Recurse | Where-Object { ! $_.PSIsContainer} | Foreach-Object {
            $_ | select fullname, name, length, extension, basename, @{n='SizeOnDisk';e={[Win32.Disk]::GetSizeOnDisk($_.FullName)}}
        }
    } else {
        Get-ChildItem $path | Where-Object { ! $_.PSIsContainer} | Foreach-Object {
            $_ | select fullname, name, length, extension, basename, @{n='SizeOnDisk';e={[Win32.Disk]::GetSizeOnDisk($_.FullName)}}
        }
    }
}
