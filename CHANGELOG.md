# Change Log

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)


## Hammer-2

### Added
- Add handler for compute.instance.update [(#497)](https://github.com/ManageIQ/manageiq-content/pull/497)

## Unreleased as of Sprint 102 ending 2019-01-07

### Fixed
- #raw_stdout does not exist for workflow template job. [(#491)](https://github.com/ManageIQ/manageiq-content/pull/491)
- Fix missing word in provisioning mail's subject and body [(#484)](https://github.com/ManageIQ/manageiq-content/pull/484)

## Hammer-1 - Released 2019-01-15

### Added
- Deny request if no conversion host is configured [(#455)](https://github.com/ManageIQ/manageiq-content/pull/455)
- Use task cancelation_status to trigger cancelation [(#457)](https://github.com/ManageIQ/manageiq-content/pull/457)
- Use embedded log method. [(#427)](https://github.com/ManageIQ/manageiq-content/pull/427)
- Adding log_and_notify method into log_object embedded method. [(#423)](https://github.com/ManageIQ/manageiq-content/pull/423)
- Transformation throttling - Base components [(#418)](https://github.com/ManageIQ/manageiq-content/pull/418)
- Adding log and raise error method into log_object embedded method. [(#416)](https://github.com/ManageIQ/manageiq-content/pull/416)
- Added log_and_exit utility method [(#414)](https://github.com/ManageIQ/manageiq-content/pull/414)
- Add plugin display name [(#411)](https://github.com/ManageIQ/manageiq-content/pull/411)
- Trigger Nuage targeted refresh more often [(#409)](https://github.com/ManageIQ/manageiq-content/pull/409)
- Prepare Nuage authentication attributes (for Embedded Ansible) [(#406)](https://github.com/ManageIQ/manageiq-content/pull/406)
- Change VMware URI to connect directly to ESXi [(#405)](https://github.com/ManageIQ/manageiq-content/pull/405)
- Add state_machine_phase attribute to transformation state machines [(#402)](https://github.com/ManageIQ/manageiq-content/pull/402)
- Add CustomButtonEvent to automate explorer [(#398)](https://github.com/ManageIQ/manageiq-content/pull/398)
- Adding Inspectme functionality into log_object embedded method. [(#386)](https://github.com/ManageIQ/manageiq-content/pull/386)
- Add Openstack volume.update.end event handler [(#401)](https://github.com/ManageIQ/manageiq-content/pull/401)
- Restore VM ownership and retirement when migrating [(#397)](https://github.com/ManageIQ/manageiq-content/pull/397)
- Created log_object method in System/CommonMethods/Utils class [(#362)](https://github.com/ManageIQ/manageiq-content/pull/362)
- Trigger targeted refresh for new Nuage entities [(#367)](https://github.com/ManageIQ/manageiq-content/pull/367)
- (Nuage Networks) Actually rename AE Instances not just fixture filename [(#365)](https://github.com/ManageIQ/manageiq-content/pull/365)
- Requested Quota for instance_type dialog override. [(#333)](https://github.com/ManageIQ/manageiq-content/pull/333)
- (Nuage Networks) Adjust Automate Instance names to new event type prefix [(#363)](https://github.com/ManageIQ/manageiq-content/pull/363)
- Add checks for retirement of correct child service in bundle [(#284)](https://github.com/ManageIQ/manageiq-content/pull/284)
- Add a precanned physical server automation event [(#339)](https://github.com/ManageIQ/manageiq-content/pull/339)
- Raise policy event when HOST_FAILURE is received. [(#329)](https://github.com/ManageIQ/manageiq-content/pull/329)
- Email instances for Cloud/Orchestration. [(#314)](https://github.com/ManageIQ/manageiq-content/pull/314)
- Email instances for VmMigrate and Reconfiguration. [(#311)](https://github.com/ManageIQ/manageiq-content/pull/311)
- Email instances for Service provisioning. [(#313)](https://github.com/ManageIQ/manageiq-content/pull/313)
- Email instances for Automation/Management/AnsibleTower provisioning. [(#310)](https://github.com/ManageIQ/manageiq-content/pull/310)
- Email instances for Host provisioning. [(#309)](https://github.com/ManageIQ/manageiq-content/pull/309)
- Email instances for /Infrastructure/Configured_System provisioning. [(#308)](https://github.com/ManageIQ/manageiq-content/pull/308)
- Updated existing V2v instances in Configuration/Email. [(#307)](https://github.com/ManageIQ/manageiq-content/pull/307)
- Updated Email instances for Cloud VM provisioning. [(#306)](https://github.com/ManageIQ/manageiq-content/pull/306)
- Updated Email instances for Infra VM provisioning. [(#305)](https://github.com/ManageIQ/manageiq-content/pull/305)
- Email instances for Cloud and Infrastructure retirement. [(#304)](https://github.com/ManageIQ/manageiq-content/pull/304)
- Email instances for Infra VM provisioning. [(#303)](https://github.com/ManageIQ/manageiq-content/pull/303)
- Email instances for Cloud VM provisioning. [(#302)](https://github.com/ManageIQ/manageiq-content/pull/302)
- Updated Configuration/Email class and existing V2v instances. [(#300)](https://github.com/ManageIQ/manageiq-content/pull/300)
- Created new namespace for Configuration/Email. [(#299)](https://github.com/ManageIQ/manageiq-content/pull/299)
- Change check for start_retirement to not initialized vs retiring [(#281)](https://github.com/ManageIQ/manageiq-content/pull/281)
- Add changes for service vm retire request approval [(#272)](https://github.com/ManageIQ/manageiq-content/pull/272)
- Add task status update to retirement status [(#262)](https://github.com/ManageIQ/manageiq-content/pull/262)
- Nuage events callbacks for targeted refresh [(#204)](https://github.com/ManageIQ/manageiq-content/pull/204)
- Add policy event triggers for Hawkular [(#201)](https://github.com/ManageIQ/manageiq-content/pull/201)
- v2v: Extend 'VM Transform' dialog to select VMs by tag [(#200)](https://github.com/ManageIQ/manageiq-content/pull/200)
- Add support to apply right-size recommendation during transformation [(#417)](https://github.com/ManageIQ/manageiq-content/pull/417)
- [V2V] Allow a retry to let virt-v2v start [(#479)](https://github.com/ManageIQ/manageiq-content/pull/479)

### Changed
- Changed validate_quota method to check individual quota items [(#375)](https://github.com/ManageIQ/manageiq-content/pull/375)

### Fixed
- Fix request denial [(#471)](https://github.com/ManageIQ/manageiq-content/pull/471)
- Fix TransformationPlanRequest approval - Set message [(#473)](https://github.com/ManageIQ/manageiq-content/pull/473)
- Modified requested method for reconfigure disk_remove. [(#461)](https://github.com/ManageIQ/manageiq-content/pull/461)
- Changed disk_name to symbol in requested Quota method. [(#474)](https://github.com/ManageIQ/manageiq-content/pull/474)
- Apply updates to the manageiq-automate Ansible role [(#454)](https://github.com/ManageIQ/manageiq-content/pull/454)
- Modified InspectMe method to check if object is taggable. [(#445)](https://github.com/ManageIQ/manageiq-content/pull/445)
- Modified Log_Object method to check if object is taggable. [(#446)](https://github.com/ManageIQ/manageiq-content/pull/446)
- Add storage profile support in vmware_best_fit_least_utilized method. [(#420)](https://github.com/ManageIQ/manageiq-content/pull/420)
- Updated requested method to fix vm_reconfigure via rest-api. [(#413)](https://github.com/ManageIQ/manageiq-content/pull/413)
- Do not check instance variables in specs for Transformation - Common - Utils [(#410)](https://github.com/ManageIQ/manageiq-content/pull/410)
- Escape username of VMware host [(#407)](https://github.com/ManageIQ/manageiq-content/pull/407)
- Add event handling for Openstack port events [(#372)](https://github.com/ManageIQ/manageiq-content/pull/372)
- Event handling for Openstack keypair events [(#371)](https://github.com/ManageIQ/manageiq-content/pull/371)
- Fix quota requested cloud_volume calculations. [(#388)](https://github.com/ManageIQ/manageiq-content/pull/388)
- Added vm_retire_extend method for new email. [(#366)](https://github.com/ManageIQ/manageiq-content/pull/366)
- Add event handling for Openstack volume attachment events [(#368)](https://github.com/ManageIQ/manageiq-content/pull/368)
- Remove check for a state of initialized in 4 start_retirement methods. [(#331)](https://github.com/ManageIQ/manageiq-content/pull/331)
- handle volume snapshot status changes [(#285)](https://github.com/ManageIQ/manageiq-content/pull/285)
- Move the task message into check for task presence [(#283)](https://github.com/ManageIQ/manageiq-content/pull/283)
- Add tests for orchestration stack retirement [(#437)](https://github.com/ManageIQ/manageiq-content/pull/437)
- Keep the encrypted value as is when creating service provision request. [(#435)](https://github.com/ManageIQ/manageiq-content/pull/435)
- Fix userid in transformation throttler launch [(#439)](https://github.com/ManageIQ/manageiq-content/pull/439)
- Disconnect storage when disconnecting a VM [(#472)](https://github.com/ManageIQ/manageiq-content/pull/472)
- #raw_stdout does not exist for workflow template job. [(#491)](https://github.com/ManageIQ/manageiq-content/pull/491)

##  Unreleased as of Sprint 101 Ending 2018-12-17

### Added
- Added Quota calculations for reconfigure resize disks [(#436)](https://github.com/ManageIQ/manageiq-content/pull/436)

## Gaprindashvili-6 - Released 2018-11-02

### Added
- Add state_machine_phase attribute to transformation state machines [(#402)](https://github.com/ManageIQ/manageiq-content/pull/402)
- Change VMware URI to connect directly to ESXi [(#405)](https://github.com/ManageIQ/manageiq-content/pull/405)
- Restore VM ownership and retirement when migrating [(#397)](https://github.com/ManageIQ/manageiq-content/pull/397)
- Add support to apply right-size recommendation during transformation [(#417)](https://github.com/ManageIQ/manageiq-content/pull/417)

### Fixed
- Escape username of VMware host [(#407)](https://github.com/ManageIQ/manageiq-content/pull/407)
- Updated requested method to fix vm_reconfigure via rest-api. [(#413)](https://github.com/ManageIQ/manageiq-content/pull/413)
- Add storage profile support in vmware_best_fit_least_utilized method. [(#420)](https://github.com/ManageIQ/manageiq-content/pull/420)

## Gaprindashvili-5 - Released 2018-09-07

### Added
- Add support for pre/post-migration playbook [(#355)](https://github.com/ManageIQ/manageiq-content/pull/355)
- Refactor set retry for pre/post migration playbooks [(#369)](https://github.com/ManageIQ/manageiq-content/pull/369)
- Refactor to add support for SSH transport method [(#359)](https://github.com/ManageIQ/manageiq-content/pull/359)
- Allow running playbook against powered off VM [(#380)](https://github.com/ManageIQ/manageiq-content/pull/380)
- Add support for MAC address in network mapping [(#351)](https://github.com/ManageIQ/manageiq-content/pull/351)
- Use targeted refresh during transformation [(#381)](https://github.com/ManageIQ/manageiq-content/pull/381)
- Update WeightedUpdateStatus to handle task cancellation and cleanup [(#357)](https://github.com/ManageIQ/manageiq-content/pull/357)
- Add default cleanup state machine for VM transformation [(#378)](https://github.com/ManageIQ/manageiq-content/pull/378)

### Fixed
- Fix default cleanup state machine [(#382)](https://github.com/ManageIQ/manageiq-content/pull/382)
- Transformation - Fix virt-v2v success check [(#393)](https://github.com/ManageIQ/manageiq-content/pull/393)
- Fix cleanup state machine path build [(#392)](https://github.com/ManageIQ/manageiq-content/pull/392)
- Fix hook string passing for pre/post-migration playbooks [(#370)](https://github.com/ManageIQ/manageiq-content/pull/370)
- Fix computation of currently running conversions by host [(#358)](https://github.com/ManageIQ/manageiq-content/pull/358)
- Fix transformation host selection [(#379)](https://github.com/ManageIQ/manageiq-content/pull/379)
- Fix weightedupdatestatus for cancellation [(#377)](https://github.com/ManageIQ/manageiq-content/pull/377)

### Removed
- Remove check on number of runners when converting VM [(#395)](https://github.com/ManageIQ/manageiq-content/pull/395)

## Gaprindashvili-4 - Released 2018-07-16

### Added
- New email consolidated namespace and class. [(#246)](https://github.com/ManageIQ/manageiq-content/pull/246)
- Automation for transformation plan [(#244)](https://github.com/ManageIQ/manageiq-content/pull/244)
- V2V - State machines - Initial work [(#248)](https://github.com/ManageIQ/manageiq-content/pull/248)
- Add VM Transformation state machine [(#252)](https://github.com/ManageIQ/manageiq-content/pull/252)
- Add V2V for VMware to oVirt / RHV [(#301)](https://github.com/ManageIQ/manageiq-content/pull/301)
- Tag migrated VM. [(#324)](https://github.com/ManageIQ/manageiq-content/pull/324)
- Add extra empty states to allow pre and post states. [(#338)](https://github.com/ManageIQ/manageiq-content/pull/338)
- Add a state to restore VM attributes during migration. [(#340)](https://github.com/ManageIQ/manageiq-content/pull/340)

### Fixed
- Calculate quota using service dialogs overrides. [(#203)](https://github.com/ManageIQ/manageiq-content/pull/203)
- Modify on {entry,exit,error} path to use WeightedUpdateStatus [(#265)](https://github.com/ManageIQ/manageiq-content/pull/265)
- Fix ManageIQ/manageiq-content/issues/275 [(#276)](https://github.com/ManageIQ/manageiq-content/pull/276)
- Fix System/CommonMethods/MiqAe directory name [(#312)](https://github.com/ManageIQ/manageiq-content/pull/312)
- Set insecure_connection to target provider as default behavior. [(#327)](https://github.com/ManageIQ/manageiq-content/pull/327)
- Restore VM power state upon transformation [(#336)](https://github.com/ManageIQ/manageiq-content/pull/336)

## Gaprindashvili-3 - Released 2018-05-15

### Added
- Add azure event handlers for targeted refresh [(#260)](https://github.com/ManageIQ/manageiq-content/pull/260)
- Add Azure events for targeted refresh [(#261)](https://github.com/ManageIQ/manageiq-content/pull/261)
- Add in the miq. automate and vmdb roles [(#254)](https://github.com/ManageIQ/manageiq-content/pull/254)

### Fixed
- Add event state machine for refresh. [(#243)](https://github.com/ManageIQ/manageiq-content/pull/243)

## Gaprindashvili-1 - Released 2018-01-31

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
- v2v: Storage mapping for mass migration [(#215)](https://github.com/ManageIQ/manageiq-content/pull/215)
- Auto approval for Cloud Vm reconfigure [(#236)](https://github.com/ManageIQ/manageiq-content/pull/236)

### Fixed
- Force full refresh for router based events [(#224)](https://github.com/ManageIQ/manageiq-content/pull/224)
- Add more aws event handlers [(#217)](https://github.com/ManageIQ/manageiq-content/pull/217)
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
- Make container events belong to their container groups [(#225)](https://github.com/ManageIQ/manageiq-content/pull/225)
- Check for both owner email and requester email for user quota [(#230)](https://github.com/ManageIQ/manageiq-content/pull/230)
- Added a retry_interval to VM Migrate state machine [(#232)](https://github.com/ManageIQ/manageiq-content/pull/232)
- Refresh template if sealing failed [(#233)](https://github.com/ManageIQ/manageiq-content/pull/233)
- Only data storage domains in VM transform dialog [(#229)](https://github.com/ManageIQ/manageiq-content/pull/229)
- Add policy resolution call to vm_destroy for providers. [(#223)](https://github.com/ManageIQ/manageiq-content/pull/223)

### Removed
- Removed the schema values for PreDeleteFromProvider. [(#226)](https://github.com/ManageIQ/manageiq-content/pull/226)

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

## Initial changelog added
