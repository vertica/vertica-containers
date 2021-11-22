#!/usr/bin/env python3

"""
Parse the vertica version number out of the name of an RPM or .deb
file 
"""

# Vertica .deb files have names like:
#
#       vertica_10.1.1-5_amd64.deb
#
# and Vertica .rpm files have names like:
#
#       vertica-10.1.1-5.x86_64.RHEL6.rpm
#       vertica-10.1.1-5.x86_64.SUSE.rpm
#
# for the daily, the hotfix number is a date:
#
#       vertica-11.0.0-20210723.x86_64.RHEL6.rpm
#       vertica_11.0.0-20210723_amd64.deb
#
# one can also encounter these:       
#
#       vertica-x86_64.RHEL6.latest.rpm
#       vertica.latest.deb
#
# which... we can't say very much about
#
# This program extracts the version number (here, 10.1.1-5) from the
# filename

from collections import namedtuple
import os.path
import argparse
import re
import sys

Release_File = namedtuple('Release_File', ['version', 'arch',
                                           'os_type', 'file_type'])

def extract_parts_from_filename(fname: str) -> Release_File:
    fname = os.path.basename(fname)
    rpm_pat = re.compile('^vertica-(.*)\.(_amd64|x86_64)\.(RHEL6|SUSE)\.rpm$')
    deb_pat = re.compile('^vertica_(.*)_(amd64|x86_64)\.deb$')
    latest_pat = re.compile('.*latest.*')
    if(not fname.startswith('vertica')):
        raise ValueError(f'filename {fname} does not begin with "vertica"')
    retval = None
    m = latest_pat.match(fname)
    if m:
        if fname.endswith('rpm'):
            return Release_File(version = 'latest',
                                arch = 'x86_64',
                                os_type = 'centos',
                                file_type = 'rpm')
        elif fname.endswith('deb'):
            return Release_File(version = 'latest',
                                arch = 'unknown',
                                os_type = 'debian',
                                file_type = 'deb')
    m = rpm_pat.match(fname)
    if m:
        os_type = m.group(3)
        if os_type == 'RHEL6': os_type = 'centos'
        return Release_File(version = m.group(1),
                            arch = m.group(2),
                            os_type = os_type,
                            file_type = 'rpm')
    m = deb_pat.match(fname)
    if m:
        return Release_File(version = m.group(1),
                            arch = m.group(2),
                            os_type = 'debian',
                            file_type = 'deb')
    raise ValueError(f'file name {fname} is neither RPM nor .deb')

def test_extract_parts_from_filename() -> None:
    Tval = namedtuple('TVal', ['test_input', 'result'])
#       vertica_10.1.1-5_amd64.deb
#       vertica_11.0.0-20210723_amd64.deb
    tests = [Tval('vertica_10.1.1-5_amd64.deb',
                  Release_File(version = '10.1.1-5',
                               arch = 'amd64',
                               os_type = 'debian',
                               file_type = 'deb')),
             Tval('vertica_11.0.0-20210723_amd64.deb',
                  Release_File(version = '11.0.0-20210723',
                               arch = 'amd64',
                               os_type = 'debian',
                               file_type = 'deb')),

#       vertica-10.1.1-5.x86_64.RHEL6.rpm
#       vertica-10.1.1-5.x86_64.SUSE.rpm

             Tval('vertica-10.1.1-5.x86_64.RHEL6.rpm',
                  Release_File(version = '10.1.1-5',
                               arch = 'x86_64',
                               os_type = 'centos',
                               file_type = 'rpm')),
             Tval('vertica-10.1.1-5.x86_64.SUSE.rpm',
                  Release_File(version = '10.1.1-5',
                               arch = 'x86_64',
                               os_type = 'SUSE',
                               file_type = 'rpm')),
#       vertica-11.0.0-20210723.x86_64.RHEL6.rpm
             Tval('vertica-11.0.0-20210723.x86_64.RHEL6.rpm',
                  Release_File(version = '11.0.0-20210723',
                               arch = 'x86_64',
                               os_type = 'centos',
                               file_type = 'rpm')),
#       vertica-x86_64.RHEL6.latest.rpm
             Tval('vertica-x86_64.RHEL6.latest.rpm',
                  Release_File(version = 'latest',
                               arch = 'x86_64',
                               os_type = 'centos',
                               file_type = 'rpm')),
#       vertica.latest.deb
             Tval('vertica.latest.deb',
                  Release_File(version = 'latest',
                               arch = 'unknown',
                               os_type = 'debian',
                               file_type = 'deb'))
             ]

    errors = 0
    for test in tests:
        result = extract_parts_from_filename(test.test_input)
        if result != test.result:
            print(f'***** ERROR ****: {test.test_input} result was {result}')
            print(f'                                    instead of {test.result}')
            errors += 1
        else:
            print(f'{test.test_input} result was {result}')
    if errors != 0:
        print('There were errors');
        return -1
    print ('No errors')
    return 1

def argparse_setup() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description='Extract information from vertica distro filename'
    )
    parser.add_argument('-a',
                        dest='print_architecture',
                        nargs=1,
                        type=str,
                        default=None,
                        help='Print architecture software intended for')
    parser.add_argument('-f',
                        dest='print_file_type',
                        nargs=1,
                        type=str,
                        default=None,
                        help='Print file type')
    parser.add_argument('-o',
                        dest='print_os',
                        nargs=1,
                        type=str,
                        default=None,
                        help='Print operating system software intended for')
    parser.add_argument('-v',
                        dest='print_version',
                        nargs=1,
                        type=str,
                        default=None,
                        help='Print Vertica version')


    parser.add_argument('-t',
                        dest='run_test',
                        action='store_true',
                        default=False,
                        help='Run tests')
    return parser

def main() -> int:
    argparser = argparse_setup()
    args = argparser.parse_args()
    if args.run_test:
        return test_extract_parts_from_filename()
    elif args.print_architecture:
        parts = extract_parts_from_filename(args.print_architecture[0])
        print(f'{parts.arch}')
        return 0
    elif args.print_file_type:
        parts = extract_parts_from_filename(args.print_file_type[0])
        print(f'{parts.file_type}')
        return 0
    elif args.print_os:
        parts = extract_parts_from_filename(args.print_os[0])
        print(f'{parts.os_type}')
        return 0
    elif args.print_version:
        parts = extract_parts_from_filename(args.print_version[0])
        print(f'{parts.version}')
        return 0

if __name__ == '__main__':
    sys.exit(main())



