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
  $download_dir = "/usr/local/src",
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
    path => '/usr/local/go/bin:/usr/local/bin:/usr/bin:/bin',
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
    command => "tar -C /usr/local -xzf ${download_dir}/go-${version}.tar.gz && rm ${download_dir}/go-${version}.tar.gz",
    onlyif  => "test -f ${download_dir}/go-${version}.tar.gz",
  }

  exec { 'remove-previous':
    command => 'rm -r /usr/local/go',
    onlyif  => [
      'test -d /usr/local/go',
      "which go && test `go version | cut -d' ' -f 3` != 'go${version}'",
    ],
    before  => Exec['unarchive'],
  }

  file { '/etc/profile.d/golang.sh':
    content => template('golang/golang.sh.erb'),
    owner   => root,
    group   => root,
    mode    => 'a+x',
  }

}
