%w{sinatra data_mapper haml sinatra/reloader}.each { |lib| require lib}

DataMapper::setup(:default,"sqlite3://#{Dir.pwd}/example.db")

class Link
  include DataMapper::Resource
  property :id, Serial
  property :title, String, :required => true 
  property :url, Text, :required => true, :format => :url 
  property :points, Integer, :default => 0
  property :created_at, Time

  attr_accessor :score

  def calculate_score
  	time_elapsed = (Time.now - self.created_at) / 3600
   	self.score = ((self.points-1) / (time_elapsed+2)**1.8).real
  end

  def self.all_sorted_desc
    self.all.each { |item| item.calculate_score }.sort { |a,b| a.score <=> b.score }.reverse 
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

put '/:id/vote/:type' do 
  l = Link.get params[:id]
  l.points += params[:type].to_i
  l.save
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
					%form{:action => "#{l.id}/vote/1", :method => "post"}
						%input{:type => "hidden", :name => "_method", :value => "put"}
						%input{:type => "submit", :value => "⇡"}
				%span.points
					#{l.points}
				%span.span
					%form{:action => "#{l.id}/vote/-1", :method => "post"}
						%input{:type => "hidden", :name => "_method", :value=> "put"}
						%input{:type => "submit", :value => "⇣"}				
			.span6
				%span.link-title
					%h3
						%a{:href => (l.url)} #{l.title}

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
