# Author: Ryan Ries [MSFT]
# Origianl date: 15 Feb. 2014
#Requires -Version 3
Function Test-RPC
{
    [CmdletBinding(SupportsShouldProcess=$True)]
    Param([Parameter(ValueFromPipeline=$True)][String[]]$ComputerName = 'localhost')
    BEGIN
    {
        Set-StrictMode -Version Latest
        $PInvokeCode = @'
        using System;
        using System.Collections.Generic;
        using System.Runtime.InteropServices;

        public class Rpc
        {
            // I found this crud in RpcDce.h

            [DllImport("Rpcrt4.dll", CharSet = CharSet.Auto)]
            public static extern int RpcBindingFromStringBinding(string StringBinding, out IntPtr Binding);

            [DllImport("Rpcrt4.dll")]
            public static extern int RpcBindingFree(ref IntPtr Binding);

            [DllImport("Rpcrt4.dll", CharSet = CharSet.Auto)]
            public static extern int RpcMgmtEpEltInqBegin(IntPtr EpBinding,
                                                    int InquiryType, // 0x00000000 = RPC_C_EP_ALL_ELTS
                                                    int IfId,
                                                    int VersOption,
                                                    string ObjectUuid,
                                                    out IntPtr InquiryContext);

            [DllImport("Rpcrt4.dll", CharSet = CharSet.Auto)]
            public static extern int RpcMgmtEpEltInqNext(IntPtr InquiryContext,
                                                    out RPC_IF_ID IfId,
                                                    out IntPtr Binding,
                                                    out Guid ObjectUuid,
                                                    out IntPtr Annotation);

            [DllImport("Rpcrt4.dll", CharSet = CharSet.Auto)]
            public static extern int RpcBindingToStringBinding(IntPtr Binding, out IntPtr StringBinding);

            public struct RPC_IF_ID
            {
                public Guid Uuid;
                public ushort VersMajor;
                public ushort VersMinor;
            }

            public static List<int> QueryEPM(string host)
            {
                List<int> ports = new List<int>();
                int retCode = 0; // RPC_S_OK                
                IntPtr bindingHandle = IntPtr.Zero;
                IntPtr inquiryContext = IntPtr.Zero;                
                IntPtr elementBindingHandle = IntPtr.Zero;
                RPC_IF_ID elementIfId;
                Guid elementUuid;
                IntPtr elementAnnotation;

                try
                {                    
                    retCode = RpcBindingFromStringBinding("ncacn_ip_tcp:" + host, out bindingHandle);
                    if (retCode != 0)
                        throw new Exception("RpcBindingFromStringBinding: " + retCode);

                    retCode = RpcMgmtEpEltInqBegin(bindingHandle, 0, 0, 0, string.Empty, out inquiryContext);
                    if (retCode != 0)
                        throw new Exception("RpcMgmtEpEltInqBegin: " + retCode);
                    
                    do
                    {
                        IntPtr bindString = IntPtr.Zero;
                        retCode = RpcMgmtEpEltInqNext (inquiryContext, out elementIfId, out elementBindingHandle, out elementUuid, out elementAnnotation);
                        if (retCode != 0)
                            if (retCode == 1772)
                                break;

                        retCode = RpcBindingToStringBinding(elementBindingHandle, out bindString);
                        if (retCode != 0)
                            throw new Exception("RpcBindingToStringBinding: " + retCode);
                            
                        string s = Marshal.PtrToStringAuto(bindString).Trim().ToLower();
                        if(s.StartsWith("ncacn_ip_tcp:"))                        
                            ports.Add(int.Parse(s.Split('[')[1].Split(']')[0]));
                        
                        RpcBindingFree(ref elementBindingHandle);
                        
                    }
                    while (retCode != 1772); // RPC_X_NO_MORE_ENTRIES

                }
                catch(Exception ex)
                {
                    Console.WriteLine(ex);
                    return ports;
                }
                finally
                {
                    RpcBindingFree(ref bindingHandle);
                }
                
                return ports;
            }
        }
'@
    }
    PROCESS
    {
        ForEach($Computer In $ComputerName)
        {
            If($PSCmdlet.ShouldProcess($Computer))
            {
                [Bool]$EPMOpen = $False
                $Socket = New-Object Net.Sockets.TcpClient
                
                Try
                {                    
                    $Socket.Connect($Computer, 135)
                    If ($Socket.Connected)
                    {
                        $EPMOpen = $True
                    }
                    $Socket.Close()                    
                }
                Catch
                {
                    $Socket.Dispose()
                }
                
                If ($EPMOpen)
                {
                    Add-Type $PInvokeCode
                    $RPCPorts = [Rpc]::QueryEPM($Computer)
                    [Bool]$AllPortsOpen = $True
                    Foreach ($Port In $RPCPorts)
                    {
                        $Socket = New-Object Net.Sockets.TcpClient
                        Try
                        {
                            $Socket.Connect($Computer, $Port)
                            If (!$Socket.Connected)
                            {
                                $AllPortsOpen = $False
                            }
                            $Socket.Close()
                        }
                        Catch
                        {
                            $AllPortsOpen = $False
                            $Socket.Dispose()
                        }
                    }

                    [PSObject]@{'ComputerName' = $Computer; 'EndPointMapperOpen' = $EPMOpen; 'RPCPortsInUse' = $RPCPorts; 'AllRPCPortsOpen' = $AllPortsOpen}
                }
                Else
                {
                    [PSObject]@{'ComputerName' = $Computer; 'EndPointMapperOpen' = $EPMOpen}
                }
            }
        }
    }
    END
    {

    }
}