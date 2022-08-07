#!/usr/bin/perl
# SPDX-FileCopyrightText: PhiBo from DinoTools (2022)
# SPDX-License-Identifier: GPL-3.0-or-later

use strict;
use warnings FATAL => 'all';

use Pod::Text::Termcap;
use Data::Dumper;

use Net::SNMP;

use constant OK         => 0;
use constant WARNING    => 1;
use constant CRITICAL   => 2;
use constant UNKNOWN    => 3;

my $pkg_monitoring_available = 0;
BEGIN {
    my $pkg_nagios_available = 0;
    eval {
        require Monitoring::Plugin;
        require Monitoring::Plugin::Functions;
        require Monitoring::Plugin::Threshold;
        $pkg_monitoring_available = 1;
    };
    if (!$pkg_monitoring_available) {
        eval {
            require Nagios::Plugin;
            require Nagios::Plugin::Functions;
            require Nagios::Plugin::Threshold;
            *Monitoring::Plugin:: = *Nagios::Plugin::;
            $pkg_nagios_available = 1;
        };
    }
    if (!$pkg_monitoring_available && !$pkg_nagios_available) {
        print("UNKNOWN - Unable to find module Monitoring::Plugin or Nagios::Plugin\n");
        exit UNKNOWN;
    }
}

my @g_long_message;
my $parser = Pod::Text::Termcap->new (sentence => 0, width => 78);
my $extra_doc = <<'END_MESSAGE';
END_MESSAGE

my $extra_doc_output;
$parser->output_string(\$extra_doc_output);
$parser->parse_string_document($extra_doc);

my $mp = Monitoring::Plugin->new(
    shortname => "MBG Lantime NTP",
    usage => "",
    extra => $extra_doc_output
);

$mp->add_arg(
    spec    => 'community|C=s',
    help    => 'Community string (Default: public)',
    default => 'public'
);

$mp->add_arg(
    spec     => 'hostname|H=s',
    help     => '',
    required => 1
);

$mp->add_arg(
    spec    => 'stratum-warning=s',
    help    => '',
    default => '',
);

$mp->add_arg(
    spec    => 'stratum-critical=s',
    help    => '',
    default => '',
);

$mp->add_arg(
    spec    => 'refclock-offset-warning=s',
    help    => '',
    default => '',
);

$mp->add_arg(
    spec    => 'refclock-offset-critical=s',
    help    => '',
    default => '',
);

$mp->getopts;

#Open SNMP Session
my ($session, $error) = Net::SNMP->session(
    -hostname => $mp->opts->hostname,
    -version => 'snmpv2c',
    -community => $mp->opts->community,
);

if (!defined($session)) {
    wrap_exit(UNKNOWN, $error)
}

check();

my ($code, $message) = $mp->check_messages();
wrap_exit($code, $message . "\n" . join("\n", @g_long_message));

sub check
{
    my $mbg_base_oid = '1.3.6.1.4.1.5597.30.0.2';
    my $mbgLtNgNtpCurrentState = $mbg_base_oid . '.1.0';
    my $mbgLtNgNtpStratum = $mbg_base_oid . '.2.0';
    my $mbgLtNgNtpRefclockName = $mbg_base_oid . '.3.0';
    my $mbgLtNgNtpRefclockOffset = $mbg_base_oid . '.4.0';
    my $mbgLtNgNtpVersion = $mbg_base_oid . '.5.0';

    my %ntp_current_state = (
        0 => 'n/a',
        1 => 'notSynchronized',
        2 => 'synchronized',
    );

    my $result = $session->get_request(
        -varbindlist => [
            $mbgLtNgNtpCurrentState,
            $mbgLtNgNtpStratum,
            $mbgLtNgNtpRefclockName,
            $mbgLtNgNtpRefclockOffset,
            $mbgLtNgNtpVersion,
        ]
    );

    if(!defined $result) {
        wrap_exit(UNKNOWN, 'Unable to get information');
    }

    my $current_state = $result->{$mbgLtNgNtpCurrentState};

    if ($current_state == 2) {
        $mp->add_message(
            OK,
            'State: ' . $ntp_current_state{$current_state},
        );
    } elsif ($current_state == 1) {
        $mp->add_message(
            CRITICAL,
            'State: ' . $ntp_current_state{$current_state},
        );
    } else {
        $mp->add_message(
            UNKNOWN,
            'State: ' . $ntp_current_state{$current_state},
        );
    }

    my $stratum = $result->{$mbgLtNgNtpStratum};
    my $stratum_threshold = Monitoring::Plugin::Threshold->set_thresholds(
        warning  => $mp->opts->get('stratum-warning'),
        critical => $mp->opts->get('stratum-critical'),
    );

    $mp->add_perfdata(
        label     => 'stratum',
        value     => $stratum,
        threshold => $stratum_threshold,
    );

    $mp->add_message(
        $stratum_threshold->get_status($stratum),
        'Stratum: ' . $stratum,
    );

    my $refclock_offset = $result->{$mbgLtNgNtpRefclockOffset};
    my $refclock_offset_threshold = Monitoring::Plugin::Threshold->set_thresholds(
        warning  => $mp->opts->get('refclock-offset-warning'),
        critical => $mp->opts->get('refclock-offset-critical'),
    );

    $mp->add_perfdata(
        label     => 'refclock-offset',
        value     => $refclock_offset,
        threshold => $refclock_offset_threshold,
        uom       => 'ms',
    );

    $mp->add_message(
        $refclock_offset_threshold->get_status($refclock_offset),
        'Refclock Offset: ' . $refclock_offset . 'ms',
    );

    # $mp->add_message(
    #     OK,
    #     'Refclock Name: ' . $result->{$mbgLtNgNtpRefclockName},
    # );

    # $mp->add_message(
    #     OK,
    #     'NTP Version: ' . $result->{$mbgLtNgNtpVersion},
    # );
}

sub wrap_exit
{
    if($pkg_monitoring_available == 1) {
        $mp->plugin_exit( @_ );
    } else {
        $mp->nagios_exit( @_ );
    }
}
