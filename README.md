# Puppet-poudriere

Manage [poudriere](http://fossil.etoilebsd.net/poudriere/doc/trunk/doc/index.wiki), the FreeBSD PkgNG build system with Puppet.


## Ports fetch method
Unfortunetly the default poudriere ports fetch method [portsnap](http://www.freebsd.org/doc/handbook/updating-upgrading-portsnap.html),
can't be used appropriately non-interactively by puppet. This means we have to use one of the other methods:

* csup
* __svn__
* svn+http
* svn+https
* svn+file
* svn+ssh
* git

by default we use svn but can be set by the *port_fetch_method* argument to the class


## Simple Implementation

    poudriere::env { "90amd64":
      makeopts => [
        "WITH_PKGNG=yes",
        "OPTIONS_SET+= SASL",
        "OPTIONS_SET+= TLS",
        "WITH_IPV6=TRUE",
        "WITH_SSL=YES",
      ]
    }

    nginx::vhost { "build.${domain}":
      port      => 80,
      vhostroot => '/usr/local/poudriere_data/packages',
      autoindex => true,
    }

## Automatic Building

As well as setting up the config files, directories and jails you need, this module can schedule
builds of the ports. You can have multiple environments (poudriere::env) which each use puppet's [schedule
resource](http://docs.puppetlabs.com/references/latest/type.html#schedule) to queue a build of
of the environment. The queueing doesn't guarentee build of the port itself. The ports are only built,
once *build_cron_args* has been set on the class. This will create a [cron job](http://docs.puppetlabs.com/references/latest/type.html#cron)
which when executed will build any environments that have been scheduled since the last build.


## Automatic Updating

Right now only the default ports tree is updated. To enable this simply add arguments to *build_cron_args*
in the class.


## More Advanced  Example with Updating and Building

    class {poudriere:
	   zpool => 'jail_tank',
	   poudriere_data => '/jail_tank/poudriere',
	   build_cron_args => { hour => 4, minute 30 } # build at 4:30am
	   update_cron_args => { hour => 4, minute => 0} # fetch new ports at 4:00am
	}
	
    poudriere::env { "83amd64":
      version => '8.3-RELEASE',
      arch => 'amd64',
      jail => '83amd64',
      pkgs => ['lang/php53',
               'lang/php53-extensions',
               'www/apache22',
               'shells/bash',
               ],
      queue_build => 'weekly',
    }

    poudriere::env { "91amd64":
     makeopts => [
                  "WITH_PKGNG=yes",
                  "RUBY_VER=1.9", #use ruby1.9 for FreeBSD 9.1
                  "RUBY_DEFAULT_VER=1.9",
                  ],
     version => '9.1-RELEASE',
     arch => 'amd64',
     jail => '91amd64',
     pkgs => ['ftp/wget',
              'ftp/curl',
              'devel/git',
              'www/apache22',
              'shells/bash',
              'sysutils/facter',
              'sysutils/puppet',
              'ports-mgmt/poudriere',
              'devel/ccache',
              'lang/php53',
              ],
     queue_build => 'daily',
   }

