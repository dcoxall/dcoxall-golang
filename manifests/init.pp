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
    path => "/usr/local/go/bin:/usr/local/bin:/usr/bin:/bin",
  }

  if ! defined(Package['curl']) {
    package { 'curl': }
  }

  if ! defined(Package['mercurial']) {
    package { 'mercurial': }
  }

  exec { 'download':
    command => "curl -o ${download_dir}/go-${version}.tar.gz ${download_location}",
    environment => ["GOROOT=/usr/local/go"],
    creates => "${download_dir}/go-${version}.tar.gz",
    unless  => "which go && go version | grep ' go${version} '",
    require => Package['curl'],
  } ->
  exec { 'unarchive':
    command => "tar -C /usr/local -xzf ${download_dir}/go-${version}.tar.gz && rm ${download_dir}/go-${version}.tar.gz",
    onlyif  => "test -f ${download_dir}/go-${version}.tar.gz",
  }

  exec { 'remove-chgo':
    command => "rm -r /usr/local/chgo;rm -f /etc/profile.d/30_go.sh /etc/profile.d/99_chgo_auto.sh",
    onlyif  => [
      "test -d /usr/local/chgo",
    ],
  }

  exec { 'remove-previous':
    command => "rm -rf /usr/local/go",
    onlyif  => [
      "test -d /usr/local/go",
      "which go && test `go version | cut -d' ' -f 3` != 'go${version}'",
    ],
    before  => Exec['unarchive'],
  }


  file { "/etc/profile.d/20-go.sh":
    content => template('golang/golang.sh.erb'),
    mode    => 'a+x',
  }

  file { "/usr/local/bin/goupdate.sh":
    content => template('golang/goupdate.sh.erb'),
    mode    => 'a+x',
    require => File["/etc/profile.d/20-go.sh"]
  }

  exec { 'update-libs':
    command => "bash -c '. /etc/profile.d/20-go.sh && /usr/local/bin/goupdate.sh'",
    
    onlyif  => [
      "which go",
      "test -f /usr/local/bin/goupdate.sh",
      "test -f /etc/profile.d/20-go.sh",
    ],
    logoutput => true,
    require => File["/usr/local/bin/goupdate.sh"]
  }
}
