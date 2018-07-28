Puppet::Type.type(:user_gsettings).provide(:user_gsettings) do
  commands gsettings: '/usr/bin/gsettings'
  commands dbus_launch: '/usr/bin/dbus-launch'
  commands getent: '/usr/bin/getent'
  commands pgrep: '/usr/bin/pgrep'
  commands sudo: '/usr/bin/sudo'
  commands grep: '/bin/grep'

  def initialize(value={})
    super(value)
    @property_flush = {}
  end

  def self.gsettings_exec(user_name, gsettings_args)
    begin
      # Try and get the running gnome-session process
      pid = pgrep("-u#{user_name}", 'gnome-session').split("\n").compact[0]
    rescue
      # Oops! No gnome-session currently running for this user!
      ENV['DBUS_SESSION_BUS_ADDRESS'] = nil
      cmd = method(:sudo)
      args = ['su', user_name, '-c', 'dbus-launch gsettings ']
    else
      # We have a valid gnome-session! Lets hijack the dbus session!
      dbus_session = grep('-zE', '^DBUS_SESSION_BUS_ADDRESS=', "/proc/#{pid}/environ").split("\u{0}").compact[0].split('=')[1..-1].join('=')
      ENV['DBUS_SESSION_BUS_ADDRESS'] = dbus_session
      cmd = method(:sudo)
      args = ["DBUS_SESSION_BUS_ADDRESS=#{dbus_session}", 'su', user_name, '-c', 'gsettings ']
    end

    args[-1].concat(gsettings_args.join(' '))

    cmd.call(args)
  end

  def self.get_properties(user_name, schema, key)
    {
      :user => user_name,
      :schema => schema,
      :key => key,
      :value => gsettings_exec(user_name, ['get', schema, key])
    }
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
    # We can't really rely on the resource names, we have to match on user, schema, and key
    settings = instances
    resources.each_key do |name|
      provider = settings.find { |setting|
        setting.schema == resources[name].parameters[:schema].value and
          setting.key == resources[name].parameters[:key].value and
          setting.user == resources[name].parameters[:user].value
      }
      resources[name].provider = provider if provider
    end
  end

  def create
    @property_flush[:ensure] = :present
  end

  def destroy
    @property_flush[:ensure] = :absent
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def flush
    if @property_flush[:ensure] == :absent
      self.class.gsettings_exec(resource[:user], ['reset', resource[:schema],
                                                  resource[:key]])
      return
    end

    self.class.gsettings_exec(resource[:user], ['set', resource[:schema],
                                                resource[:key], resource[:value]])

    @property_hash = self.class.get_properties(resource[:user], resource[:schema],
                                               resource[:key])
  end

  mk_resource_methods
end

# vim: ts=2 sts=2 sw=2 expandtab
