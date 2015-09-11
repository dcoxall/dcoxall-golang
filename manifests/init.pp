# == Class: golang
#
# Installs the go language allowing you to
# execute and compile go.
#
# === Examples
#
#  class { "golang":}
#
# === Authors
#
# Darren Coxall <darren@darrencoxall.com>
# Dario Castañé <i@dario.im>
#

class golang (
  $version      = "1.5.1",
  $workspace    = "$HOME/.go",
  $download_dir = "/tmp",
  $download_url = undef,
) {

  $goarch = $::architecture ? {
    'i386'  => '386',
    default => $architecture,
  }

  $goos = downcase($::kernel)

  if ($download_url) {
    $download_location = $download_url
  } else {
    $download_location = "https://storage.googleapis.com/golang/go${version}.${goos}-${goarch}.tar.gz"
  }

  Exec {
    path => "$BOXEN_HOME/go/bin:/usr/local/bin:/usr/bin:/bin",
  }

  if ! defined(Package['curl']) {
    package { 'curl': }
  }

  if ! defined(Package['mercurial']) {
    package { 'mercurial': }
  }

  exec { 'download':
    command => "curl -o ${download_dir}/go-${version}.tar.gz ${download_location}",
    creates => "${download_dir}/go-${version}.tar.gz",
    unless  => "which go && go version | grep ' go${version} '",
    require => Package['curl'],
  } ->
  exec { 'unarchive':
    command => "tar -C $BOXEN_HOME -xzf ${download_dir}/go-${version}.tar.gz && rm ${download_dir}/go-${version}.tar.gz",
    onlyif  => "test -f ${download_dir}/go-${version}.tar.gz",
  }

  exec { 'remove-chgo':
    command => "rm -r $BOXEN_HOME/chgo;rm -f $BOXEN_HOME/env.d/30_go.sh $BOXEN_HOME/env.d/99_chgo_auto.sh",
    onlyif  => [
      "test -d $BOXEN_HOME/chgo",
    ],
  }

  exec { 'remove-previous':
    command => 'rm -r $BOXEN_HOME/go',
    onlyif  => [
      "test -d $BOXEN_HOME/go",
      "which go && test `go version | cut -d' ' -f 3` != ' go${version} '",
    ],
    before  => Exec['unarchive'],
  }

  file { "$BOXEN_HOME/env.d/20-go.sh":
    content => template('golang/golang.sh.erb'),
    mode    => 'a+x',
  }

}
