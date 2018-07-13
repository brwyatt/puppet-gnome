Puppet::Type.newtype(:user_gsettings) do
  @doc = <<-MANIFEST
    Sets a configuration key in a user's Gnome GSettings registry.
  MANIFEST

  ensurable

  newparam(:name, :namevar => true) do
  end

  newproperty(:schema) do
    defaultto 'wut?'
  end

  newproperty(:key) do
    defaultto 'wut?'
  end

  newproperty(:value) do
    defaultto 'wut?'
  end

  newproperty(:user) do
    defaultto 'wut?'
  end
end

# vim: ts=2 sts=2 sw=2 expandtab
