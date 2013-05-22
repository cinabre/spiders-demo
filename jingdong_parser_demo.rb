#!/usr/bin/env ruby
# encoding: UTF-8

require_relative 'spider'
require 'ostruct' # just for demo, inside of a db obj
require 'pry-debugger' # for debug


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
    link_queue << next_page[0]['href'] if next_page.text.include? '下一页'
    
    products = doc.css('.pmc')
    Log.warn "Cannot parse page `#{page_url}'" if products.empty?

    products.each do |product|
      record = OpenStruct.new
      record.title = product.css('.title a').base_text.strip
      record.thumbnail = product.css('.pic a img')[0]['src']
      record.price = product.css('.price font').text
      record.src = product.css('.title a')[0]['href']
      record.store = :jingdong

      records << record
    end
  end
end

JingdongParser.parse
