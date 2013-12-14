require "rubygems"
require "sinatra"
require "json"

set :port, 4568

class ExpCache
	def initialize opts
		@default_timeout = opts[:default_timeout] || 5.0 
		@cache = {}
		@timeouts = {}
	end
	def add key, obj, timeout=nil
		timeout = @default_timeout unless @timeout
		@cache[key] = obj
		@timeouts[key] = Time.new.to_f + timeout
	end
	def del key
		@timeouts.delete key
		@cache.delete key
	end
	def check_key key
		return nil unless @cache[key]
		return true unless @timeouts[key]
		if @timeouts[key] <= Time.now.to_f
			@timeouts.delete key
			@cache.delete key
			return false
		else
			return true
		end
	end
	def get key
		return nil unless check_key key
		return @cache[key]
	end
	def cleanup
		@cache.each_key do |k|
			check_key k
		end
	end
end

cache=ExpCache.new  :defalut_timeout => 1

get "/story.json" do 
	unless storyarray=cache.get( 'storyarray' )
		storyarray = Dir.new( "./public/story" ).entries.sort
		storyarray.delete '.'
		storyarray.delete '..'
		storyarray.map! { |v| /\.html$/ =~ v ? v : nil }
		storyarray.compact!
		cache.add 'storyarray', storyarray = {"chapters"=>storyarray}.to_json
	end
	content_type "application/json"
	storyarray
end


get "/*" do 
	redirect "/main.html"
end
