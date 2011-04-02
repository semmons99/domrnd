require 'sinatra'
require 'haml'
require 'yaml'
require 'json'
require 'active_support/core_ext/time/calculations'

set :haml, {:format => :html5 }
SETS = YAML.load_file File.expand_path("../../data/sets.yml", __FILE__)

get '/' do
  cookie = request.cookies['cards'];
  redirect '/rnd' unless cookie.nil?
  @sets = SETS.keys
  haml :index
end

get '/rnd' do
  cookie = request.cookies['cards'];
  cookie ||= SETS.values.flatten.to_json
  response.set_cookie(
    'cards',
    :value => cookie,
    :expires => Time.current.next_year
  )

  @cards = JSON.parse(cookie);
  @sets = SETS
  @set_names = SETS.keys.sort
  haml :rnd
end

post '/rnd' do
  response.set_cookie(
    'cards',
    :value => params.values.to_json,
    :expires => Time.current.next_year
  )
  redirect '/rnd'
end

get '/prefs' do
  cookie = request.cookies['cards'];
  cookie ||= [].to_json
  response.set_cookie(
    'cards',
    :value => cookie,
    :expires => Time.current.next_year
  )

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
  &.tiny
    width: 47px
#footer
  font:
    size: 75%

@@ layout
!!!
%html
  %head
    %title Dominion Set Randomizer
    %link(rel='stylesheet' type='text/css' href='/stylesheet.css')
    %meta(name='viewport' content='initial-scale=1.0, user-scalable=no')
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
  var sets = #{@sets.to_json};
  var set_names = #{@set_names.to_json};

  function rand() { return Math.round(Math.random()) - 0.5; }

  function anyFromSet(set, deck) {
    rtVal = false;
    for(var i in sets[set]) {
      for(var j in deck) {
        if (sets[set][i] == deck[j])
          rtVal = true;
      }
    }
    return rtVal;
  }

  function fromSet(set, card) {
    for(var i in sets[set]) {
      if(sets[set][i] == card)
        return true;
    }
    return false;
  }

  function getRandCards() {
    cards.sort(rand);
    var decks = cards.slice(0,10);
    decks.sort();
    document.getElementById('sets').innerHTML = '';
    for(var set_idx in set_names) {
      if(anyFromSet(set_names[set_idx], decks) == true) {
        document.getElementById('sets').innerHTML += '<b>' + set_names[set_idx] + '</b><br/>'
        for(var i in decks) {
          if(fromSet(set_names[set_idx], decks[i]))
            document.getElementById('sets').innerHTML += decks[i] + '<br/>';
        }
        document.getElementById('sets').innerHTML += '<br/>'
      }
    }
    document.getElementById('cards').innerHTML = '';
    for(var i in decks)
      document.getElementById('cards').innerHTML += decks[i] + '<br/>'
  }

  function setCookie(val) {
    var exDate = new Date();
    exDate.setDate(exDate.getDate() + 365);
    document.cookie = 'visibility=' + escape(val) + ';expires=' + exDate.toGMTString();
  }

  function hideCards() {
    document.getElementById('cards_div').style.display = 'none';
    document.getElementById('sets_div').style.display = 'block';
    setCookie('sets');
  }

  function hideSets() {
    document.getElementById('cards_div').style.display = 'block';
    document.getElementById('sets_div').style.display = 'none';
    setCookie('cards');
  }
#cards_div
  #cards
#sets_div
  #sets
%button.normal(type='button' onclick="getRandCards();")
  Generate Another Group
%br
%button.normal(type='button' onclick="parent.location='/prefs'")
  Choose Sets/Cards
%div
  Show By Set?
  %button.tiny(type='button' onclick="hideCards();")
    Yes
  %button.tiny(type='button' onclick="hideSets();")
    No
:javascript
  getRandCards();
  if (document.cookie.length > 0) {
    c_start = document.cookie.indexOf('visibility=');
    if (c_start == -1) {
      hideSets();
    } else {
      c_end = document.cookie.indexOf(";",c_start);
      if (c_end == -1)
        c_end = document.cookie.length;
      if (unescape(document.cookie.substring(c_start,c_end)) == 'visibility=sets') {
        hideCards();
      } else {
        hideSets();
      }
    }
  } else {
    hideSets();
  }

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
  #{@sets.keys.sort.map{|set| "updateSetTxt(#{set.to_json});"}.join("\n")}
