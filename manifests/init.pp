# Poudriere is a tool that lets you build PkgNG packages from ports.  This is
# cool because it gives you the flexibility of custom port options with all the
# awesomeness of packages.  The below class prepares the build environment.
# For the configuration of the build environment, see Class[poudriere::env].

class poudriere (
  $zpool          = 'tank',
  $freebsd_host   = 'http://ftp6.us.freebsd.org/',
  $ccache_enable  = false,
  $ccache_dir     = '/var/cache/ccache',
  $poudriere_data = '/usr/local/poudriere_data', 
  $port_fetch_method = 'svn',
  $build_cron_args = {},
  $update_cron_args = {},
){

  $exec_incl = '/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/bin:/usr/local/sbin'

  Exec {
    path => $exec_incl
  }

  if $port_fetch_method == 'portsnap' {
    fail ( "fetching from portsnap is currently not
    enabled because it cannot be run non interactively")
  }

  # Install poudriere
  # make -C /usr/ports/ports-mgmt/poudriere install clean
  package { 'poudriere':
    ensure => installed,
  }

  file { '/usr/local/etc/poudriere.conf':
    content => template('poudriere/poudriere.conf.erb'),
    require => Package['poudriere'],
  }

  exec { "create default ports tree":
    command => "poudriere ports -c -m $port_fetch_method",
    require => File["/usr/local/etc/poudriere.conf"],
    creates => '/usr/local/poudriere/ports/default/ftp',
    timeout => '3000',
  }

  file { "/usr/local/etc/poudriere.d":
    ensure  => directory,
    require => Exec["create default ports tree"],
  }

  if $ccache_enable {
    file { $ccache_dir:
      ensure => directory,
    }
  }
  
  if is_hash($build_cron_args){
    if $build_cron_args != {}{
      ensure_resource('cron','poudriere_build_run', merge(
        {command => "poudriere cron",environment => "PATH=$exec_incl"},
        $build_cron_args))
    }
  } else {
     fail ("build_cron_args only takes a hash as an argument")
  }

  if is_hash($update_cron_args){
    if $update_cron_args != {}{
      ensure_resource('cron','poudriere_update_run', merge(
        {command => "poudriere ports -u", environment => "PATH=$exec_incl"},
        $update_cron_args))
    }
  } else {
     fail ("update_cron_args only takes a hash as an argument")
  }

  
}
