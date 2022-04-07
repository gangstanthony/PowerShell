# http://www.stevieg.org/2010/07/using-powershell-to-import-contacts-into-exchange-and-outlook-live/
# https://www.reddit.com/r/PowerShell/comments/tyfmuf/getmailboxcontacts_and_importmailboxcontacts

# Import-MailboxContacts -CSVFileName C:\temp\contacts.csv -EmailAddress user@domain.com -Impersonate $true -Username admin@domain.com -Password <pass>

# NOTE: not tested with admin account that requires MFA
# your csv must have headers as defined in left column of $ContactMapping

function Import-MailboxContacts {
    param (
        [string]$CSVFileName,
        [string]$EmailAddress,
        [string]$Username,
        [string]$Password,
        [string]$Domain,
        [bool]$Impersonate,
        [string]$EwsUrl,
        [string]$EWSManagedApiDLLFilePath,
        [bool]$Exchange2007,
        [switch]$Exchange2010
    )
    
    #
    # Import-MailboxContacts.ps1
    #
    # By Steve Goodman, Use at your own risk.
    #
    # Parameters
    #  Mandatory:
    # -CSVFileName : Filename of the CSV file to import contacts for this user from. Same format as Outlook Export.
    # -EmailAddress : Account SMTP email address. Required, but only used when impersonating or with Autodiscover - otherwise uses the user you login as
    #  Optional:
    # -Impersonate : Set to $true to use impersonation.
    # -Username : The username to use. If this isn't specified (along with Password), attempts to use the logged on user.
    # -Password : Used with above
    # -Domain : Used with above - optional.
    # -EwsUrl : The URL for EWS if you don't want to use Autodiscover. Typically https://casserver/EWS/Exchange.asmx
    # -EWSManagedApiDLLFilePath : (Optional) Overwrite the filename and path to the DLL for EWS Managed API. By default, uses the default install location.
    # -Exchange2007 : Set to $true to use the Exchange 2007 SP1+ version of the Managed API.
    #
    # Contact Mapping - this maps the attributes in the CSV file (left) to the attributes EWS uses.
    # NB: If you change these, please note "First Name" is specified at line 102 as a required attribute and
    # "First Name" and "Last Name" are hard coded at lines 187-197 when constructing NickName and FileAs.
    
    $ContactMapping = @{
        'First Name'              = 'GivenName'
        'Middle Name'             = 'MiddleName'
        'Last Name'               = 'Surname'
        'Company'                 = 'CompanyName'
        'Department'              = 'Department'
        'Job Title'               = 'JobTitle'
        'Business Street'         = 'Address:Business:Street'
        'Business City'           = 'Address:Business:City'
        'Business State'          = 'Address:Business:State'
        'Business Postal Code'    = 'Address:Business:PostalCode'
        'Business Country/Region' = 'Address:Business:CountryOrRegion'
        'Home Street'             = 'Address:Home:Street'
        'Home City'               = 'Address:Home:City'
        'Home State'              = 'Address:Home:State'
        'Home Postal Code'        = 'Other:Home:PostalCode'
        'Home Country/Region'     = 'Address:Home:CountryOrRegion'
        'Other Street'            = 'Address:Other:Street'
        'Other City'              = 'Address:Other:City'
        'Other State'             = 'Address:Other:State'
        'Other Postal Code'       = 'Address:Other:PostalCode'
        'Other Country/Region'    = 'Address:Other:CountryOrRegion'
        "Assistant's Phone"       = 'Phone:AssistantPhone'
        'Business Fax'            = 'Phone:BusinessFax'
        'Business Phone'          = 'Phone:BusinessPhone'
        'Business Phone 2'        = 'Phone:BusinessPhone2'
        'Callback'                = 'Phone:CallBack'
        'Car Phone'               = 'Phone:CarPhone'
        'Company Main Phone'      = 'Phone:CompanyMainPhone'
        'Home Fax'                = 'Phone:HomeFax'
        'Home Phone'              = 'Phone:HomePhone'
        'Home Phone 2'            = 'Phone:HomePhone2'
        'ISDN'                    = 'Phone:ISDN'
        'Mobile Phone'            = 'Phone:MobilePhone'
        'Other Fax'               = 'Phone:OtherFax'
        'Other Phone'             = 'Phone:OtherTelephone'
        'Pager'                   = 'Phone:Pager'
        'Primary Phone'           = 'Phone:PrimaryPhone'
        'Radio Phone'             = 'Phone:RadioPhone'
        'TTY/TDD Phone'           = 'Phone:TtyTddPhone'
        'Telex'                   = 'Phone:Telex'
        'Anniversary'             = 'WeddingAnniversary'
        'Birthday'                = 'Birthday'
        'E-mail Address'          = 'Email:EmailAddress1'
        'E-mail 2 Address'        = 'Email:EmailAddress2'
        'E-mail 3 Address'        = 'Email:EmailAddress3'
        'Initials'                = 'Initials'
        'Office Location'         = 'OfficeLocation'
        "Manager's Name"          = 'Manager'
        'Mileage'                 = 'Mileage'
        'Notes'                   = 'Body'
        'Profession'              = 'Profession'
        'Spouse'                  = 'SpouseName'
        'Web Page'                = 'BusinessHomePage'
        'Contact Picture File'    = 'Method:SetContactPicture'
    }
    
    # CSV File Checks
    # Check filename is specified
    if (!$CSVFileName) {
        THROW 'Parameter CSVFileName must be specified'
    }
    
    # Check file exists
    if (!(Get-Item -Path $CSVFileName -ErrorAction SilentlyContinue)) {
        THROW 'Please provide a valid filename for parameter CSVFileName'
    }
    
    # Check file has required fields and check if is a single row, or multiple rows
    $SingleItem = $false
    $CSVFile = Import-Csv -Path $CSVFileName
    if ($CSVFile.'First Name') {
        $SingleItem = $true
    } else {
        if (!$CSVFile[0].'First Name') {
            Throw "File $($CSVFileName) must specify at least the field 'First Name'"
        }
    }
    
    # Check email address
    if (!$EmailAddress) {
        Throw 'Parameter EmailAddress must be specified'
    }
    
    if (!$EmailAddress.Contains('@')) {
        Throw 'Parameter EmailAddress does not appear valid'
    }
    
    # Check EWS Managed API available
    if (!$EWSManagedApiDLLFilePath) {
        #$EWSManagedApiDLLFilePath = 'C:\Program Files\Microsoft\Exchange\Web Services\2.0\Microsoft.Exchange.WebServices.dll'
        $EWSManagedApiDLLFilePath = 'C:\Program Files\Microsoft\Exchange\Web Services\2.2\Microsoft.Exchange.WebServices.dll'
    }
    
    if (!(Get-Item -Path $EWSManagedApiDLLFilePath -ErrorAction SilentlyContinue)) {
        Throw "EWS Managed API not found at $($EWSManagedApiDLLFilePath). Download from https://github.com/gangstanthony/PowerShell/raw/master/EWSManagedAPI2.2.msi"
    }
    
    # Load EWS Managed API
    #[void][Reflection.Assembly]::LoadFile('C:\Program Files\Microsoft\Exchange\Web Services\2.0\Microsoft.Exchange.WebServices.dll')
    [void][Reflection.Assembly]::LoadFile($EWSManagedApiDLLFilePath)
    
    # Create Service Object
    if ($Exchange2007) {
        $service = New-Object Microsoft.Exchange.WebServices.Data.ExchangeService([Microsoft.Exchange.WebServices.Data.ExchangeVersion]::Exchange2007_SP1)
    } elseif ($Exchange2010) {
        $service = New-Object Microsoft.Exchange.WebServices.Data.ExchangeService([Microsoft.Exchange.WebServices.Data.ExchangeVersion]::Exchange2010)
    } else {
        #$service = New-Object Microsoft.Exchange.WebServices.Data.ExchangeService([Microsoft.Exchange.WebServices.Data.ExchangeVersion]::Exchange2013)
        $service = New-Object Microsoft.Exchange.WebServices.Data.ExchangeService([Microsoft.Exchange.WebServices.Data.ExchangeVersion]::Exchange2013_SP1)
    }
    
    # Set credentials if specified, or use logged on user.
    if ($Username -and $Password) {
        if ($Domain) {
            $service.Credentials = New-Object  Microsoft.Exchange.WebServices.Data.WebCredentials($Username,$Password,$Domain)
        } else {
            $service.Credentials = New-Object  Microsoft.Exchange.WebServices.Data.WebCredentials($Username,$Password)
        }
    } else {
        $service.UseDefaultCredentials = $true
    }
    
    # Set EWS URL if specified, or use autodiscover if no URL specified.
    if ($EwsUrl) {
        $service.URL = New-Object Uri($EwsUrl)
    } else {
        $EwsUrl = 'https://outlook.office365.com/ews/exchange.asmx'
        try {
            #$service.AutodiscoverUrl($EmailAddress)
            $service.URL = New-Object Uri($EwsUrl)
        } catch {
            Throw
        }
    }
    
    # Perform a test - try and get the default, well known contacts folder.
    if ($Impersonate) {
        $service.ImpersonatedUserId = New-Object Microsoft.Exchange.WebServices.Data.ImpersonatedUserId([Microsoft.Exchange.WebServices.Data.ConnectingIdType]::SmtpAddress, $EmailAddress)
    }
    
    try {
        $ContactsFolder = [Microsoft.Exchange.WebServices.Data.ContactsFolder]::Bind($service, [Microsoft.Exchange.WebServices.Data.WellKnownFolderName]::Contacts)
    } catch {
        Throw
    }
    
    # Add contacts
    foreach ($ContactItem in $CSVFile) {
        # If impersonate is specified, do so.
        if ($Impersonate) {
            $service.ImpersonatedUserId = New-Object Microsoft.Exchange.WebServices.Data.ImpersonatedUserId([Microsoft.Exchange.WebServices.Data.ConnectingIdType]::SmtpAddress, $EmailAddress)
        }
        
        $ExchangeContact = New-Object Microsoft.Exchange.WebServices.Data.Contact($service)
        if ($ContactItem.'First Name' -and $ContactItem.'Last Name') {
            $ExchangeContact.NickName = $ContactItem.'First Name' + ' ' + $ContactItem.'Last Name'
        } elseif ($ContactItem.'First Name' -and !$ContactItem.'Last Name') {
            $ExchangeContact.NickName = $ContactItem.'First Name'
        } elseif (!$ContactItem.'First Name' -and $ContactItem.'Last Name') {
            $ExchangeContact.NickName = $ContactItem.'Last Name'
        }
        
        $ExchangeContact.DisplayName = $ExchangeContact.NickName
        $ExchangeContact.FileAs = $ExchangeContact.NickName
        
        $BusinessPhysicalAddressEntry = New-Object Microsoft.Exchange.WebServices.Data.PhysicalAddressEntry
        $HomePhysicalAddressEntry = New-Object Microsoft.Exchange.WebServices.Data.PhysicalAddressEntry
        $OtherPhysicalAddressEntry = New-Object Microsoft.Exchange.WebServices.Data.PhysicalAddressEntry
        
        # This uses the Contact Mapping above to save coding each and every field, one by one. Instead we look for a mapping and perform an action on
        # what maps across. As some methods need more "code" a fake multi-dimensional array (seperated by :'s) is used where needed.
        foreach ($Key IN $ContactMapping.Keys) {
            # Only do something if the key exists
            if ($ContactItem.$Key) {
                # Will this call a more complicated mapping?
                if ($ContactMapping[$Key] -like '*:*') {
                    # Make an array using the : to split items.
                    $MappingArray = $ContactMapping[$Key].Split(':')
                    
                    # Do action
                    switch ($MappingArray[0]) {
                        'Email' {
                            $ExchangeContact.EmailAddresses[[Microsoft.Exchange.WebServices.Data.EmailAddressKey]::($MappingArray[1])] = $ContactItem.$Key
                        }
                        'Phone' {
                            $ExchangeContact.PhoneNumbers[[Microsoft.Exchange.WebServices.Data.PhoneNumberKey]::($MappingArray[1])] = $ContactItem.$Key
                        }
                        'Address' {
                            switch ($MappingArray[1]) {
                                'Business' {
                                    $BusinessPhysicalAddressEntry.($MappingArray[2]) = $ContactItem.$Key
                                    $ExchangeContact.PhysicalAddresses[[Microsoft.Exchange.WebServices.Data.PhysicalAddressKey]::($MappingArray[1])] = $BusinessPhysicalAddressEntry
                                }
                                'Home' {
                                    $HomePhysicalAddressEntry.($MappingArray[2]) = $ContactItem.$Key
                                    $ExchangeContact.PhysicalAddresses[[Microsoft.Exchange.WebServices.Data.PhysicalAddressKey]::($MappingArray[1])] = $HomePhysicalAddressEntry
                                }
                                'Other' {
                                    $OtherPhysicalAddressEntry.($MappingArray[2]) = $ContactItem.$Key
                                    $ExchangeContact.PhysicalAddresses[[Microsoft.Exchange.WebServices.Data.PhysicalAddressKey]::($MappingArray[1])] = $OtherPhysicalAddressEntry
                                }
                            }
                        }
                        'Method' {
                            switch ($MappingArray[1]) {
                                'SetContactPicture' {
                                    if (!$Exchange2007) {
                                        if (!(Get-Item -Path $ContactItem.$Key -ErrorAction SilentlyContinue)) {
                                            Throw "Contact Picture File not found at $($ContactItem.$Key)"
                                        }
                                        $ExchangeContact.SetContactPicture($ContactItem.$Key);
                                    }
                                }
                            }
                        }
                    
                    }                
                } else {
                    # It's a direct mapping - simple!
                    if ($ContactMapping[$Key] -eq 'Birthday' -or $ContactMapping[$Key] -eq 'WeddingAnniversary') {
                        if ($ContactItem.$Key -ne '0/0/00') {
                            [System.DateTime]$ContactItem.$Key = Get-Date($ContactItem.$Key)
                        }
                    }
                    if ($ContactItem.$Key -ne '0/0/00') {
                        $ExchangeContact.($ContactMapping[$Key]) = $ContactItem.$Key
                    }
                }
                
            }    
        }
        
        # Save the contact    
        $ExchangeContact.Save()
        
        # Provide output that can be used on the pipeline
        $Output_Object = New-Object Object
        $Output_Object | Add-Member NoteProperty FileAs $ExchangeContact.FileAs
        $Output_Object | Add-Member NoteProperty GivenName $ExchangeContact.GivenName
        $Output_Object | Add-Member NoteProperty Surname $ExchangeContact.Surname
        $Output_Object | Add-Member NoteProperty EmailAddress1 $ExchangeContact.EmailAddresses[[Microsoft.Exchange.WebServices.Data.EmailAddressKey]::EmailAddress1]
        $Output_Object
    }
}
