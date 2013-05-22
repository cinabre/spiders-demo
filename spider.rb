# encoding: UTF-8

require 'nokogiri'
require 'open-uri'
require 'logger'


class Spider
  
  Log = Logger.new(STDOUT)
  Log.formatter = proc do |severity, datetime, progname, msg|
    "#{severity} #{datetime}: #{msg}\n"
  end

  attr_accessor :link_queue
  attr_accessor :options
  attr_accessor :threads
  attr_accessor :records

  DefaultOptions = {
    verbose: false,
    threads: 10,
  }

  def initialize options = {}
    self.options = options.merge DefaultOptions

    self.link_queue = Queue.new
    self.threads = []
    self.records = []
  end

  def pre_loop
  end

  def post_loop
  end

  def each_loop
  end

  def loop
    options[:threads].times { self.threads << Thread.new { each_thread_loop }}
    self.threads.each { |thr| thr.join }
  end

  def each_thread_loop
    until link_queue.empty?
      each_time
    end
  end

  def self.parse
    instance = self.new
    instance.pre_loop
    instance.loop
    # instance.each_thread_loop
    instance.post_loop
  end
end

# a little bit nokogiri hack-in
class Nokogiri::XML::NodeSet
  def base_text
    children.map{|e|e.text if e.text?}.join
  end
end