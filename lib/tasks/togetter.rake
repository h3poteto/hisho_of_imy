# coding: utf-8
require File.expand_path(File.dirname(__FILE__) + "/../../config/environment")
require 'rubygems'
require 'open-uri'
require 'nokogiri'
require 'kconv'
require 'uri'
require 'net/http'

togetter_url = "http://togetter.com/li/318700"
more_url = "http://togetter.com/api/moreTweets/318700"

namespace :togetter do
  desc "get togetter data"
  task :all => :environment do
    @result = []
    url = togetter_url
    doc = Nokogiri::HTML(open(url))
    show_tweet(doc.css('.type_tweet'))

    # metaからcsrf_tokenを抜き出す
    csrf_token = nil
    doc.xpath("//meta[@name='csrf_token']/@content").each do |attr|
      csrf_token = attr.value
    end

    # cookieからcsrf_secretを抜き出す
    cookie = {}
    uri = URI.parse(togetter_url)
    http = Net::HTTP.new(uri.host)
    http.start
    res = http.get '/'

    res.get_fields('Set-Cookie').each{|str|
      k,v = str[0...str.index(';')].split('=')
      cookie[k] = v
    }
    
    # 2page目だけで大丈夫
    body_text = nil
    uri = URI.parse( more_url )
    Net::HTTP.start(uri.host, uri.port){|http|
      header = {
        "Content-Type" =>"application/x-www-form-urlencoded; charset=UTF-8",
        "Cookie" => "__gads=ID=72e5f3cd280aa17b:T=1365436955:S=ALNI_MYrR64sJ8QXnqYshLHpmqRRbOhNxQ; csrf_secret=#{cookie['csrf_secret']}"
      }
      body ="page=2&csrf_token=" + csrf_token
      response = http.post(uri.path, body, header)
      body_text = response.body.toutf8
    }
    doc = Nokogiri::HTML(body_text)
    show_tweet(doc.css('.type_tweet'))
  end

  def show_tweet(tweet)
    tweet.each do |t|
      p t.css('.tweet').text
      p ("")
    end
  end
end
