Puppet::Type.type(:user_gsettings).provide(:user_gsettings) do
  commands gsettings: '/usr/bin/gsettings'
  commands dbus_launch: '/usr/bin/dbus-launch'
  commands getent: '/usr/bin/getent'

  def self.instances
    users = getent(['passwd']).encode('UTF-8', 'binary', invalid: :replace, undef: :replace, replace: '')

    settings = []
    
    users.split("\n").map do |user|
      user_properties = user.to_s.split(':')
      if user_properties[2].to_i >= 1000 then
        settings << new(
          name: "#{user_properties[0]} - blahs blak",
          schema: :blahs,
          key: :blahk,
          value: :blahv,
          user: user_properties[0])
      end
    end

    settings.compact!
  end

  def self.prefetch(resources)
  end

  def create
  end

  def destroy
  end

  def exists?
  end
end

# vim: ts=2 sts=2 sw=2 expandtab
