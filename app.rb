require 'sinatra'
require 'sinatra/reloader' if development?
require File.dirname(__FILE__) + '/waz-storage/lib/waz-tables.rb'
require File.dirname(__FILE__) + '/waz-storage/lib/waz-blobs.rb'
require File.dirname(__FILE__) + '/secrets.rb'
require 'kconv'
require 'rss/maker'
require File.dirname(__FILE__) + '/metaweblog.rb'

set :public, File.dirname(__FILE__) + '/static'

get '/' do
  options = {:top => 5, :expression => "(PartitionKey eq '#{PARTITION}') and (not IsDraft)"}
  if request.query_string.length > 0
    split = request.query_string.split '/'
    options.merge!( {:continuation_token => {'NextPartitionKey' => split[0], 'NextRowKey' => split[1]}} )
  end
  @entries = WAZ::Tables::Table.service_instance.query('BlogEntryTable', options)
  haml :index
end

get '/posts/:permalink' do
  entry = WAZ::Tables::Table.service_instance.query('BlogEntryTable', {:expression => "(PartitionKey eq '#{PARTITION}') and (Permalink eq '#{params[:permalink]}')"})[0]
  haml :post, :locals => {:entry => entry}
end

def feed(version)
  host = request.host
  host += ":#{request.port}" unless request.port == 80
  nextlink = nil
  [RSS::Maker.make(version) do |m|
    m.channel.title = m.channel.subtitle = m.channel.description = DESCRIPTION
    m.channel.link = BLOG_URL
    m.channel.id = CHANNEL_ID
    m.channel.date = m.channel.updated = Time.now.utc
    m.channel.author = AUTHOR
    m.items.do_sort = true

    cont = nil
    count = 0
    while count < 10 and (cont.nil? or (!cont['NextPartitionKey'].nil? or !cont['NextRowKey'].nil?))
      entries = WAZ::Tables::Table.service_instance.query('BlogEntryTable', :continuation_token => cont, :top => 10, :expression => "(PartitionKey eq '#{PARTITION}') and (not IsDraft)")
      count += entries.length
      entries.each do |entry|
        i = m.items.new_item
        i.title = entry[:Title]
        i.link = "http://#{host}/posts/#{entry[:Permalink]}"
        i.author = EMAIL_ADDRESS
        i.content.type = 'html'
        i.description = i.content.content = entry[:Body]
        i.date = entry[:Posted]
        i.guid.content = i.link
      end
      cont = entries.continuation_token
    end

    unless cont.nil? or (cont['NextPartitionKey'].nil? and cont['NextRowKey'].nil?)
      nextlink = m.channel.links.new_link
      nextlink.rel = "next"
      nextlink.href = "?continuation=#{cont['NextPartitionKey']}/#{cont['NextRowKey']}"
    end
  end, nextlink]
end

['/atom', '/atompub.svc/blog/posts/?'].each do |path|
  get path do
    pass if params[:fmt] == 'rss'
    content_type 'application/atom+xml'
    feed("atom")[0].to_s
  end
end

['/rss', '/atompub.svc/blog/posts/?'].each do |path|
  get path do
    content_type 'application/rss+xml'
    feed, link = feed("2.0")
    xml = feed("2.0")[0].to_s.sub('xmlns:itunes="http://www.itunes.com/dtds/podcast-1.0.dtd"', 'xmlns:atom="http://www.w3.org/2005/Atom"')
    if !link.nil?
      xml.sub!("</description>", "</description><atom:link rel=\"next\" href=\"#{link.href}\" />")
    end
    xml
  end
end

not_found do
  haml :notfound
end

error do
  haml :error
end