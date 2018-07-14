Puppet::Type.newtype(:user_gsettings) do
  @doc = <<-MANIFEST
    Sets a configuration key in a user's Gnome GSettings registry.
  MANIFEST

  ensurable

  newparam(:name, :namevar => true) do
  end

  newproperty(:schema) do
    isrequired
  end

  newproperty(:key) do
    isrequired
  end

  newproperty(:value) do
    isrequired
  end

  newproperty(:user) do
    isrequired
  end
end

# vim: ts=2 sts=2 sw=2 expandtab
