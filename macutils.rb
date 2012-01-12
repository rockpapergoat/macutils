#!/usr/bin/env ruby
# date: 2012-01-12
# author: nate
# description: utility functions for mac administration

require 'rubygems'
require "FileUtils"
require 'pathname'

class Macutils
  
  # user and group tools
  def get_current_user
    @user = Etc.getlogin.chomp
  end

  def get_full_name(user)
    Etc.getpwnam("#{user}")["gecos"].chomp
    # or with dscl
    #%x(dscl . -read /users/#{user} original_realname).split.drop(1).join(" ")
  end

  def get_homedir(user)
    Etc.getpwnam("#{user}")["dir"].chomp
    # or with dscl
    #homedir = %x(dscl . -read /users/#{user} NFSHomeDirectory).gsub(/NFSHomeDirectory: /,"")
  end
  
  # networking
  def get_interfaces
      @list = %x(/usr/sbin/networksetup -listallnetworkservices).split("\n").drop(1)
  end
  
  def set_proxyurl(interfaces)
      if interfaces.is_a?(Array)
        interfaces.each do |nic|
            puts "/usr/sbin/networksetup -setautoproxyurl #{nic} http://llnobody/proxy.pac"
        end
      else
          puts "no interfaces passed. try again."
      end
  end
  
  # process tools
  def kill_process(process)
    # attempt to kill by name
  end
  
  def uninstall_app(*args)
    # 
  end
  
  # pkg tools
  def forget_pkgs(*args)
    args.each do |receipt|
      known_pkgs = %x(pkgutil --pkgs).split
      if known_pkgs.include?(receipt.to_s)
        puts "#{receipt} is in receipts database. removing now."
        %x(pkgutil --forget #{receipt})
      else
        puts "#{receipt} is not in receipts database. stopping."
      end
    end
  end
  
  def remove_paths(*args)
    args.each do |item|
      if File.directory?(item)
        puts "#{item} is a path. removing it now."
        # set :noop => true to do a dry run
        FileUtils.rm_rf(item, :verbose => true)
      else
        puts "#{item} doesn't exist or isn't a directory."
      end
    end
  end
  
  def create_dummy_receipt(receipt)
    crumb = File.new("/Library/Application\ Support/JAMF/Receipts/#{receipt}", "w")
    crumb.close
  end
  
  # misc. tools
  def stash_user_file(*args)
    # not really needed, since casper handles FEU and FUT
  end

end

# to use, instantiate a class object, then call the methods
a = Macutils.new

# set proxy for all interfaces
# a.set_proxyurl(a.get_interfaces)
# remove paths passed as args
# a.remove_paths("/tmp/1", "/tmp/2")
# forget pkgs from the receipts db
# a.forget_pkgs("edu.mit.ll.ilife11", "com.done.cow")
# create a dummy receipt under jamf receipts
# a.create_dummy_receipt("Google Chrome.pkg")