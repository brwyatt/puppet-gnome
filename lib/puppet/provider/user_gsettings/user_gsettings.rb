Puppet::Type.type(:user_gsettings).provide(:user_gsettings) do
  commands gsettings: '/usr/bin/gsettings'
  commands dbus_launch: '/usr/bin/dbus-launch'
  commands getent: '/usr/bin/getent'
  commands pgrep: '/usr/bin/pgrep'
  commands sudo: '/usr/bin/sudo'
  commands grep: '/bin/grep'

  def self.gsettings_exec(user_name, gsettings_args)
    begin
      # Try and get the running gnome-session process
      pid = pgrep("-u#{user_name}", 'gnome-session').split("\n").compact[0]
    rescue
      # Oops! No gnome-session currently running for this user!
      ENV['DBUS_SESSION_BUS_ADDRESS'] = nil
      cmd = method(:sudo)
      args = ['-u', user_name, 'dbus-launch', 'gsettings']
    else
      # We have a valid gnome-session! Lets hijack the dbus session!
      dbus_session = grep('-zE', '^DBUS_SESSION_BUS_ADDRESS=', "/proc/#{pid}/environ").split("\u{0}").compact[0].split('=')[1..-1].join('=')
      ENV['DBUS_SESSION_BUS_ADDRESS'] = dbus_session
      cmd = method(:gsettings)
      args = []
    end

    args.concat(gsettings_args)

    cmd.call(args)
  end

  def self.instances
    users = getent(['passwd']).encode('UTF-8', 'binary', invalid: :replace, undef: :replace, replace: '')

    settings = []

    users.split("\n").map do |user|
      user_properties = user.to_s.split(':')
      user_name = user_properties[0]
      user_id = user_properties[2].to_i
      if user_id >= 1000 and user_id != 65534 then

        gsettings_exec(user_name, ['list-recursively']).split("\n").each do |line|
          next if line == 'No protocol specified'
          parts = line.split(' ')
          schema = parts[0]
          key = parts[1]
          value = (parts[2..-1] || []).join(' ')
          settings << new(
            name: "#{user_name} - #{schema} #{key}",
            ensure: :present,
            schema: schema,
            key: key,
            value: value,
            user: user_name,
          )
        end
      end
    end

    settings.compact
  end

  def self.prefetch(resources)
    settings = instances
    resources.each_key do |name|
      provider = settings.find { |setting|
        setting.schema == resources[name].schema and
          setting.key == resources[name].key and
          setting.user == resources[name].user
      }
      resources[name].provider = provider if provider
    end
  end

  def create
  end

  def destroy
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  mk_resource_methods
end

# vim: ts=2 sts=2 sw=2 expandtab
