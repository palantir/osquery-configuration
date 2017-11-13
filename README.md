# Palantir osquery Configuration

## About This Repository
This repository is the companion to the [osquery Across the Enterprise](https://link.tbd) blog post.

The goal of this project is to provide a baseline template for any organization considering a deployment of osquery in a production environment. It is
our belief that queries which are likely to have a high level of utility for a large percentage of users should be committed directly to the osquery project, which is
exactly what we have done with our unwanted-chrome-extensions query pack and additions to the windows-attacks pack. However, we have included additional query packs
that are more tailored to our specific environment that may be useful to some or at least serve as a reference to other organizations. osquery operates best when
operators have carefully considered the datasets to be collected and the potential use-cases for that data.

**Note**: This repository contains copies of packs that are maintained in the official osquery project to save users time from having to download packs from two different locations:
* [ossec-rootkit.conf](https://github.com/facebook/osquery/blob/master/packs/ossec-rootkit.conf)
* [osx-attacks.conf](https://github.com/facebook/osquery/blob/master/packs/osx-attacks.conf)
* [unwanted-chrome-extensions.conf](https://github.com/facebook/osquery/blob/master/packs/unwanted-chrome-extensions.conf)
* [windows-attacks.conf](https://github.com/facebook/osquery/blob/master/packs/windows-attacks.conf)

These packs may not be kept up to date in this repository, so please be sure to download them from the official osquery repository if you desire the most up to date pack content.

## Repository Layout
This repository is organized as follows:
* [**Endpoints**](./Endpoints/): The contents of this folder are tailored towards monitoring MacOS and Windows endpoints that are not expected to be online at all times. You may notice the interval of many queries in this folder set to 28800. We purposely set the interval to this value because the interval timer only moves forward when a host is online and we would only expect an endpoint to be online for about 8 hours, or 28800 seconds, per day.
* [**Servers**](./Servers/): The contents of this folder are tailored towards monitoring Linux servers. This configuration has process and network auditing enabled, so expect an exponentially higher volume of logs to be returned from the agent.


## Using This Repository
**Note**: We recommend that you spin up a lab environment before deploying any of these configurations to a production
environment.

**Endpoints Configuration Overview**
* The configurations in this folder are meant for MacOS and Windows and the interval timings assume that these hosts are only online for ~8 hours per day
* The flags included in this configuration enable TLS client mode in osquery and assume it will be connected to a TLS server. We have also included non-TLS flagfiles for local testing.
* File integrity monitoring on MacOS is enabled for specific files and directories defined in [osquery.conf](./Endpoints/MacOS/osquery.conf)
* Events are disabled on Windows via the `--disable_events` flag in [osquery.flags](./Endpoints/Windows/osquery.flags). We use [Windows Event Forwarding](https://github.com/palantir/windows-event-forwarding) and don't have a need for osquery to process Windows event logs.
* These configuration files utilize packs within the [packs](./Endpoints/packs) folder and may generate errors if started without them

**Servers Configuration Overview**
* This configuration assumes the destination operating system is Linux-based and that the hosts are online at all times
* Auditing mode is enabled for processes and network events. Ensure auditd is disabled or removed from the system where this will be running as it may conflict with osqueryd.
* File integrity monitoring is enabled for specific files and directories defined in [osquery.conf](./Servers/Linux/osquery.conf)
* Requires the [ossec-rootkit.conf](./Servers/Linux/packs/ossec-rootkit.conf) pack found to be located at `/etc/osquery/packs/ossec-rootkit.conf`
* The subscriber for `user_events` is disabled

**Quickstart**
1. [Install osquery](https://osquery.io/downloads/)
2. Copy the osquery.conf and osquery.flags files from this repository onto the system and match the directory structure shown below
3. Start osquery via `sudo osqueryctl start` on Linux/MacOS or `Start-Process osqueryd` on Windows
4. Logs are located in `/var/log/osquery` (Linux/MacOS) and `c:\ProgramData\osquery\logs` (Windows)

The desired osquery directory structure for Linux, MacOS, and Windows is outlined below:

**Linux**
```
$ git clone https://github.com/palantir/osquery-configuration.git
$ cp -R osquery-configuration/Servers/Linux/* /etc/osquery
$ sudo osqueryctl start

/etc/osquery
├── osquery.conf
├── osquery.db
├── osquery.flags
└── packs
    └── ossec-rootkit.conf

```
**MacOS**
```
$ git clone https://github.com/palantir/osquery-configuration.git
$ cp osquery-configuration/Endpoints/MacOS/* /var/osquery
$ cp osquery-configuration/Endpoints/packs/* /var/osquery/packs
$ mv /var/osquery/osquery_no_tls.flags /var/osquery/osquery.flags   ## Non-TLS server testing
$ sudo osqueryctl start

/var/osquery
├── certs.crt [if using TLS endpoint]
├── osquery.conf
├── osquery.db
├── osquery.flags
└── packs
    ├── performance-metrics.conf
    ├── security-tooling-checks.conf
    ├── unwanted-chrome-extensions.conf
    └── osx-attacks.conf
```

**Windows**
```
PS> git clone https://github.com/palantir/osquery-configuration.git
PS> copy-item osquery-configuration/Endpoints/Windows/* c:\ProgramData\osquery
PS> copy-item osquery-configuration/Endpoints/packs/* c:\ProgramData\osquery\packs
PS> copy-item c:\ProgramData\osquery\osquery_no_tls.flags c:\ProgramData\osquery\osquery.flags -force   ## Non-TLS server testing
PS> start-service osqueryd

c:\ProgramData\osquery
├── certs.crt [if using TLS endpoint]
├── log
├── osquery.conf
├── osquery.db
├── osquery.flags
├── osqueryi.exe
├─── osqueryd
|    └── osqueryd.exe
└── packs
    ├── performance-metrics.conf
    ├── security-tooling-checks.conf
    ├── unwanted-chrome-extensions.conf
    ├── windows-application-security.conf
    ├── windows-compliance.conf
    ├── windows-registry-monitoring.conf
    └── windows-attacks.conf
```

## Contributing
Contributions, fixes, and improvements can be submitted directly against this project as a GitHub issue or pull request.

## License
MIT License

Copyright (c) 2017 Palantir Technologies Inc.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
