check_meinberg_lantime_*
========================

A collection of monitoring plugins to check Meinberg Lantime devices with [Icinga](https://icinga.com/), [Nagios](https://www.nagios.org/) and other compatible monitoring solutions.

Compatible devices
------------------

- [Meinberg](https://www.meinbergglobal.com/) Lantime with NG MIB


Requirements
------------

**General**

- Perl 5
- Perl Modules:
    - Monitoring::Plugin or Nagios::Plugin
    - Net::SNMP

**Ubuntu/Debian**

- perl
- libmonitoring-plugin-perl
- libnet-snmp-perl


Commands
--------

### check_meinberg_lantime_hw.pl

Check hardware components like power supplies, fans and temperatures. [Commandline documentation for check_meinberg_lantime_hw.pl](https://dinotools.github.io/monitoring-check_meinberg_lantime/commands/check_meinberg_lantime_hw/)

### check_meinberg_lantime_ntp.pl

Check NTP state. [Commandline documentation for check_meinberg_lantime_ntp.pl](https://dinotools.github.io/monitoring-check_meinberg_lantime/commands/check_meinberg_lantime_ntp/)

Installation
------------

Just copy the files `check_meinberg_lantime_*.pl` to your Icinga or Nagios plugin directory.

Examples
--------


Documentation
-------------

- Documentation: https://dinotools.github.io/monitoring-check_meinberg_lantime

Source
------

- [Latest source at github.com](https://github.com/DinoTools/monitoring-check_meinberg_lantime)

Issues
------

Use the [GitHub issue tracker](https://github.com/DinoTools/monitoring-check_meinberg_lantime/issues) to report any issues

License
-------

GPLv3+
