#!/usr/bin/env ruby
# date: 01/12/12 
# author: nate 
# description: testing macutils class

require 'pathname'
require './macutils'

a = Macutils.new
#puts a.get_full_name(a.get_current_user)
#puts a.get_full_name("goo")
#puts a.get_homedir(a.get_current_user)
#puts a.stash_user_file("/tmp/1","Documents")
puts a.methods.sort
