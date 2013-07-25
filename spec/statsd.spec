Name:           statsd
Version:        0.6.0
Release:        %{ci_build_number}
Summary:        monitoring daemon, that aggregates events received by udp in 10 second intervals
Group:          Applications/Internet
License:        Etsy open source license
URL:            https://github.com/CompendiumSoftware/statsd-rpm
Vendor:         Compendium
Packager:       Stephen Gregory <sgregory@compendium.com>
Source0:        %{name}-%{version}.tar.gz
Source1:	statsd-init.d
Source2:	config.js
BuildRoot:      %{_tmppath}/%{name}-%{version}-%{release}-root
BuildArch:      noarch
Requires:       nodejs,npm

%description
Simple daemon for easy stats aggregation  

%prep
%setup -q

%build

%install
%{__mkdir_p} %{buildroot}/usr/share/statsd/backends %{buildroot}/usr/share/statsd/lib
%{__install} -Dp -m0644 stats.js %{buildroot}/usr/share/statsd
%{__install} -Dp -m0644 lib/config.js lib/logger.js lib/set.js lib/process_metrics.js %{buildroot}/usr/share/statsd/lib
%{__install} -Dp -m0644 backends/{console.js,graphite.js} %{buildroot}/usr/share/statsd/backends/

%{__mkdir_p} %{buildroot}%{_initrddir}
%{__install} -Dp -m0755 %{SOURCE1} %{buildroot}%{_initrddir}/%{name}

%{__mkdir_p} %{buildroot}%{_sysconfdir}/%{name}
%{__install} -Dp -m0644 %{SOURCE2}  %{buildroot}%{_sysconfdir}/%{name}/config.js

%{__mkdir_p} %{buildroot}%{_localstatedir}/lock/subsys
touch %{buildroot}%{_localstatedir}/lock/subsys/%{name}


%pre
getent group %{name} >/dev/null || groupadd -r %{name}
getent passwd %{name} >/dev/null || \
    useradd -r -g %{name} -d %{_localstatedir}/lib/%{name} \
    -s /sbin/nologin -c "%{name} daemon" %{name}
exit 0

%preun
service %{name} stop
exit 0

%postun

if [ $1 = 0 ]; then
	chkconfig --del %{name}
	getent passwd %{name} >/dev/null && \
	userdel -r %{name} 2>/dev/null
fi
exit 0

%post
cd /usr/share/statsd
npm install statsd-instrumental-backend
chkconfig --add %{name}
service %{name} start


%clean
[ "%{buildroot}" != "/" ] && %{__rm} -rf %{buildroot}

%files
%defattr(-,root,root,-)
%doc LICENSE README.md
%doc exampleConfig.js

/usr/share/%{name}/*
%{_initrddir}/%{name}

%config %{_sysconfdir}/%{name}
%ghost %{_localstatedir}/lock/subsys/%{name}

%changelog
* Thu Jul 25 2013 Stephen Gregory <sgregory@compenidum.com> 0.6.0
- customization for compendium
* Sun Jun 10 2012 Rene Cunningham <rene@compounddata.com> 0.3.0-1
- initial build
