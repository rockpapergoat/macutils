#!/usr/bin/env ruby
# date: 2012-01-12
# author: nate
# description: utility functions for mac administration

require 'rubygems'
require "FileUtils"
require 'pathname'
require 'open-uri'
require 'openssl'
require 'json'

class Macutils
  
  # user and group tools
  
  # returns: string
  def get_current_user
    @user = Etc.getlogin.chomp
  end
  
  # returns: string
  def get_full_name(user)
    Etc.getpwnam("#{user}")["gecos"].chomp
    # or with dscl
    #%x(dscl . -read /users/#{user} original_realname).split.drop(1).join(" ")
  end
  
  # returns: string
  def get_homedir(user)
    Etc.getpwnam("#{user}")["dir"].chomp
    # or with dscl
    #homedir = %x(dscl . -read /users/#{user} NFSHomeDirectory).gsub(/NFSHomeDirectory: /,"")
  end
  
  # returns: array
  def get_admins
    `dscl . -read /groups/admin GroupMembership`.split.drop(1)
  end
  
  # returns: hash of hashes in this form {"user" => 1209765}
  def get_all_over500_users
    user_hash = {}
    `dscl . -list /users UniqueID | sort -k2 -n`.split("\n").each do |pair|
      pair.split(" ").collect! { user_hash[pair.split(" ")[0]] = pair.split(" ")[1].to_i}
    end
    user_hash.delete_if {|k,v| v.to_i < 500 }
    # can also do it like this, but it reports all directory entries
    # Etc.passwd { |d| user_hash[d.name] = d.uid if d.uid > 500 }
  end
  
  
  
  # networking
  
  # returns: array
  def get_interfaces
      @list = %x(/usr/sbin/networksetup -listallnetworkservices).split("\n").drop(1)
  end
  
  # returns: string
  # for now, just outputs what it would do.
  # will return maybe nothing unless error.
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
  
  # returns: nothing
  # adds file to jamf specific dummy receipts folder
  def create_dummy_receipt(receipt)
    crumb = File.new("/Library/Application\ Support/JAMF/Receipts/#{receipt}", "w")
    crumb.close
  end
  
  # misc. tools
  
  # returns: string
  # notifies of copying file or files to spot under user's homedir.
  # assumes passing full path to the file to be copied.
  # needs work before using.
  # fra-gee-lay
  def stash_user_file(file,path)
      users = get_all_over500_users
      users.each_key do |u|
          puts "copying files to #{u}\'s home at #{path}."
          system "ditto -V #{file} /Users/#{u}/#{path}/#{File.basename(file)}"
          FileUtils.chown_R("#{u}", nil, "/Users/#{u}/#{path}/#{File.basename(file)}")
      end
  end
  
  # returns: string
  def get_serial
    %x(system_profiler SPHardwareDataType | awk '/Serial/ {print $4}').upcase.chomp
  end
  
  # returns: string
  # more like a bunch of text
  # cf. this is based on gary larizza's script:
  # https://github.com/glarizza/scripts/blob/master/ruby/warranty.rb
  def get_warranty(serial, proxy = "")
    serial = serial.upcase
    warranty_data = {}
    raw_data = open('https://selfsolve.apple.com/warrantyChecker.do?sn=' + serial.upcase + '&country=USA', :proxy => "#{proxy}")
    warranty_data = JSON.parse(raw_data.string[5..-2])

    puts "\nSerial Number:\t\t#{warranty_data['SERIAL_ID']}\n"
    puts "Product Decription:\t#{warranty_data['PROD_DESCR']}\n"
    puts "Purchase date:\t\t#{warranty_data['PURCHASE_DATE'].gsub("-",".")}"

    unless warranty_data['COV_END_DATE'].empty?
      puts "Coverage end:\t\t#{warranty_data['COV_END_DATE'].gsub("-",".")}\n"
    else
      puts "Coverage end:\t\tEXPIRED\n"
    end
    
  end

end

# EXAMPLES

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

# copy files to a user's homedir
# a.stash_user_file("/tmp/blorp","Library/Preferences")

# get the current machine's warranty coverage
# a.get_warranty(a.get_serial, "http://1.1.1.1:8080")