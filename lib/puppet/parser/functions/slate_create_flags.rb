require 'shellwords'
#
# slate_create_flags.rb
#
module Puppet::Parser::Functions
  # Transforms a hash into a string of slate create flags
  newfunction(:slate_create_flags, :type => :rvalue) do |args|
    opts = args[0] || {}
    flags = []
    flags << "--no-ingress" if opts['no_ingress']
    flags << "--group '#{opts['group']}'" if opts['group'] != 'undef'
    flags << "--org '#{opts['org']}'" if opts['org'] != 'undef'
    flags << "-y" if opts['confirm']

    flags.flatten.join(' ')
  end
end
