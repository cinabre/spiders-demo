# encoding: UTF-8

require 'nokogiri'
require 'open-uri'
require 'logger'
require 'ostruct' # just for demo, inside of a db obj
require 'pry-debugger' # for debug


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
    instance.post_loop
  end
end

class Nokogiri::XML::NodeSet
  def base_text
    children.map{|e|e.text if e.text?}.join
  end

  def attr_text attribute_name
    attr(attribute_name).to_s
  end
end

class JingdongParser < Spider

  def pre_loop
    channel_url = 'http://m.jd.com/category/1316.html'
    
    Log.info "Requesting main page `#{channel_url}'"
    doc = Nokogiri::HTML(open(channel_url))
    
    Log.info "Parsing main page `#{channel_url}'"
    doc.css('.mc a:not(.on)').each do |a|
      link_queue << a.attr('href')
    end
  end

  def each_time
    page_url = "http://m.jd.com#{link_queue.pop}"
    Log.info "Requesting page `#{page_url}'"
    doc = Nokogiri::HTML(open(page_url), nil, "UTF-8")
    
    Log.info "Parsing page `#{page_url}', Queue: #{link_queue.length}, Records: #{records.length}"
    next_page = doc.css('.page a')
    link_queue << next_page.attr_text('href') if next_page.text.include? '下一页'
    
    products = doc.css('.pmc')
    Log.warn "Cannot parse page `#{page_url}'" if products.empty?

    products.each do |product|
      record = OpenStruct.new
      record.title = product.css('.title a').base_text
      record.thumbnail = product.css('.pic a img').attr_text 'src'
      record.price = product.css('.price font').text
      record.thumbnail = product.css('.title a').attr_text 'href'

      records << record
    end
  end
end

JingdongParser.parse