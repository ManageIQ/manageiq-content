# Change Log

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)


## Unreleased as of Sprint 77 Ending 2018-01-15

### Added
- Auto approval for Cloud Vm reconfigure. [(#236)](https://github.com/ManageIQ/manageiq-content/pull/236)

### Fixed
- Refresh template if sealing failed [(#233)](https://github.com/ManageIQ/manageiq-content/pull/233)
- Only data storage domains in VM transform dialog [(#229)](https://github.com/ManageIQ/manageiq-content/pull/229)
- Add policy resolution call to vm_destroy for providers. [(#223)](https://github.com/ManageIQ/manageiq-content/pull/223)

## Unreleased as of Sprint 76 Ending 2018-01-01

### Added
- v2v: Storage mapping for mass migration [(#215)](https://github.com/ManageIQ/manageiq-content/pull/215)

### Fixed
- Added a retry_interval to VM Migrate state machine. [(#232)](https://github.com/ManageIQ/manageiq-content/pull/232)
- Check for both owner email and requester email for user quota. [(#230)](https://github.com/ManageIQ/manageiq-content/pull/230)
- Make container events belong to their container groups [(#225)](https://github.com/ManageIQ/manageiq-content/pull/225)

## Unreleased as of Sprint 75 Ending 2017-12-11

### Fixed
- Force full refresh for router based events [(#224)](https://github.com/ManageIQ/manageiq-content/pull/224)

### Removed
- Removed the schema values for PreDeleteFromProvider. [(#226)](https://github.com/ManageIQ/manageiq-content/pull/226)

## Unreleased as of Sprint 74 Ending 2017-11-27

### Fixed
- Add more aws event handlers [(#217)](https://github.com/ManageIQ/manageiq-content/pull/217)

## Gaprindashvili Beta2

### Fixed
- Add more aws event handlers [(#217)](https://github.com/ManageIQ/manageiq-content/pull/217)

## Unreleased as of Sprint 72 Ending 2017-10-30

### Added
- Auto approval for instance resize operation. [(#205)](https://github.com/ManageIQ/manageiq-content/pull/205)
- Nuage events callbacks for targeted refresh [(#204)](https://github.com/ManageIQ/manageiq-content/pull/204)
- Add policy event triggers for Hawkular [(#201)](https://github.com/ManageIQ/manageiq-content/pull/201)
- v2v: Extend 'VM Transform' dialog to select VMs by tag [(#200)](https://github.com/ManageIQ/manageiq-content/pull/200)
- Do targeted refresh in Stack check provisioned [(#182)](https://github.com/ManageIQ/manageiq-content/pull/182)

## Gaprindashvili Beta1

### Added
- Do targeted refresh based on Openstack events. [(#184)](https://github.com/ManageIQ/manageiq-content/pull/184)
- Add basic events handlers for AWS [(#183)](https://github.com/ManageIQ/manageiq-content/pull/183)
- Target template related actions [(#153)](https://github.com/ManageIQ/manageiq-content/pull/153)
- Do targeted refresh based on AWS events [(#178)](https://github.com/ManageIQ/manageiq-content/pull/178)
- Record the name of the actual VM to simplify debugging [(#175)](https://github.com/ManageIQ/manageiq-content/pull/175)
- Pre-check install_drivers checkbox for windows VMs [(#170)](https://github.com/ManageIQ/manageiq-content/pull/170)
- v2v: Rephrase ISO driver selection [(#169)](https://github.com/ManageIQ/manageiq-content/pull/169)
- Support TTL (Time To Live) value for services. [(#162)](https://github.com/ManageIQ/manageiq-content/pull/162)
- AWS DetachVolume event switchboard setting. [(#164)](https://github.com/ManageIQ/manageiq-content/pull/164)
- New refresh method callable from the automate [(#159)](https://github.com/ManageIQ/manageiq-content/pull/159)
- Fix message when import fails [(#161)](https://github.com/ManageIQ/manageiq-content/pull/161)
- Support TTL (Time To Live) value for services. [(#148)](https://github.com/ManageIQ/manageiq-content/pull/148)
- v2v: Support virtio-win drivers ISO [(#147)](https://github.com/ManageIQ/manageiq-content/pull/147)
- Targeted refresh enhacements for VM import\rename\migration events [(#119)](https://github.com/ManageIQ/manageiq-content/pull/119)

### Fixed
- Added active provisions to quota count. [(#196)](https://github.com/ManageIQ/manageiq-content/pull/196)
- Fixed calculation for Ansible playbook service max TTL. [(#193)](https://github.com/ManageIQ/manageiq-content/pull/193)
- Fix VM Migrate complete email when To field is nil. [(#177)](https://github.com/ManageIQ/manageiq-content/pull/177)
- Fixed an issue when trying to retire a service that is already in the process of being retired. [(#189)](https://github.com/ManageIQ/manageiq-content/pull/189)
- Changed ae_retry_limit = 1.minute to ae_retry_interval = 1.minute. [(#151)](https://github.com/ManageIQ/manageiq-content/pull/151)
- Changes made in Wait_for_ip and Wait_for_completion methods in [(#152)](https://github.com/ManageIQ/manageiq-content/pull/152)
- v2v: Handle IMPORTEXPORT_STARTING_IMPORT_VM event [(#149)](https://github.com/ManageIQ/manageiq-content/pull/149)
- Set retry interval to 1 minute for generic service state-machine. [(#163)](https://github.com/ManageIQ/manageiq-content/pull/163)
- v2v: Fix filtering of drivers ISO to display [(#143)](https://github.com/ManageIQ/manageiq-content/pull/143)
- Fixed quota calculations for multiple vms in requested method. [(#128)](https://github.com/ManageIQ/manageiq-content/pull/128)
- Add Available_Projects method for dynamic dropdown in container template service dialog [(#127)](https://github.com/ManageIQ/manageiq-content/pull/127)
- Require just rails/engine [(#120)](https://github.com/ManageIQ/manageiq-content/pull/120)
- Support embedded_ansible to fetch credentials from provider [(#112)](https://github.com/ManageIQ/manageiq-content/pull/112)

## Fine-3

### Added
- Add automate methods for VM import between providers [(#36)](https://github.com/ManageIQ/manageiq-content/pull/36)
- v2v: Add support for driver ISOs [(#121)](https://github.com/ManageIQ/manageiq-content/pull/121)
- v2v: Add automate methods for post-import network configuration [(#123)](https://github.com/ManageIQ/manageiq-content/pull/123)
- Event switchboard entries for Amazon EBS events. [(#137)](https://github.com/ManageIQ/manageiq-content/pull/137)

### Changed
- Update method order_ansible_playbook.rb to match the move of create_service_provision_request [(#126)](https://github.com/ManageIQ/manageiq-content/pull/126)

### Fixed
- Change errors in log to error type. [(#101)](https://github.com/ManageIQ/manageiq-content/pull/101)
- Changed ${/#ae_reason} to a string value in on_error methods. [(#98)](https://github.com/ManageIQ/manageiq-content/pull/98)
- Add quota checking for VMReconfigure tests. [(#56)](https://github.com/ManageIQ/manageiq-content/pull/56)
- Change exceeds message in log to warn type. [(#104)](https://github.com/ManageIQ/manageiq-content/pull/104)
- Remove VM reconfiguration email. [(#116)](https://github.com/ManageIQ/manageiq-content/pull/116)
- OrderAnsiblePlaybook method should collect machine credential. [(118)](https://github.com/ManageIQ/manageiq-content/pull/118)
- v2v: Fix confusing message in WaitForImport state [(#140)](https://github.com/ManageIQ/manageiq-content/pull/140)
- v2v: Fix list drivers on missing ISO domain [(#139)](https://github.com/ManageIQ/manageiq-content/pull/139)

## Fine-2

### Added
- Order Ansible Playbook from a Custom Button using a Method. [(#113)](https://github.com/ManageIQ/manageiq-content/pull/113)

## Fine-1

### Added
- Remove createfolder event handler since it is now handled by MiqVimBrokerWorker [(#100)](https://github.com/ManageIQ/manageiq-content/pull/100)
- Added LenovoXclarity Namespace to EMS Events into Automate [(#77)](https://github.com/ManageIQ/manageiq-content/pull/77)
- Automate - Notification for Ansible and Cloud provisioning errors. [(#15)](https://github.com/ManageIQ/manageiq-content/pull/15)
- Generic Service State Machine update_status change [(#85)](https://github.com/ManageIQ/manageiq-content/pull/85)
- Generic Service State Machine - new retirement instances. [(#72)](https://github.com/ManageIQ/manageiq-content/pull/72)
- Add Automate modeling for Embedded Ansible Events. [(#69)](https://github.com/ManageIQ/manageiq-content/pull/69)
- Add Automate modeling for External Ansible Tower Events. [(#68)](https://github.com/ManageIQ/manageiq-content/pull/68)
- Change default behavior of Service Retirement to not remove the Service [(#76)](https://github.com/ManageIQ/manageiq-content/pull/76)
- Generic Service State Machine - added notifications and improved logging. [(#61)](https://github.com/ManageIQ/manageiq-content/pull/61)
- Automate method to list ansible credentials [(#53)](https://github.com/ManageIQ/manageiq-content/pull/53)
- Add openstack cloud tenant events [(#59)](https://github.com/ManageIQ/manageiq-content/pull/59)

### Changed
- In the F release ConfigurationManagement has been deprecated [(#87)](https://github.com/ManageIQ/manageiq-content/pull/87)
- Refactoring and fixing cloud/vm/provisioning/placement/best_fit_amazon method. [(#63)](https://github.com/ManageIQ/manageiq-content/pull/63)
- Generic Service State Machine method update. [(#51)](https://github.com/ManageIQ/manageiq-content/pull/51)
- Generic Service State Machine methods modified to use Service object. [(#58)](https://github.com/ManageIQ/manageiq-content/pull/58)

### Fixed
- Add notifications for finish_retirement. [(#106)](https://github.com/ManageIQ/manageiq-content/pull/106)
- Add policy checking for the retirement request. [(#86)](https://github.com/ManageIQ/manageiq-content/pull/86)
- Modified vmware_best_fit_least_utilized to not select Hosts in maintenance. [(#81)](https://github.com/ManageIQ/manageiq-content/pull/81)
- Added method instances for EmbeddedAnsible [(#80)](https://github.com/ManageIQ/manageiq-content/pull/80)
- Fixes VM extend retirement [(#62)](https://github.com/ManageIQ/manageiq-content/pull/62)
- Disabled DeleteFromVMDB in 2 places [(#55)](https://github.com/ManageIQ/manageiq-content/pull/55)
- Fixed typo in check_ssh method [(#66)](https://github.com/ManageIQ/manageiq-content/pull/66)
- Generic State Machine provision instance fix [(#54)](https://github.com/ManageIQ/manageiq-content/pull/54)
