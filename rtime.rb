#!/usr/bin/ruby

# == Synopsis
#
# rtime: tracks time 
#
# == Usage
#
# rtime [OPTION] 
#
# -h, --help:
#    show help
#
# -s [TASK], --start [TASK]:
#	start task
# -t [TASK], --stop [TASK]:
#	stop task 
# -c [TASK], --clear [TASK]
#	clear entries for task
# -l [TASK], --list [TASK]
#	list entries for task
#
# TASK: The task to track time on. Clear and list take MySQL LIKE wildcards. 
#

require 'rubygems'
require 'sqlite3'
require 'activerecord'
require 'rdoc/usage'
require 'pathname'

DB_DIR = File.join(ENV['HOME'], '.rtime')
Dir.mkdir(DB_DIR) unless File.exist?(DB_DIR)
DB_PATH = File.join(DB_DIR, "rtime.sqlite3")
SQLite3::Database.new(DB_PATH)

ActiveRecord::Base.establish_connection(:adapter => 'sqlite3', :database => DB_PATH)

class ProjectTime < ActiveRecord::Base
end
class TimeCommands
	def self.start(task)
		ProjectTime.create!(:task=>task, :start=>Time.now) 
	end
	def self.stop(task)
		p = ProjectTime.find(:first, :conditions=>["task = ? AND end IS NULL ", task])
		p.update_attributes(:end=>Time.now) if p
	end
	def self.list(task)
		total_minutes = 0.0
		ProjectTime.find(:all, :conditions=>["task LIKE ?", task]).each do |p|
			minutes = ((((p.end || Time.now) - (p.start))/6).floor.to_f / 10)
			puts "#{p.task.ljust(10)} #{p.start.to_s(:short)}#{p.end ? "-#{p.end.to_s(:short)}" : ''} (#{minutes}m)"
			total_minutes = total_minutes + minutes
		end
		puts "#{'TOTAL:'.ljust(10)} #{total_minutes}m"
	end
	def self.clear(task)
		ProjectTime.delete_all(["task LIKE ?", task])
	end
end

if !ProjectTime.table_exists?
  ActiveRecord::Base.connection.create_table(:project_times) do |t|
    t.column :task, :string
    t.column :start, :timestamp
	t.column :end, :timestamp
  end
end


opts = GetoptLong.new(
  [ '--help', '-h', GetoptLong::NO_ARGUMENT ],
  [ '--stop', '-x', GetoptLong::OPTIONAL_ARGUMENT],
  [ '--start', '-s', GetoptLong::OPTIONAL_ARGUMENT],
  [ '--list', '-l', GetoptLong::OPTIONAL_ARGUMENT],
  [ '--clear', '-c', GetoptLong::OPTIONAL_ARGUMENT]
)

opts.each do |opt, arg|
  case opt
	when '--help'
	  RDoc::usage
	when '--start'
		task = arg
		puts "Starting task #{task}..."
		TimeCommands.start(task)
		TimeCommands.list(task)
	when '--stop'
		task = arg
		puts "Stopping #{task}..."
		TimeCommands.stop(task)
		TimeCommands.list(task)
	when '--clear'
		task = arg
		puts "Clearing #{task}..."
		TimeCommands.clear(task)
		TimeCommands.list(task)
	when '--list'
		task = arg
		TimeCommands.list(task)
  end
end

if ARGV.length==0
	RDoc::usage
end
