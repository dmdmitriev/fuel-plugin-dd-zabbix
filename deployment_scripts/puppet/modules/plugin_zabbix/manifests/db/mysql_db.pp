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
define plugin_zabbix::db::mysql_db (
  $user,
  $password,
  $charset     = 'utf8',
  $host        = 'localhost',
  $user_file   = '/var/run/mysqld/zabbix_user',
  $grant_file  = '/var/run/mysqld/zabbix_grant',
) {

  package { 'mysql-client':
    ensure => present,
    before => Package['mysql-server']
  }

  file { ['/etc/mysql',
          '/etc/mysql/conf.d']:
    ensure => directory,
    before => Package['mysql-server']
  }

  package { 'mysql-server':
    ensure => 'installed',
  }

  service { 'mysql':
    ensure => 'running',
    enable => true,
    require => Package['mysql-server'],
  }

  database { $name:
    ensure    => present,
    charset   => $charset,
    provider  => 'mysql',
    require   => Package['mysql-server'],
  }
  
  exec { 'zabbix_user':
    command => "/usr/bin/mysql mysql -e \"CREATE USER '${user}'@'localhost' IDENTIFIED BY '${password}'\"",
    unless  => "/usr/bin/mysql mysql -e \"SELECT User FROM user WHERE user = '${name}'\"",
  }

  exec { 'zabbix_grant':
    command => "/usr/bin/mysql mysql -e \"GRANT ALL ON ${name}.* TO '${user}'@'localhost'\"",
    unless  => "/usr/bin/mysql mysql -e \"SHOW GRANTS FOR 'zabbix'@'localhost'\" | grep ALL",
  }

  Package['mysql-server'] -> Exec['zabbix_user'] -> Exec['zabbix_grant']

  # exec{ "${name}-import":
  #   command     => "/usr/bin/mysql ${name} < ${sql}",
  #   logoutput   => true,
  #   refreshonly => $refresh,
  #   subscribe   => Database[$name],
  # }

}

