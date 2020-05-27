# @summary
#   This class handles installation of the SLATE CLI.
#
# @note This class requires `jq` and `curl` to be installed.
#
# @param endpoint_url
#   The endpoint to use for the SLATE CLI.
#
class slate::cli (
  String $endpoint_url = 'https://api.slateci.io:18080',
) {
  file { '/root/.slate':
    ensure => directory,
  }
  -> file { '/root/.slate/endpoint':
    content => $endpoint_url,
    mode    => '0600',
  }

  -> exec { 'download/update SLATE CLI':
    path        => ['/usr/sbin', '/usr/bin', '/bin', '/sbin', '/usr/local/bin'],
    command     => 'curl -L https://jenkins.slateci.io/artifacts/client/slate-linux.tar.gz | tar -xz -C /usr/local/bin',
    # Do not run if the SLATE binary is present and it's version is equal to the server's reported version.
    unless      => 'test -f /usr/local/bin/slate && \
    test $(slate version | grep -Pzo "Client Version.*\\n\\K(\\d+)(?=.*)") = \
    $(curl -L https://jenkins.slateci.io/artifacts/client/latest.json | \
    jq -r ".[0].version")',
    environment => ['HOME=/root'],
    require     => [
      Package['jq'],
      Package['curl'],
    ],
  }

  ~> exec { 'setup SLATE completions':
    path        => ['/usr/sbin', '/usr/bin', '/bin', '/sbin', '/usr/local/bin'],
    command     => 'slate completion > /etc/bash_completion.d/slate',
    refreshonly => true,
    environment => ['HOME=/root'],
  }
}
