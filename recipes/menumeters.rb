menu_meters_destdir = "#{ENV['HOME']}/Library/PreferencePanes/"
menu_meters_dst = menu_meters_destdir + "MenuMeters.prefPane"

homebrew_cask "menumeters"

unless File.exists?(menu_meters_dst)
  plist_file = "#{ENV['HOME']}/Library/Preferences/com.apple.systemuiserver.plist"

  ruby_block "Put MenuMeters on the Menubar" do
    block do
      Gem.clear_paths
      require 'rubygems'
      require 'plist'
      `plutil -convert xml1 #{plist_file}`
      ui_plist = Plist::parse_xml(plist_file)
      ui_plist['menuExtras'] ||= Array.new
      ui_plist['menuExtras'].unshift(
      '~/Library/PreferencePanes/MenuMeters.prefPane/Contents/Resources/MenuMeterNet.menu',
      '~/Library/PreferencePanes/MenuMeters.prefPane/Contents/Resources/MenuMeterDisk.menu',
      '~/Library/PreferencePanes/MenuMeters.prefPane/Contents/Resources/MenuMeterMem.menu',
      '~/Library/PreferencePanes/MenuMeters.prefPane/Contents/Resources/MenuMeterCPU.menu',
      '~/Library/PreferencePanes/MenuMeters.prefPane/Contents/Resources/MenuCracker.menu'
      )
      File.open(plist_file, "w") do |plist_handle|
        plist_handle.puts Plist::Emit.dump(ui_plist)
      end
    end
    # long path because this command runs as root, and we're in node['sprout']['user']'s preferences, not root's
    not_if "defaults read ~#{node['sprout']['user']}/Library/Preferences/com.apple.systemuiserver menuExtras | grep 'MenuMeters.prefPane'"
  end

  # My preferences: more history graphs.  Delete this stanza if you want to go with the defaults.
  plist_path = File.expand_path('com.ragingmenace.MenuMeters.plist', File.join(node['sprout']['home'], 'Library', 'Preferences'))
  template plist_path do
    source "com.ragingmenace.MenuMeters.plist.erb"
    owner node['sprout']['user']
  end

  execute "Restart SystemUIServer" do
    command 'killall -HUP SystemUIServer'
    user node['sprout']['user']
    ignore_failure true # SystemUIServer is not running if not logged in
  end

  ruby_block "test to see if MenuMeters was installed" do
    block do
      raise "MenuMeters install failed" unless File.exists?(menu_meters_dst)
    end
  end
end
