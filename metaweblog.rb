require 'xmlrpc/marshal'
require 'builder'

get '/metaweblog' do
  xml = Builder::XmlMarkup.new
  xml.instruct!
  host = request.host
  host += ":#{request.port}" unless request.port == 80
  xml.rsd(:version => "1.0", :xmlns => "http://archipelago.phrasewise.com/rsd") do
    xml.service do
      xml.engineName BLOG_NAME
      xml.engineLink "http://#{host}"
      xml.homePageLink "http://#{host}"
      xml.apis do
        xml.api(:name => "MetaWebLog", :preferred => true, :apiLink => request.url, :blogID => 0)
      end
    end
  end
  xml.target!
end

post '/metaweblog' do
  xml = request.body.read
  
  call = XMLRPC::Marshal.load_call(xml)
  
  method = call[0].gsub(/(?:metaWeblog|blogger)\.(.*)/, '\1').gsub(/([A-Z])/, '_\1').downcase.intern
  
  raise NoMethodError, "Invalid method '#{method}'" unless [:get_users_blogs, :get_recent_posts, :get_post, :get_categories, :new_post, :edit_post, :new_media_object].include?(method)
  return 403 unless call[1][1] == USERNAME and call[1][2] == PASSWORD
  
  content_type 'text/xml'
  send(method, *call[1])
end

def get_users_blogs(something, username, password)
  host = request.host
  host += ":#{request.port}" unless request.port == 80
  XMLRPC::Marshal.dump_response([{:url => 'http://#{host}', :blogid => "0", :blogName => BLOG_NAME}])
end

def get_post(postid, username, password)
  entry = WAZ::Tables::Table.service_instance.get_entity("BlogEntryTable", PARTITION, postid)
  XMLRPC::Marshal.dump_response(to_metaweblog(entry))
end

def get_recent_posts(blogid, username, password, n)
  top = [1000, n].min
  entries = WAZ::Tables::Table.service_instance.query("BlogEntryTable", :top => top, :expression => "(PartitionKey eq '#{PARTITION}')")
  XMLRPC::Marshal.dump_response(entries.map { |entry| to_metaweblog(entry) })
end

def get_categories(blogid, username, password)
  XMLRPC::Marshal.dump_response([])
end

def edit_post(postid, username, password, post, publish)
  WAZ::Tables::Table.service_instance.merge_entity('BlogEntryTable', {
    :partition_key => PARTITION,
    :row_key => postid,
    :Title => post["title"],
    :Body => post["description"],
    :IsDraft => !publish
  })
  XMLRPC::Marshal.dump_response(true)
end

def new_post(blogid, username, password, post, publish)
  entry = {
      :partition_key => PARTITION,
      :row_key => "%019d %s" % [3155378975999999999-621355968000000000-Time.now.to_i*10000000, permalink(post["title"])], # equivalent of C# (DateTime.MaxValue - DateTime.UtcNow).Ticks.ToString("d19")
      :Timestamp => Time.now.utc,
      :Title => post["title"],
      :Permalink => permalink(post["title"]),
      :Body => post["description"],
      :IsDraft => !publish,
      :Posted => Time.now.utc
    }
  WAZ::Tables::Table.service_instance.insert_entity('BlogEntryTable', entry)
  return XMLRPC::Marshal.dump_response(entry[:row_key].to_s)
end

def permalink(title)
  title.downcase.gsub(/[^a-z]/,'-').sub(/^-/, '').sub(/-$/, '').gsub(/--+/, '-')
end

def to_metaweblog(entry)
  host = request.host
  host += ":#{request.port}" unless request.port == 80
  {
    :dateCreated => entry[:Posted],
    :userid => 1,
    :postid => entry[:row_key],
    :description => entry[:Body],
    :title => entry[:Title],
    :link => "http://#{host}/posts/#{entry[:Permalink]}",
    :permalink => "http://#{host}/posts/#{entry[:Permalink]}",
    :date_created_gmt => entry[:Posted].getgm
  }
end

def new_media_object(blogid, username, password, object)
  name = rand(32**10).to_s(32)
  WAZ::Blobs::Container.service_instance.put_blob("images/#{name}", object['bits'], object['type'])
  host = "#{WAZ::Storage::Base.default_connection[:account_name]}.blob.core.windows.net"
  host = CDN_HOST if defined? CDN_HOST
  XMLRPC::Marshal.dump_response({:url => "http://#{host}/images/#{name}"})
end