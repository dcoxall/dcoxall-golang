# Golang
Quickly and easily install the Go programming language with a customisable workspace and version.

## Usage
In order to use this module do the following:

    class { 'golang':
      version   => '1.1.2',
      workspace => '/usr/local/src/go',
    }

This will install go 1.1.2 and setup your workspace in `/usr/local/go`. If you then want to include a different directory in the workspace you can do the following:

    file { '/home/user/project':
      ensure => link,
      target => '/usr/local/src/go/src/project',
    }

Your project can then be accessed by Go:

    $ go test project

## Contributions
This module is fairly young and has only been tested on Debian. All contributions are welcome by forking the project and creating a pull request with your changes.
