#
#    Copyright 2015 Mirantis, Inc.
#
#    Licensed under the Apache License, Version 2.0 (the "License"); you may
#    not use this file except in compliance with the License. You may obtain
#    a copy of the License at
#
#         http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
#    WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
#    License for the specific language governing permissions and limitations
#    under the License.
#
class plugin_zabbix::controller {

  include plugin_zabbix::params

  $host = regsubst($plugin_zabbix::params::db_ip,'^(\d+\.\d+\.\d+\.)\d+','\1%')


  file { '/etc/dbconfig-common':
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }

  file { '/etc/dbconfig-common/zabbix-server-mysql.conf':
    ensure  => present,
    require => File['/etc/dbconfig-common'],
    mode    => '0600',
    source  => 'puppet:///modules/plugin_zabbix/zabbix-server-mysql.conf',
  }

  package { $plugin_zabbix::params::server_pkg:
    ensure  => present,
    require => File['/etc/dbconfig-common/zabbix-server-mysql.conf'],
  }

  file { $plugin_zabbix::params::server_config:
    ensure  => present,
    require => Package[$plugin_zabbix::params::server_pkg],
    content => template($plugin_zabbix::params::server_config_template),
  }

  service { 'zabbix-server':
    ensure   => running,
    name     => 'zabbix-server',
    enable   => true,
    require  => Package[$plugin_zabbix::params::server_pkg]
  }

  sysctl::value { 'kernel.shmmax':
    value  => $plugin_zabbix::params::sysctl_kernel_shmmax,
    notify => Service['zabbix-server'],
  }

  plugin_zabbix::db::mysql_db { $plugin_zabbix::params::db_name:
    user     => $plugin_zabbix::params::db_user,
    password => $plugin_zabbix::params::db_password,
    host     => $host,
  }

  Plugin_zabbix::Db::Mysql_db[$plugin_zabbix::params::db_name] -> Package[$plugin_zabbix::params::server_pkg]

  if $plugin_zabbix::params::frontend {
    class { 'plugin_zabbix::frontend':
      require => File[$plugin_zabbix::params::server_config],
    }
  }

  firewall { '998 zabbix agent vip':
    proto  => 'tcp',
    action => 'accept',
    port   => $plugin_zabbix::params::zabbix_ports['agent'],
  }

  firewall { '998 zabbix server vip':
    proto  => 'tcp',
    action => 'accept',
    port   => $plugin_zabbix::params::zabbix_ports['server'],
  }
}
