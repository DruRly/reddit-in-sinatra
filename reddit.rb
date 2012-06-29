require 'sinatra'
require 'data_mapper'
require 'haml'
require 'sinatra/reloader'

DataMapper::setup(:default, "sqlite3://#{Dir.pwd}/example.db")

class Link
  include DataMapper::Resource

  property :id, Serial
  property :title, String 
  property :url, Text 
  property :score, Integer
  property :points, Integer, :default => 0
  property :created_at, Time

  def self.score
    @_score ||= begin
      time_elapsed = (Time.now - self.created_at) / 3600
      ((self.points - 1) / (time_elapsed + 2) ** 1.8).real
    end
  end

  def self.all_sorted_desc
    self.all.sort { |a,b| a.score <=> b.score }.reverse 
  end

  def upvote(mod = 1)
    self.points += mod
  end

  def downvote(mod = 1)
    self.points -= mod
  end

  def upvote!(*a, &b)
    self.upvote(*a, &b)
    self.save
  end

  def downvote!(*a, &b)
    self.downvote(*a, &b)
    self.save
  end
end

DataMapper.finalize.auto_upgrade!

get '/' do 
  @links = Link.all :order => :id.desc

  haml :index
end

get '/hot' do
  @links = Link.all_sorted_desc

  haml :index  
end

post '/' do
  Link.create(:title => params[:title], :url => params[:url], :created_at => Time.now)

  redirect back
end

put '/:id/:type' do
  link = Link.get(params[:id]) or halt 404

  case params[:type]
  when 'upvote'
    link.upvote!
  when 'downvote'
    link.downvote!
  else
    halt 400
  end

  redirect back
end 

__END__

@@ layout
%html
  %head
    %link(rel="stylesheet" href="/css/bootstrap.css")
    %link(rel="stylesheet" href="/css/style.css")
  %body
    .container
      #main
        .title Learn Sinatra
        .options  
          %a{:href => ('/')} New 
          | 
          %a{:href => ('/hot')} Hot
        = yield

@@ index
#links-list  
  -@links.each do |l|  
    .row
      .span3
        %span.span
          %form{:action => "#{l.id}/upvote", :method => "post"}
            %input{:type => "hidden", :name => "_method", :value => "put"}
            %input{:type => "submit", :value => "⇡"}
        %span.points
          #{l.points}
        %span.span
          %form{:action => "#{l.id}/downvote", :method => "post"}
            %input{:type => "hidden", :name => "_method", :value=> "put"}
            %input{:type => "submit", :value => "⇣"}        
      .span6
        %span.link-title
          %h3
            %a{:href => (l.url)} #{l.title}
#add-link
  %form{:action => "/", :method => "post"}
    %input{:type => "text", :name => "title", :placeholder => "Title"}
    %input{:type => "text", :name => "url", :placeholder => "Url"}
    %input{:type => "submit", :value => "Submit"}  
