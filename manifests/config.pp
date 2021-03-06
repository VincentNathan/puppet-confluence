# == Class: confluence
#
# Install confluence, See README.md for more.
#
class confluence::config(
  $tomcat_port          = $confluence::tomcat_port,
  $tomcat_max_threads   = $confluence::tomcat_max_threads,
  $tomcat_accept_count  = $confluence::tomcat_accept_count,
  $tomcat_proxy         = $confluence::tomcat_proxy,
  $tomcat_extras        = $confluence::tomcat_extras,
  $tomcat_jdbc_settings = $confluence::tomcat_jdbc_settings,
  $manage_server_xml    = $confluence::manage_server_xml,
  $context_path         = $confluence::context_path,
  $ajp                  = $confluence::ajp,
) {

  File {
    owner => $confluence::user,
    group => $confluence::group,
  }

  file {"${confluence::webappdir}/bin/setenv.sh":
    ensure  => present,
    content => template('confluence/setenv.sh.erb'),
    mode    => '0755',
  }
  ~> file { "${confluence::webappdir}/confluence/WEB-INF/classes/confluence-init.properties":
    content => template('confluence/confluence-init.properties.erb'),
    mode    => '0755',
    require => Class['confluence::install'],
    notify  => Class['confluence::service'],
  }

  if ! empty($tomcat_jdbc_settings) {
    $_jdbc = suffix(prefix(join_keys_to_values($tomcat_jdbc_settings, " '"), "set ${jdbc_path}/"), "'")
    $_jdbc_name = $tomcat_jdbc_settings['name']
    $_jdbc_auth = $tomcat_jdbc_settings['auth']
    $_jdbc_type = $tomcat_jdbc_settings['type']
  }
  else {
    $_jdbc = undef
    $_jdbc_name = undef
    $_jdbc_auth = undef
    $_jdbc_type = undef
  }

  if $manage_server_xml == 'augeas' {
    $_tomcat_max_threads  = { maxThreads  => $tomcat_max_threads }
    $_tomcat_accept_count = { acceptCount => $tomcat_accept_count }
    $_tomcat_port         = { port        => $tomcat_port }

    $parameters = merge($_tomcat_max_threads, $_tomcat_accept_count, $tomcat_proxy, $tomcat_extras, $_tomcat_port )

    if versioncmp($::augeasversion, '1.0.0') < 0 {
      fail('This module requires Augeas >= 1.0.0')
    }

    $path = "Server/Service[#attribute/name='Tomcat-Standalone']"

    if ! empty($parameters) {
      $_parameters = suffix(prefix(join_keys_to_values($parameters, " '"), "set ${path}/Connector/#attribute/"), "'")
    } else {
      $_parameters = undef
    }

    ###
    # configure external tomcat datasource. See, for example:
    # https://confluence.atlassian.com/doc/configuring-a-mysql-datasource-in-apache-tomcat-1867.html
    ###
    # Step 3. Configure Tomcat: Set the JDBC Resource for external database.

    $jdbc_path = "${path}/Engine/Host/Context[#attribute/path='${context_path}']/Resource/#attribute"

    $_context_path_changes = "set ${path}/Engine/Host/Context/#attribute/path '${context_path}'"

    $changes = delete_undef_values([$_parameters, $_context_path_changes, $_jdbc])

    if ! empty($changes) {
      augeas { "${confluence::webappdir}/conf/server.xml":
        lens    => 'Xml.lns',
        incl    => "${confluence::webappdir}/conf/server.xml",
        changes => $changes,
      }
    }

    # Step 4. Configure the Confluence web application

    # (this broken indentation is required to pass rake test)
    $conf_changes = [
  'set web-app/resource-ref/description/#text "Connection Pool"',
  "set web-app/resource-ref/res-ref-name/#text \"${_jdbc_name}\"",
  "set web-app/resource-ref/res-type/#text \"${_jdbc_type}\"",
  "set web-app/resource-ref/res-auth/#text \"${_jdbc_auth}\"",
  ]
    # Make sure the necessary <resource-ref> is added to web.xml
    augeas {"${confluence::webappdir}/confluence/WEB-INF/web.xml":
      lens    => 'Xml.lns',
      incl    => "${confluence::webappdir}/confluence/WEB-INF/web.xml",
      changes => $conf_changes,
    }

  } elsif $manage_server_xml == 'template' {

    file { "${confluence::webappdir}/conf/server.xml":
      content => template('confluence/server.xml.erb'),
      mode    => '0600',
      require => Class['confluence::install'],
      notify  => Class['confluence::service'],
    }

    # web.xml can only be configured with augeas. This is tested for in init.pp.
  }
  # if JDBC was configured along with the license key and server_id, skip some server setup steps.
  if ! empty($confluence::tomcat_jdbc_settings) and $confluence::license and $confluence::server_id {
    file { "${confluence::homedir}/confluence.cfg.xml":
      content => template('confluence/confluence.cfg.xml.erb'),
      mode    => '0600',
      owner   => 'confluence',
      group   => 'confluence',
      require => Class['confluence::install'],
      notify  => Class['confluence::service'],
    }
  }
}
