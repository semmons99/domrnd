require 'sinatra'
require 'haml'
require 'json'
require 'active_support'

set :haml, {:format => :html5 }
SETS = YAML::load_file 'sets.yml'

get '/' do
  cookie = request.cookies['cards'];
  redirect '/rnd' unless cookie.nil?
  @sets = SETS.keys
  haml :index
end

get '/rnd' do
  cookie = request.cookies['cards'];
  cookie ||= SETS.values.flatten.to_json
  set_cookie('cards', :value => cookie, :expires => 1.year.from_now)

  @cards = JSON.parse(cookie);
  haml :rnd
end

post '/rnd' do
  set_cookie('cards', :value => params.values.to_json, :expires => 1.year.from_now)
  redirect '/rnd'
end

get '/prefs' do
  cookie = request.cookies['cards'];
  cookie ||= [].to_json
  set_cookie('cards', :value => cookie, :expires => 1.year.from_now)

  @saved_cards = JSON.parse(cookie);
  @sets = SETS
  haml :prefs
end

get '/stylesheet.css' do
  headers 'Content-Type' => 'text/css; charset=utf-8'
  sass :stylesheet
end

__END__

@@ stylesheet
body
  font:
    family: sans-serif
button
  &.normal
    width: 200px
  &.short
    width: 98px
#footer
  font:
    size: 75%

@@ layout
!!!
%html
  %head
    %title Dominion Set Randomizer
    %link(rel='stylesheet' type='text/css' href='/stylesheet.css')
  %body
    = yield
    #footer
      %a(href='http://github.com/semmons99/domrnd')
        Vist project page
    :javascript
      var gaJsHost = (("https:" == document.location.protocol) ? "https://ssl." : "http://www.");
      document.write(unescape("%3Cscript src='" + gaJsHost + "google-analytics.com/ga.js' type='text/javascript'%3E%3C/script%3E"));
    :javascript
      try {
        var pageTracker = _gat._getTracker("UA-7938691-6");
        pageTracker._trackPageview();
      } catch(err) {}
      

@@ index
#div.info
  Available Sets: #{@sets.sort.join(", ")}
%button.normal(onclick="parent.location='/rnd'")
  Use All Cards
%br
%button.normal(onclick="parent.location='/prefs'")
  Choose Sets/Cards

@@ rnd
:javascript
  var cards = #{@cards.to_json};
  function rand() { return Math.round(Math.random()) - 0.5; }
  function getRandCards() {
    cards.sort(rand);
    var decks = cards.slice(0,10);
    decks.sort();
    document.getElementById('cards').innerHTML = '';
    for(var i in decks)
      document.getElementById('cards').innerHTML += decks[i] + '<br/>';
  }
#cards
%button.normal(type='button' onclick="getRandCards();")
  Generate Another Group
%br
%button.normal(type='button' onclick="parent.location='/prefs'")
  Choose Sets/Cards
:javascript
  getRandCards();

@@ prefs
:javascript
  sets = #{ @sets.to_json };

  function writeSetTxt(set, val) {
    document.getElementById(set + '_txt').innerHTML = 'Using ' + val + ' ' + set + ' Cards'
  }

  function getCard(set, i) {
    return document.getElementsByName(set + '/' + sets[set][i])[0];
  }

  function check(set) {
    for(var i in sets[set])
      getCard(set,i).checked = true;
    writeSetTxt(set, 'All');
  }

  function uncheck(set) {
    for(var i in sets[set])
      getCard(set,i).checked = false;
    writeSetTxt(set, 'No');
  }

  function updateSetTxt(set) {
    var usingAll = 0;
    for(var i in sets[set]) {
      if (getCard(set,i).checked == true)
        usingAll++;
    }
    if (usingAll == 0) {
      writeSetTxt(set, 'No');
    } else if (usingAll < sets[set].length) {
      writeSetTxt(set, 'Some');
    } else {
      writeSetTxt(set, 'All');
    }
  }
%form(action='/rnd' method='post')
  - @sets.keys.sort.each do |set|
    %div{:id => "#{set}_txt"}
      Using ? #{set} Cards
    %button.short{:type => 'button', :onclick => "check(#{set.to_json})"}
      = "Select All"
    %button.short{:type => 'button', :onclick => "uncheck(#{set.to_json})"}
      = "Deselect All"
    %hr
  %button.normal(type='submit')
    Save
  %hr
  - @sets.keys.sort.each do |set|
    %div
      = "Specific #{set} Cards"
    - @sets[set].sort.each do |card|
      %div
        %input{:type => 'checkbox', :name => "#{set}/#{card}", :value => card, :checked => @saved_cards.include?(card), :onclick => "updateSetTxt(#{set.to_json})"}
        = card
    %hr
  %button.normal(type='submit')
    Save
:javascript
  #{@sets.keys.sort.map{|set| "updateSetTxt(#{set.to_json});\n"}}
