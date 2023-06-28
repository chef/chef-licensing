# Changelog

<!-- latest_release 0.4.40 -->
## [0.4.40](https://github.com/chef/chef-licensing/tree/0.4.40) (2023-06-28)

#### Merged Pull Requests
- CHEF-3726: Restrict setting certain options via arguments or environment variables; confine to config block only [#138](https://github.com/chef/chef-licensing/pull/138) ([ahasunos](https://github.com/ahasunos))
<!-- latest_release -->

<!-- release_rollup -->
### Changes not yet released to rubygems.org

#### Merged Pull Requests
- CHEF-3726: Restrict setting certain options via arguments or environment variables; confine to config block only [#138](https://github.com/chef/chef-licensing/pull/138) ([ahasunos](https://github.com/ahasunos)) <!-- 0.4.40 -->
- Remove traces of air_gap_detected method [#140](https://github.com/chef/chef-licensing/pull/140) ([ahasunos](https://github.com/ahasunos)) <!-- 0.4.39 -->
- Improve TUI Engine&#39;s error message to debug broken flows [#143](https://github.com/chef/chef-licensing/pull/143) ([ahasunos](https://github.com/ahasunos)) <!-- 0.4.38 -->
- CHEF-3698: Add `--chef-license-server` to Chef Licensing CLI Flags [#137](https://github.com/chef/chef-licensing/pull/137) ([ahasunos](https://github.com/ahasunos)) <!-- 0.4.37 -->
- Feature/CHEF-3553 improve error handling [#136](https://github.com/chef/chef-licensing/pull/136) ([sathish-progress](https://github.com/sathish-progress)) <!-- 0.4.36 -->
- CHEF-3666 Global service detection to use 404 status code [#134](https://github.com/chef/chef-licensing/pull/134) ([Nik08](https://github.com/Nik08)) <!-- 0.4.35 -->
- CHEF-3276 UX revised changes on expiration flow [#133](https://github.com/chef/chef-licensing/pull/133) ([Nik08](https://github.com/Nik08)) <!-- 0.4.34 -->
- Error handling for license expiration check - client API [#127](https://github.com/chef/chef-licensing/pull/127) ([Nik08](https://github.com/Nik08)) <!-- 0.4.33 -->
- CHEF-3277: Fix UX for Skip step in chef licensing [#131](https://github.com/chef/chef-licensing/pull/131) ([ahasunos](https://github.com/ahasunos)) <!-- 0.4.32 -->
- CHEF-3578: Support log level and log location capabilities for chef licensing logger [#125](https://github.com/chef/chef-licensing/pull/125) ([ahasunos](https://github.com/ahasunos)) <!-- 0.4.31 -->
- HACK: Remove warn level log message to fix omnibus test for inspec [#130](https://github.com/chef/chef-licensing/pull/130) ([ahasunos](https://github.com/ahasunos)) <!-- 0.4.30 -->
- CHEF-3276 UI/UX revised changes in expiration flow [#111](https://github.com/chef/chef-licensing/pull/111) ([Nik08](https://github.com/Nik08)) <!-- 0.4.29 -->
- CHEF-3259: Modify license list command to fetch license information from local license server [#117](https://github.com/chef/chef-licensing/pull/117) ([ahasunos](https://github.com/ahasunos)) <!-- 0.4.28 -->
- CHEF-3184 Disable license keys persist in local license service mode [#121](https://github.com/chef/chef-licensing/pull/121) ([Nik08](https://github.com/Nik08)) <!-- 0.4.27 -->
- CHEF-3594: Test Commercial License UX in License Generation Menu [#128](https://github.com/chef/chef-licensing/pull/128) ([ahasunos](https://github.com/ahasunos)) <!-- 0.4.26 -->
- Return license server url to config in all case [#126](https://github.com/chef/chef-licensing/pull/126) ([ahasunos](https://github.com/ahasunos)) <!-- 0.4.25 -->
- Malformed license key format graceful error handling [#124](https://github.com/chef/chef-licensing/pull/124) ([Nik08](https://github.com/Nik08)) <!-- 0.4.24 -->
- CHEF-77: UX tests for trial license scenarios [#122](https://github.com/chef/chef-licensing/pull/122) ([ahasunos](https://github.com/ahasunos)) <!-- 0.4.23 -->
- FIX: Do not raise exception as we handled and logged it already [#123](https://github.com/chef/chef-licensing/pull/123) ([ahasunos](https://github.com/ahasunos)) <!-- 0.4.22 -->
- CHEF-3374 - Updates the commercial option to show contact us link [#118](https://github.com/chef/chef-licensing/pull/118) ([Vasu1105](https://github.com/Vasu1105)) <!-- 0.4.21 -->
- CHEF-2861 Form validation revised for name and company name [#107](https://github.com/chef/chef-licensing/pull/107) ([Nik08](https://github.com/Nik08)) <!-- 0.4.20 -->
- CHEF-3258 Integration to fetch license keys from local licensing service using API [#119](https://github.com/chef/chef-licensing/pull/119) ([Nik08](https://github.com/Nik08)) <!-- 0.4.19 -->
- CHEF-2507 Detect local and global licensing service [#104](https://github.com/chef/chef-licensing/pull/104) ([Nik08](https://github.com/Nik08)) <!-- 0.4.18 -->
- CHEF-78: UX testing for free license scenarios [#112](https://github.com/chef/chef-licensing/pull/112) ([ahasunos](https://github.com/ahasunos)) <!-- 0.4.17 -->
- CHEF-3278 Display validity for free license as Unlimited in the license details [#116](https://github.com/chef/chef-licensing/pull/116) ([Vasu1105](https://github.com/Vasu1105)) <!-- 0.4.16 -->
- List license typo fix and restful client cleanup [#113](https://github.com/chef/chef-licensing/pull/113) ([Nik08](https://github.com/Nik08)) <!-- 0.4.15 -->
- CHEF-3277: Change UX for Skip step in chef licensing [#110](https://github.com/chef/chef-licensing/pull/110) ([ahasunos](https://github.com/ahasunos)) <!-- 0.4.14 -->
- CHEF-3275: Minor change in UI message and format [#109](https://github.com/chef/chef-licensing/pull/109) ([ahasunos](https://github.com/ahasunos)) <!-- 0.4.13 -->
- CHEF-2516 Update UI text [#108](https://github.com/chef/chef-licensing/pull/108) ([IanMadd](https://github.com/IanMadd)) <!-- 0.4.12 -->
- CHEF-2435: Integrate `listlicenses` API to fetch licenses [#105](https://github.com/chef/chef-licensing/pull/105) ([ahasunos](https://github.com/ahasunos)) <!-- 0.4.11 -->
- CHEF-3186: Remove bearer token authentication [#106](https://github.com/chef/chef-licensing/pull/106) ([ahasunos](https://github.com/ahasunos)) <!-- 0.4.10 -->
- CHEF-3113: Update licensing server&#39;s endpoint  [#101](https://github.com/chef/chef-licensing/pull/101) ([ahasunos](https://github.com/ahasunos)) <!-- 0.4.9 -->
- CHEF-2901: Restrict addition of free license when user has an active trial license [#100](https://github.com/chef/chef-licensing/pull/100) ([ahasunos](https://github.com/ahasunos)) <!-- 0.4.8 -->
- CHEF-1959: Display Unlimited licenses properly for trial licenses [#103](https://github.com/chef/chef-licensing/pull/103) ([ahasunos](https://github.com/ahasunos)) <!-- 0.4.7 -->
- Fix typo in the missing credentials message [#102](https://github.com/chef/chef-licensing/pull/102) ([Vasu1105](https://github.com/Vasu1105)) <!-- 0.4.6 -->
- CHEF-48 Multiple Free License restrictions [#95](https://github.com/chef/chef-licensing/pull/95) ([Nik08](https://github.com/Nik08)) <!-- 0.4.5 -->
- CHEF-2743: Remove inspec-specific references in chef-licensing [#99](https://github.com/chef/chef-licensing/pull/99) ([ahasunos](https://github.com/ahasunos)) <!-- 0.4.4 -->
- CHEF-2505: Determine how to write unit test for UX components [#96](https://github.com/chef/chef-licensing/pull/96) ([ahasunos](https://github.com/ahasunos)) <!-- 0.4.3 -->
- DOCS: Update docs for the chef-licensing endpoints [#94](https://github.com/chef/chef-licensing/pull/94) ([ahasunos](https://github.com/ahasunos)) <!-- 0.4.2 -->
- CHEF-2314 No prompt for same license id addition using env and argument [#93](https://github.com/chef/chef-licensing/pull/93) ([Nik08](https://github.com/Nik08)) <!-- 0.4.1 -->
- CHEF-1957: Update method-name and responsibilities [#91](https://github.com/chef/chef-licensing/pull/91) ([ahasunos](https://github.com/ahasunos)) <!-- 0.4.0 -->
- CHEF-58: Create Free License Text User Interface in Client Library (Hide Options) [#92](https://github.com/chef/chef-licensing/pull/92) ([ahasunos](https://github.com/ahasunos)) <!-- 0.3.54 -->
- CHEF-76 CHEF-1748 Trial License restrictions [#87](https://github.com/chef/chef-licensing/pull/87) ([Nik08](https://github.com/Nik08)) <!-- 0.3.53 -->
- CHEF-76 CHEF-1747 Store license type information in license file [#79](https://github.com/chef/chef-licensing/pull/79) ([Nik08](https://github.com/Nik08)) <!-- 0.3.52 -->
- CHEF-1499 Verify trial expiration flow [#76](https://github.com/chef/chef-licensing/pull/76) ([Nik08](https://github.com/Nik08)) <!-- 0.3.51 -->
- CHEF-1974: Improve error handling for describe API [#86](https://github.com/chef/chef-licensing/pull/86) ([ahasunos](https://github.com/ahasunos)) <!-- 0.3.50 -->
- CHEF-61: Verify commercial license entry works [#88](https://github.com/chef/chef-licensing/pull/88) ([ahasunos](https://github.com/ahasunos)) <!-- 0.3.49 -->
- CHEF-54: Update serial number regex and test associated with the change [#85](https://github.com/chef/chef-licensing/pull/85) ([ahasunos](https://github.com/ahasunos)) <!-- 0.3.48 -->
- CHEF-1497: Implement Feedback from Verification of Trial License Generation [#82](https://github.com/chef/chef-licensing/pull/82) ([ahasunos](https://github.com/ahasunos)) <!-- 0.3.47 -->
- Refactored License key fetcher library to enable reusability [#84](https://github.com/chef/chef-licensing/pull/84) ([Nik08](https://github.com/Nik08)) <!-- 0.3.46 -->
- CHEF-1763: Extend TUI Engine to display formatted messages [#78](https://github.com/chef/chef-licensing/pull/78) ([ahasunos](https://github.com/ahasunos)) <!-- 0.3.45 -->
- Added missing credentials error for required API credentials [#73](https://github.com/chef/chef-licensing/pull/73) ([Nik08](https://github.com/Nik08)) <!-- 0.3.44 -->
- Rename existing license generation methods and APIs to specify trial licenses [#75](https://github.com/chef/chef-licensing/pull/75) ([ahasunos](https://github.com/ahasunos)) <!-- 0.3.43 -->
- Fix for  Invalid argument @ dir_s_mkdir on Windows [#77](https://github.com/chef/chef-licensing/pull/77) ([Vasu1105](https://github.com/Vasu1105)) <!-- 0.3.42 -->
- CHEF-57: Create Free Generate License API EndPoint Support [#74](https://github.com/chef/chef-licensing/pull/74) ([ahasunos](https://github.com/ahasunos)) <!-- 0.3.41 -->
- Minor refactoring and code style changes [#72](https://github.com/chef/chef-licensing/pull/72) ([ahasunos](https://github.com/ahasunos)) <!-- 0.3.40 -->
- CHEF-1496: Fix Windows chef-licensing verify CI test timeout [#71](https://github.com/chef/chef-licensing/pull/71) ([ahasunos](https://github.com/ahasunos)) <!-- 0.3.39 -->
- CHEF-62 No hard expiry for licenses only nagging [#64](https://github.com/chef/chef-licensing/pull/64) ([Nik08](https://github.com/Nik08)) <!-- 0.3.38 -->
- Update path to version file in chef-licensing [#70](https://github.com/chef/chef-licensing/pull/70) ([Nik08](https://github.com/Nik08)) <!-- 0.3.37 -->
- CHEF-59: Verify license entry TUI matches Feb 2023 UX diagrams [#61](https://github.com/chef/chef-licensing/pull/61) ([ahasunos](https://github.com/ahasunos)) <!-- 0.3.36 -->
- Extra info of license type in expiry flow [#63](https://github.com/chef/chef-licensing/pull/63) ([Nik08](https://github.com/Nik08)) <!-- 0.3.35 -->
- CHEF-54: Accept Serial Number license format as well as GUID [#65](https://github.com/chef/chef-licensing/pull/65) ([ahasunos](https://github.com/ahasunos)) <!-- 0.3.34 -->
- CHEF-56 License add TUI endpoint introduced [#62](https://github.com/chef/chef-licensing/pull/62) ([Nik08](https://github.com/Nik08)) <!-- 0.3.33 -->
- Fix filespec in gemspec and rename gem to have dashes [#66](https://github.com/chef/chef-licensing/pull/66) ([clintoncwolfe](https://github.com/clintoncwolfe)) <!-- 0.3.32 -->
- CFINSPEC-599 API Caching Integration [#58](https://github.com/chef/chef-licensing/pull/58) ([Nik08](https://github.com/Nik08)) <!-- 0.3.31 -->
- CFINSPEC-602: Update Chef Licensing Documentation - README [#60](https://github.com/chef/chef-licensing/pull/60) ([ahasunos](https://github.com/ahasunos)) <!-- 0.3.30 -->
- CFINSPEC-476: Licensing - Argument fetcher does not take arguments without = [#59](https://github.com/chef/chef-licensing/pull/59) ([ahasunos](https://github.com/ahasunos)) <!-- 0.3.29 -->
- CFINSPEC-581: Change config class to block style in Chef Licensing [#54](https://github.com/chef/chef-licensing/pull/54) ([ahasunos](https://github.com/ahasunos)) <!-- 0.3.28 -->
- CFINSPEC-548 Entitlement checks with Client API call [#52](https://github.com/chef/chef-licensing/pull/52) ([Nik08](https://github.com/Nik08)) <!-- 0.3.27 -->
- CFINSPEC-503 License Expiry Flow [#50](https://github.com/chef/chef-licensing/pull/50) ([Nik08](https://github.com/Nik08)) <!-- 0.3.26 -->
- CFINSPEC-559 License key Validation for argument and environment licenses [#51](https://github.com/chef/chef-licensing/pull/51) ([Nik08](https://github.com/Nik08)) <!-- 0.3.25 -->
- CFINSPEC-505: Command to list licenses [#48](https://github.com/chef/chef-licensing/pull/48) ([ahasunos](https://github.com/ahasunos)) <!-- 0.3.24 -->
- CFINSPEC-539 Client API integration [#46](https://github.com/chef/chef-licensing/pull/46) ([Nik08](https://github.com/Nik08)) <!-- 0.3.23 -->
- CFINSPEC-512 Describe API implementation [#47](https://github.com/chef/chef-licensing/pull/47) ([Nik08](https://github.com/Nik08)) <!-- 0.3.22 -->
- CFINSPEC-511 Added license data model object [#44](https://github.com/chef/chef-licensing/pull/44) ([Nik08](https://github.com/Nik08)) <!-- 0.3.21 -->
- Clean-up use of old configs in the project [#45](https://github.com/chef/chef-licensing/pull/45) ([ahasunos](https://github.com/ahasunos)) <!-- 0.3.20 -->
- CFINSPEC-508 Handle case in which disk to write the license file is not writable. [#42](https://github.com/chef/chef-licensing/pull/42) ([Vasu1105](https://github.com/Vasu1105)) <!-- 0.3.19 -->
- Added version in license validate api call [#43](https://github.com/chef/chef-licensing/pull/43) ([Nik08](https://github.com/Nik08)) <!-- 0.3.18 -->
- CFINSPEC-482: Config and Logging [#33](https://github.com/chef/chef-licensing/pull/33) ([ahasunos](https://github.com/ahasunos)) <!-- 0.3.17 -->
- CFINSPEC-507: Raise exception when no interaction file is provided to TUI Engine [#39](https://github.com/chef/chef-licensing/pull/39) ([ahasunos](https://github.com/ahasunos)) <!-- 0.3.16 -->
- Update failing test on main [#40](https://github.com/chef/chef-licensing/pull/40) ([ahasunos](https://github.com/ahasunos)) <!-- 0.3.15 -->
- delegate error message from API [#36](https://github.com/chef/chef-licensing/pull/36) ([sathish-progress](https://github.com/sathish-progress)) <!-- 0.3.14 -->
- CFINSPEC-494: Implement versioning in interaction file of TUI Engine [#35](https://github.com/chef/chef-licensing/pull/35) ([ahasunos](https://github.com/ahasunos)) <!-- 0.3.13 -->
- CFINSPEC-443 Generation TUI Flow V1 [#30](https://github.com/chef/chef-licensing/pull/30) ([Nik08](https://github.com/Nik08)) <!-- 0.3.12 -->
- CFINSPEC-496: Extend tui_prompt with timeout_select functionality [#37](https://github.com/chef/chef-licensing/pull/37) ([ahasunos](https://github.com/ahasunos)) <!-- 0.3.11 -->
- CFINSPEC-484: Extend support for ERB templating in TUI Engine [#28](https://github.com/chef/chef-licensing/pull/28) ([ahasunos](https://github.com/ahasunos)) <!-- 0.3.10 -->
- CFINSPEC-492: Improve TUI Engine [#32](https://github.com/chef/chef-licensing/pull/32) ([ahasunos](https://github.com/ahasunos)) <!-- 0.3.9 -->
- CFINSPEC-490 authenticate requests [#31](https://github.com/chef/chef-licensing/pull/31) ([sathish-progress](https://github.com/sathish-progress)) <!-- 0.3.8 -->
- CFINSPEC-483: Handle timeout at first prompt of Chef Licensing [#25](https://github.com/chef/chef-licensing/pull/25) ([ahasunos](https://github.com/ahasunos)) <!-- 0.3.7 -->
- Fix: Require appropriate class to be able to raise error [#29](https://github.com/chef/chef-licensing/pull/29) ([ahasunos](https://github.com/ahasunos)) <!-- 0.3.6 -->
- Creates Namespace for API calls [#26](https://github.com/chef/chef-licensing/pull/26) ([Vasu1105](https://github.com/Vasu1105)) <!-- 0.3.5 -->
- Updates the version pinning for faraday gem [#24](https://github.com/chef/chef-licensing/pull/24) ([Vasu1105](https://github.com/Vasu1105)) <!-- 0.3.4 -->
- Few changes and fixes in license key fetcher [#16](https://github.com/chef/chef-licensing/pull/16) ([Nik08](https://github.com/Nik08)) <!-- 0.3.3 -->
- Clean up in TUI Engine [#23](https://github.com/chef/chef-licensing/pull/23) ([ahasunos](https://github.com/ahasunos)) <!-- 0.3.2 -->
- Add named params for feature entitlement check. [#22](https://github.com/chef/chef-licensing/pull/22) ([Vasu1105](https://github.com/Vasu1105)) <!-- 0.3.1 -->
- CFINSPEC-463: TUI Engine Implementation [#13](https://github.com/chef/chef-licensing/pull/13) ([ahasunos](https://github.com/ahasunos)) <!-- 0.3.0 -->
- Few Readme fixes [#21](https://github.com/chef/chef-licensing/pull/21) ([Vasu1105](https://github.com/Vasu1105)) <!-- 0.2.5 -->
- CFINSPEC-24 Software/Product entitlement check. [#19](https://github.com/chef/chef-licensing/pull/19) ([Vasu1105](https://github.com/Vasu1105)) <!-- 0.2.4 -->
- Feature/cfinspec 474 features validation [#14](https://github.com/chef/chef-licensing/pull/14) ([sathish-progress](https://github.com/sathish-progress)) <!-- 0.2.3 -->
- AirGap Updates [#17](https://github.com/chef/chef-licensing/pull/17) ([clintoncwolfe](https://github.com/clintoncwolfe)) <!-- 0.2.2 -->
- Methodize License Server Setting, rename to CHEF_LICENSE_SERVER [#18](https://github.com/chef/chef-licensing/pull/18) ([clintoncwolfe](https://github.com/clintoncwolfe)) <!-- 0.2.1 -->
- CFINSPEC-459: Implement AIR_GAP functionality [#7](https://github.com/chef/chef-licensing/pull/7) ([ahasunos](https://github.com/ahasunos)) <!-- 0.2.0 -->
- CFINSPEC-468 Handle multiple licenses [#15](https://github.com/chef/chef-licensing/pull/15) ([Nik08](https://github.com/Nik08)) <!-- 0.1.7 -->
- fix style [#12](https://github.com/chef/chef-licensing/pull/12) ([sathish-progress](https://github.com/sathish-progress)) <!-- 0.1.6 -->
- License validation generation [#9](https://github.com/chef/chef-licensing/pull/9) ([sathish-progress](https://github.com/sathish-progress)) <!-- 0.1.5 -->
- CFINSPEC-433 File fetcher test specs and license file version support [#8](https://github.com/chef/chef-licensing/pull/8) ([Nik08](https://github.com/Nik08)) <!-- 0.1.4 -->
- CFINSPEC-432 ENV and ARGV fetcher tests [#11](https://github.com/chef/chef-licensing/pull/11) ([Nik08](https://github.com/Nik08)) <!-- 0.1.3 -->
- CFINSPEC-445 - Entry TUI for licensing [#5](https://github.com/chef/chef-licensing/pull/5) ([ahasunos](https://github.com/ahasunos)) <!-- 0.1.2 -->
- Few chefstyle fixes [#6](https://github.com/chef/chef-licensing/pull/6) ([Vasu1105](https://github.com/Vasu1105)) <!-- 0.1.1 -->
<!-- release_rollup -->

<!-- latest_stable_release -->
<!-- latest_stable_release -->