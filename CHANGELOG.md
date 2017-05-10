# Change Log

All notable changes to this project will be documented in this file.

## Fine-1

### Added
- Support embedded_ansible to fetch credentials from provider [(#112)](https://github.com/ManageIQ/manageiq-content/pull/112)
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
