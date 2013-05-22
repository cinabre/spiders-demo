#!/usr/bin/env ruby
# encoding: UTF-8

require_relative 'spider'
require 'ostruct' # just for demo, inside of a db obj
require 'pry-debugger' # for debug


class JingdongParser < Spider

  def pre_loop
    channel_url = 'http://m.tmall.com/tmallCate.htm'
    
    Log.info "Requesting main page `#{channel_url}'"
    doc = Nokogiri::HTML(open(channel_url))
    
    Log.info "Parsing main page `#{channel_url}'"
    doc.css('.item:nth-child(6) .bd a').each do |a|
      link_queue << a.attr('href')
    end
  end

  def each_time
    page_url = link_queue.pop
    Log.info "Requesting page `#{page_url}'"
    doc = Nokogiri::HTML(open(page_url), nil, "UTF-8")
    
    Log.info "Parsing page `#{page_url}', Queue: #{link_queue.length}, Records: #{records.length}"
    next_page = doc.css('.pager a')[0]
    link_queue << next_page['href'] if next_page.text.include? '下页'
    
    products = doc.css('.box')[4..9]
    Log.warn "Cannot parse page `#{page_url}'" if products.empty?

    products.each do |product|
      record = OpenStruct.new
      record.title = product.css('div a').text.strip
      record.thumbnail = product.css('table a img')[0]['src']
      record.price = product.css('div strong').text
      record.src = product.css('div a')[0]['href']
      record.store = :tmall

      records << record
    end
  end
end

JingdongParser.parse
