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
  $workspace    = "\$HOME/.go",
  $download_dir = "/tmp",
  $download_url = undef,
  $go_binaries = '',
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
    path => "${::boxen_home}/go/bin:/usr/local/bin:/usr/bin:/bin",
  }

  if ! defined(Package['curl']) {
    package { 'curl': }
  }

  if ! defined(Package['mercurial']) {
    package { 'mercurial': }
  }

  exec { 'download':
    command => "curl -o ${download_dir}/go-${version}.tar.gz ${download_location}",
    environment => ["GOROOT=${::boxen_home}/go"],
    creates => "${download_dir}/go-${version}.tar.gz",
    unless  => "which go && go version | grep ' go${version} '",
    require => Package['curl'],
  } ->
  exec { 'unarchive':
    command => "tar -C ${::boxen_home} -xzf ${download_dir}/go-${version}.tar.gz && rm ${download_dir}/go-${version}.tar.gz",
    onlyif  => "test -f ${download_dir}/go-${version}.tar.gz",
  }

  exec { 'remove-chgo':
    command => "rm -r ${::boxen_home}/chgo;rm -f ${::boxen_home}/env.d/30_go.sh ${::boxen_home}/env.d/99_chgo_auto.sh",
    onlyif  => [
      "test -d ${::boxen_home}/chgo",
    ],
  }

  exec { 'remove-previous':
    command => "rm -rf ${::boxen_home}/go",
    onlyif  => [
      "test -d ${::boxen_home}/go",
      "which go && test `go version | cut -d' ' -f 3` != 'go${version}'",
    ],
    before  => Exec['unarchive'],
  }


  file { "${::boxen_home}/env.d/20-go.sh":
    content => template('golang/golang.sh.erb'),
    mode    => 'a+x',
  }

  file { "${::boxen_home}/bin/goupdate.sh":
    content => template('golang/goupdate.sh.erb'),
    mode    => 'a+x',
    require => File["${::boxen_home}/env.d/20-go.sh"]
  }

  exec { 'update-libs':
    command => "bash -c '. ${::boxen_home}/env.d/20-go.sh && ${::boxen_home}/bin/goupdate.sh'",
    
    onlyif  => [
      "which go",
      "test -f ${::boxen_home}/bin/goupdate.sh",
      "test -f ${::boxen_home}/env.d/20-go.sh",
    ],
    logoutput => true,
    require => File["${::boxen_home}/bin/goupdate.sh"]
  }
}
