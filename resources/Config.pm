# This is CPAN.pm's systemwide configuration file. This file provides
# defaults for users, and the values can be changed in a per-user
# configuration file. The user-config file is being looked for as
# ~/.cpan/CPAN/MyConfig.pm.

$CPAN::Config = {
  'build_cache' => q[10],
  'build_dir' => q[/export/home/apl/.cpan/build],
  'cache_metadata' => q[1],
  'cpan_home' => q[/export/home/apl/.cpan],
  'ftp' => q[/usr/bin/ftp],
  'ftp_proxy' => q[],
  'getcwd' => q[cwd],
  'gpg' => q[],
  'gzip' => q[/usr/bin/gzip],
  'histfile' => q[/export/home/apl/.cpan/histfile],
  'histsize' => q[100],
  'http_proxy' => q[],
  'inactivity_timeout' => q[0],
  'index_expire' => q[1],
  'inhibit_startup_message' => q[0],
  'keep_source_where' => q[/export/home/apl/.cpan/sources],
  'lynx' => q[],
  'make' => q[/usr/gnu/bin/make],
  'make_arg' => q[],
  'make_install_arg' => q[],
  'makepl_arg' => q[],
  'ncftp' => q[],
  'ncftpget' => q[],
  'no_proxy' => q[],
  'pager' => q[/usr/bin/less],
  'prerequisites_policy' => q[follow],
  'scan_cache' => q[atstart],
  'shell' => q[/usr/bin/bash],
  'tar' => q[/usr/gnu/bin/tar],
  'term_is_latin' => q[1],
  'unzip' => q[],
  'urllist' => [q[ftp://ftp.hosteurope.de/pub/CPAN/]],
  'wget' => q[/usr/bin/wget],
};
1;
__END__
