function Get-IP{
    [cmdletbinding()]
    param(
        [parameter(valuefrompipelinebypropertyname, mandatory, position = 0)][alias('host','cn')][validatepattern("\d{4}-?\S*")][string]$computername
    )

    import-module DhcpServer
    import-module ActiveDirectory 
    
    $DC = #DHCP Server here#
    $Scopes = Get-DhcpServerv4Scope -ComputerName $DC | select ScopeID     #get all the different subnets to loop through 
    $found = $false 
    
    $Cname = Get-ADComputer -filter "name -like '$computername*'" | select -expand name     #grabs full computer name; runs even if you provide full name 
     if($cname){     #if user provides invalid name $cname will be null so this won't execute 
        foreach ($subnet in $Scopes){
            $IP = get-dhcpserverv4lease -ComputerName $DC -ScopeId $subnet.scopeid -ErrorAction SilentlyContinue | select ipaddress,hostname | where {$_.hostname -eq "$cname.domain.com"} | select -expand ipaddress   #searches subnet for IP w/ FQDN 
             if($IP){     #$IP will be null if not found in a subnet so proceed only if found 
                $found = $true     #$flag used to notify that machine was found in at least one scope since $IP changes in each iteration 
                    if(($IP.tostring()) -match "\d{1,3}\.\d{1,3}\.\.\d{1,3}"){     #*.*.*.* we wanted to differentiate wireless IPs so I but wireless subnet here
                        write-output "$cname has an IP address of $($IP.ipaddresstostring) [WIRELESS]"
                        break
                    }
                 write-output "$cname has an IP address of $($IP.ipaddresstostring) [ETHERNET]" 
                 $IP.tostring() | clip | out-null
             }
        }
     }
     else{
        write-warning "$computername is invalid. Please check its spelling and try again."
        break 
     }
   
        
    
    if(!$found){
        write-warning "$computername IP address was not found in any scope."
    }

}