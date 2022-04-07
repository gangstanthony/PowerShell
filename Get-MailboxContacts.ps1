# https://social.technet.microsoft.com/wiki/contents/articles/21573.exchange-access-mailbox-contacts-using-powershell-and-ews.aspx
# https://www.reddit.com/r/PowerShell/comments/tyfmuf/getmailboxcontacts_and_importmailboxcontacts

# NOTE: have not tested with admin account that requires MFA
# NOTE: maybe hangs on account if no longer active user? shared mailbox? no license?

# Get-MailboxContacts -EmailAddress user@domain.com -Username admin@domain.com -Password mypasswd

function Get-MailboxContacts {
    param (
        $EmailAddress, # account to check contacts of (user@domain.com)
        $Username, # admin account with impersonation access (user@domain.com)
        $Password, # admin password
        $EWSManagedApiDLLFilePath = 'C:\Program Files\Microsoft\Exchange\Web Services\2.2\Microsoft.Exchange.WebServices.dll'
    )
    
    if (!(Test-Path $EWSManagedApiDLLFilePath)) {
        $ans = Read-Host "Could not find EWS Manged API 2.2. Install automatically? [Y]/n"
        if (!$ans -or $ans -eq 'y') {
            if (!(test-path 'c:\temp')) {
                md 'c:\temp' | out-null
            }
            try {
                Write-Host 'Attempting to download EWSManagedAPI2.2.msi to C:\temp...'
                #iwr https://download.microsoft.com/download/8/9/9/899EEF2C-55ED-4C66-9613-EE808FCF861C/EwsManagedApi.msi -OutFile 'c:\temp\EWSManagedAPI2.2.msi'
                # https://web.archive.org/web/20200812034329/https://download.microsoft.com/download/8/9/9/899EEF2C-55ED-4C66-9613-EE808FCF861C/EwsManagedApi.msi
                iwr https://github.com/gangstanthony/PowerShell/blob/master/EWSManagedAPI2.2.msi?raw=true -OutFile 'c:\temp\EWSManagedAPI2.2.msi'

                Write-Host 'Attempting to install C:\temp\EWSManagedAPI2.2.msi...'
                start -wait msiexec "/i C:\temp\EWSManagedAPI2.2.msi /qb"

                if (!(Test-Path $dllpath)) {
                    throw "Could not install. Please install manually.`nhttps://www.microsoft.com/en-us/download/details.aspx?id=42951"
                }
            } catch {
                throw $_
            }
        } else {
            throw "Do you have Microsoft Exchange Web Services Managed API 2.2 installed?`nhttps://www.microsoft.com/en-us/download/details.aspx?id=42951`nhttps://download.microsoft.com/download/8/9/9/899EEF2C-55ED-4C66-9613-EE808FCF861C/EwsManagedApi.msi"
        }
    }

    [void][Reflection.Assembly]::LoadFile($EWSManagedApiDLLFilePath)

    $service = New-Object Microsoft.Exchange.WebServices.Data.ExchangeService([Microsoft.Exchange.WebServices.Data.ExchangeVersion]::Exchange2013_SP1)
    $service.Credentials = New-Object Microsoft.Exchange.WebServices.Data.WebCredentials $Username, $Password
    $service.URL = New-Object Uri('https://outlook.office365.com/ews/exchange.asmx')
    $service.ImpersonatedUserId = New-Object Microsoft.Exchange.WebServices.Data.ImpersonatedUserId([Microsoft.Exchange.WebServices.Data.ConnectingIdType]::SmtpAddress, $EmailAddress)

    $pageSize = 100
    $pageLimitOffset = 0
    $getMoreItems = $true
    $itemCount = 0

    $propAlias = [Microsoft.Exchange.WebServices.Data.ContactSchema]::Alias
    $propAssistantName = [Microsoft.Exchange.WebServices.Data.ContactSchema]::AssistantName
    $propAssistantPhone = [Microsoft.Exchange.WebServices.Data.ContactSchema]::AssistantPhone
    $propBirthday = [Microsoft.Exchange.WebServices.Data.ContactSchema]::Birthday
    $propBusinessAddressCity = [Microsoft.Exchange.WebServices.Data.ContactSchema]::BusinessAddressCity
    $propBusinessAddressCountryOrRegion = [Microsoft.Exchange.WebServices.Data.ContactSchema]::BusinessAddressCountryOrRegion
    $propBusinessAddressPostalCode = [Microsoft.Exchange.WebServices.Data.ContactSchema]::BusinessAddressPostalCode
    $propBusinessAddressState = [Microsoft.Exchange.WebServices.Data.ContactSchema]::BusinessAddressState
    $propBusinessAddressStreet = [Microsoft.Exchange.WebServices.Data.ContactSchema]::BusinessAddressStreet
    $propBusinessFax = [Microsoft.Exchange.WebServices.Data.ContactSchema]::BusinessFax
    $propBusinessHomePage = [Microsoft.Exchange.WebServices.Data.ContactSchema]::BusinessHomePage
    $propBusinessPhone = [Microsoft.Exchange.WebServices.Data.ContactSchema]::BusinessPhone
    $propBusinessPhone2 = [Microsoft.Exchange.WebServices.Data.ContactSchema]::BusinessPhone2
    $propCallback = [Microsoft.Exchange.WebServices.Data.ContactSchema]::Callback
    $propCarPhone = [Microsoft.Exchange.WebServices.Data.ContactSchema]::CarPhone
    $propChildren = [Microsoft.Exchange.WebServices.Data.ContactSchema]::Children
    $propCompanies = [Microsoft.Exchange.WebServices.Data.ContactSchema]::Companies
    $propCompanyMainPhone = [Microsoft.Exchange.WebServices.Data.ContactSchema]::CompanyMainPhone
    $propCompanyName = [Microsoft.Exchange.WebServices.Data.ContactSchema]::CompanyName
    $propCompleteName = [Microsoft.Exchange.WebServices.Data.ContactSchema]::CompleteName
    $propContactSource = [Microsoft.Exchange.WebServices.Data.ContactSchema]::ContactSource
    $propDepartment = [Microsoft.Exchange.WebServices.Data.ContactSchema]::Department
    $propDirectoryId = [Microsoft.Exchange.WebServices.Data.ContactSchema]::DirectoryId
    $propDirectReports = [Microsoft.Exchange.WebServices.Data.ContactSchema]::DirectReports
    $propDisplayName = [Microsoft.Exchange.WebServices.Data.ContactSchema]::DisplayName
    $propEmailAddress1 = [Microsoft.Exchange.WebServices.Data.ContactSchema]::EmailAddress1
    $propEmailAddress2 = [Microsoft.Exchange.WebServices.Data.ContactSchema]::EmailAddress2
    $propEmailAddress3 = [Microsoft.Exchange.WebServices.Data.ContactSchema]::EmailAddress3
    #$propEmailAddresses = [Microsoft.Exchange.WebServices.Data.ContactSchema]::EmailAddresses
    $propFileAs = [Microsoft.Exchange.WebServices.Data.ContactSchema]::FileAs
    $propFileAsMapping = [Microsoft.Exchange.WebServices.Data.ContactSchema]::FileAsMapping
    $propGeneration = [Microsoft.Exchange.WebServices.Data.ContactSchema]::Generation
    $propGivenName = [Microsoft.Exchange.WebServices.Data.ContactSchema]::GivenName
    $propHasPicture = [Microsoft.Exchange.WebServices.Data.ContactSchema]::HasPicture
    $propHomeAddressCity = [Microsoft.Exchange.WebServices.Data.ContactSchema]::HomeAddressCity
    $propHomeAddressCountryOrRegion = [Microsoft.Exchange.WebServices.Data.ContactSchema]::HomeAddressCountryOrRegion
    $propHomeAddressPostalCode = [Microsoft.Exchange.WebServices.Data.ContactSchema]::HomeAddressPostalCode
    $propHomeAddressState = [Microsoft.Exchange.WebServices.Data.ContactSchema]::HomeAddressState
    $propHomeAddressStreet = [Microsoft.Exchange.WebServices.Data.ContactSchema]::HomeAddressStreet
    $propHomeFax = [Microsoft.Exchange.WebServices.Data.ContactSchema]::HomeFax
    $propHomePhone = [Microsoft.Exchange.WebServices.Data.ContactSchema]::HomePhone
    $propHomePhone2 = [Microsoft.Exchange.WebServices.Data.ContactSchema]::HomePhone2
    $propImAddress1 = [Microsoft.Exchange.WebServices.Data.ContactSchema]::ImAddress1
    $propImAddress2 = [Microsoft.Exchange.WebServices.Data.ContactSchema]::ImAddress2
    $propImAddress3 = [Microsoft.Exchange.WebServices.Data.ContactSchema]::ImAddress3
    #$propImAddresses = [Microsoft.Exchange.WebServices.Data.ContactSchema]::ImAddresses
    $propInitials = [Microsoft.Exchange.WebServices.Data.ContactSchema]::Initials
    $propIsdn = [Microsoft.Exchange.WebServices.Data.ContactSchema]::Isdn
    $propJobTitle = [Microsoft.Exchange.WebServices.Data.ContactSchema]::JobTitle
    $propManager = [Microsoft.Exchange.WebServices.Data.ContactSchema]::Manager
    $propManagerMailbox = [Microsoft.Exchange.WebServices.Data.ContactSchema]::ManagerMailbox
    $propMiddleName = [Microsoft.Exchange.WebServices.Data.ContactSchema]::MiddleName
    $propMileage = [Microsoft.Exchange.WebServices.Data.ContactSchema]::Mileage
    $propMobilePhone = [Microsoft.Exchange.WebServices.Data.ContactSchema]::MobilePhone
    $propMSExchangeCertificate = [Microsoft.Exchange.WebServices.Data.ContactSchema]::MSExchangeCertificate
    $propNickName = [Microsoft.Exchange.WebServices.Data.ContactSchema]::NickName
    $propNotes = [Microsoft.Exchange.WebServices.Data.ContactSchema]::Notes
    $propOfficeLocation = [Microsoft.Exchange.WebServices.Data.ContactSchema]::OfficeLocation
    $propOtherAddressCity = [Microsoft.Exchange.WebServices.Data.ContactSchema]::OtherAddressCity
    $propOtherAddressCountryOrRegion = [Microsoft.Exchange.WebServices.Data.ContactSchema]::OtherAddressCountryOrRegion
    $propOtherAddressPostalCode = [Microsoft.Exchange.WebServices.Data.ContactSchema]::OtherAddressPostalCode
    $propOtherAddressState = [Microsoft.Exchange.WebServices.Data.ContactSchema]::OtherAddressState
    $propOtherAddressStreet = [Microsoft.Exchange.WebServices.Data.ContactSchema]::OtherAddressStreet
    $propOtherFax = [Microsoft.Exchange.WebServices.Data.ContactSchema]::OtherFax
    $propOtherTelephone = [Microsoft.Exchange.WebServices.Data.ContactSchema]::OtherTelephone
    $propPager = [Microsoft.Exchange.WebServices.Data.ContactSchema]::Pager
    #$propPhoneNumbers = [Microsoft.Exchange.WebServices.Data.ContactSchema]::PhoneNumbers
    $propPhoneticFirstName = [Microsoft.Exchange.WebServices.Data.ContactSchema]::PhoneticFirstName
    $propPhoneticFullName = [Microsoft.Exchange.WebServices.Data.ContactSchema]::PhoneticFullName
    $propPhoneticLastName = [Microsoft.Exchange.WebServices.Data.ContactSchema]::PhoneticLastName
    $propPhoto = [Microsoft.Exchange.WebServices.Data.ContactSchema]::Photo
    #$propPhysicalAddresses = [Microsoft.Exchange.WebServices.Data.ContactSchema]::PhysicalAddresses
    $propPostalAddressIndex = [Microsoft.Exchange.WebServices.Data.ContactSchema]::PostalAddressIndex
    $propPrimaryPhone = [Microsoft.Exchange.WebServices.Data.ContactSchema]::PrimaryPhone
    $propProfession = [Microsoft.Exchange.WebServices.Data.ContactSchema]::Profession
    $propRadioPhone = [Microsoft.Exchange.WebServices.Data.ContactSchema]::RadioPhone
    $propSpouseName = [Microsoft.Exchange.WebServices.Data.ContactSchema]::SpouseName
    $propSurname = [Microsoft.Exchange.WebServices.Data.ContactSchema]::Surname
    $propTelex = [Microsoft.Exchange.WebServices.Data.ContactSchema]::Telex
    $propTtyTddPhone = [Microsoft.Exchange.WebServices.Data.ContactSchema]::TtyTddPhone
    $propUserSMIMECertificate = [Microsoft.Exchange.WebServices.Data.ContactSchema]::UserSMIMECertificate
    $propWeddingAnniversary = [Microsoft.Exchange.WebServices.Data.ContactSchema]::WeddingAnniversary

    while ($getMoreItems)
    {
        $view = new-object Microsoft.Exchange.WebServices.Data.ItemView($pageSize,$pageLimitOffset,[Microsoft.Exchange.WebServices.Data.OffsetBasePoint]::Beginning)
        $view.Traversal = [Microsoft.Exchange.WebServices.Data.ItemTraversal]::Shallow
        $view.PropertySet = new-object Microsoft.Exchange.WebServices.Data.PropertySet($propAlias, $propAssistantName, $propAssistantPhone, $propBirthday, $propBusinessAddressCity, $propBusinessAddressCountryOrRegion, $propBusinessAddressPostalCode, $propBusinessAddressState, $propBusinessAddressStreet, $propBusinessFax, $propBusinessHomePage, $propBusinessPhone, $propBusinessPhone2, $propCallback, $propCarPhone, $propChildren, $propCompanies, $propCompanyMainPhone, $propCompanyName, $propCompleteName, $propContactSource, $propDepartment, $propDirectoryId, $propDirectReports, $propDisplayName, $propEmailAddress1, $propEmailAddress2, $propEmailAddress3, $propFileAs, $propFileAsMapping, $propGeneration, $propGivenName, $propHasPicture, $propHomeAddressCity, $propHomeAddressCountryOrRegion, $propHomeAddressPostalCode, $propHomeAddressState, $propHomeAddressStreet, $propHomeFax, $propHomePhone, $propHomePhone2, $propImAddress1, $propImAddress2, $propImAddress3, $propInitials, $propIsdn, $propJobTitle, $propManager, $propManagerMailbox, $propMiddleName, $propMileage, $propMobilePhone, $propMSExchangeCertificate, $propNickName, $propNotes, $propOfficeLocation, $propOtherAddressCity, $propOtherAddressCountryOrRegion, $propOtherAddressPostalCode, $propOtherAddressState, $propOtherAddressStreet, $propOtherFax, $propOtherTelephone, $propPager, $propPhoneticFirstName, $propPhoneticFullName, $propPhoneticLastName, $propPhoto, $propPostalAddressIndex, $propPrimaryPhone, $propProfession, $propRadioPhone, $propSpouseName, $propSurname, $propTelex, $propTtyTddPhone, $propUserSMIMECertificate, $propWeddingAnniversary);

        $searchFilterDisplayName = New-Object Microsoft.Exchange.WebServices.Data.SearchFilter+Exists($propDisplayName)
        $searchFilters = New-Object Microsoft.Exchange.WebServices.Data.SearchFilter+SearchFilterCollection([Microsoft.Exchange.WebServices.Data.LogicalOperator]::Or)
        $searchFilters.add($searchFilterDisplayName)

        $contactItems = $Service.FindItems([Microsoft.Exchange.WebServices.Data.WellKnownFolderName]::Contacts, $searchFilters, $view)

        foreach ($item in $contactItems.Items)
        {
            if ($item.GetType().FullName -eq 'Microsoft.Exchange.WebServices.Data.Contact')
            {
                $item | select *,
                    @{n='EmailAddress1';e={$_.EmailAddresses['EmailAddress1'].address}},
                    @{n='EmailAddress2';e={$_.EmailAddresses['EmailAddress2'].address}},
                    @{n='EmailAddress3';e={$_.EmailAddresses['EmailAddress3'].address}},
                    @{n='MobilePhone';e={$_.phonenumbers['MobilePhone']}},
                    @{n='ISDN';e={$_.phonenumbers['ISDN']}},
                    @{n='CarPhone';e={$_.phonenumbers['CarPhone']}},
                    @{n='HomePhone';e={$_.phonenumbers['HomePhone']}},
                    @{n='HomePhone2';e={$_.phonenumbers['HomePhone2']}},
                    @{n='BusinessPhone';e={$_.phonenumbers['BusinessPhone']}},
                    @{n='BusinessPhone2';e={$_.phonenumbers['BusinessPhone2']}},
                    @{n='BusinessFax';e={$_.phonenumbers['BusinessFax']}},
                    @{n='OtherFax';e={$_.phonenumbers['OtherFax']}},
                    @{n='HomeFax';e={$_.phonenumbers['HomeFax']}},
                    @{n='Pager';e={$_.phonenumbers['Pager']}},
                    @{n='OtherTelephone';e={$_.phonenumbers['OtherTelephone']}},
                    @{n='Callback';e={$_.phonenumbers['Callback']}},
                    @{n='CompanyMainPhone';e={$_.phonenumbers['CompanyMainPhone']}},
                    @{n='PrimaryPhone';e={$_.phonenumbers['PrimaryPhone']}},
                    @{n='AssistantPhone';e={$_.phonenumbers['AssistantPhone']}},
                    @{n='RadioPhone';e={$_.phonenumbers['RadioPhone']}},
                    @{n='TtyTddPhone';e={$_.phonenumbers['TtyTddPhone']}},
                    @{n='Telex';e={$_.phonenumbers['Telex']}},
                    @{n='ImAddresses1';e={$_.ImAddresses['ImAddresses1'].address}},
                    @{n='ImAddresses2';e={$_.ImAddresses['ImAddresses2'].address}},
                    @{n='ImAddresses3';e={$_.ImAddresses['ImAddresses3'].address}},
                    @{n='PhysicalAddress1Street';e={$_.physicaladdresses[0].street}},
                    @{n='PhysicalAddress1City';e={$_.physicaladdresses[0].City}},
                    @{n='PhysicalAddress1State';e={$_.physicaladdresses[0].State}},
                    @{n='PhysicalAddress1CountryOrRegion';e={$_.physicaladdresses[0].CountryOrRegion}},
                    @{n='PhysicalAddress1PostalCode';e={$_.physicaladdresses[0].PostalCode}},
                    @{n='PhysicalAddress2Street';e={$_.physicaladdresses[1].street}},
                    @{n='PhysicalAddress2City';e={$_.physicaladdresses[1].City}},
                    @{n='PhysicalAddress2State';e={$_.physicaladdresses[1].State}},
                    @{n='PhysicalAddress2CountryOrRegion';e={$_.physicaladdresses[1].CountryOrRegion}},
                    @{n='PhysicalAddress2PostalCode';e={$_.physicaladdresses[1].PostalCode}},
                    @{n='PhysicalAddress3Street';e={$_.physicaladdresses[2].street}},
                    @{n='PhysicalAddress3City';e={$_.physicaladdresses[2].City}},
                    @{n='PhysicalAddress3State';e={$_.physicaladdresses[2].State}},
                    @{n='PhysicalAddress3CountryOrRegion';e={$_.physicaladdresses[2].CountryOrRegion}},
                    @{n='PhysicalAddress3PostalCode';e={$_.physicaladdresses[2].PostalCode}}
            }
        }
    
        if ($contactItems.MoreAvailable -eq $false) {
            $getMoreItems = $false
        }

        if ($getMoreItems) {
            $pageLimitOffset += $pageSize
        }
    }
}
