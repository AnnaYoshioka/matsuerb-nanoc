# -*- coding: utf-8 -*-

require 'yaml'
require 'icalendar'
require 'date'

def get_tags(items)
  tag_num_hash = Hash.new(0)
  items.each do |item|
    if item[:tags]
      item[:tags].each do |tag|
        tag_num_hash[tag] += 1
      end
    end
  end
  return tag_num_hash
end

def tags_page
  tags = get_tags(@items)
  html_source = '<ul">'
  tags.each do |k, v|
    html_source << '<li class="tagnum' + v.to_s + '">' + link_to(k, "/tags/#{k}/") + '</li>'
  end
  html_source << '</ul>'
end

def tags_in_article
  tags = @item[:tags]
  html_source = '<ul">'
  tags.each do |k, v|
    html_source << '<li class="tagnum' + v.to_s + '">' + link_to(k, "/tags/#{k}/") + '</li>'
  end
  html_source << '</ul>'
end

def tag_page
  tags = get_tags(@items)
  tags.each do |k, v|
    page_stats = {:title => "tag: #{k}", :tag_page_title => "#{k}"}
    option = {:binary => false}
    @items << Nanoc::Item.new("<%= render('_tag') %>", page_stats, "/tags/#{k}/", option)
  end
end

def tag_page_item_list(tag)

#  html_source = '<dl">'
  html_source = ""
  items_with_tag(tag).each do |item|
    html_source << "<blockquote><small>#{link_to(item[:title], item.identifier)}</small><p>#{strip_html(item.reps.first.compiled_content).slice(0,100)}...</p></blockquote>"
  end
  html_source
end

def article_list
  html_source = "<ul>"
  sorted_articles.each do |item|
    date = item[:updated_at]
    date ||= item[:created_at]
    html_source << "<li>#{link_to(item[:title], item.identifier)} - #{date}</li>"
  end
  html_source << "</ul>"
end

def fbe(id)
  return link_to("Facebook", "https://www.facebook.com/events/#{id}/")
end

OFFICIAL_SITE_START_YEAR = 2013

def copyright_year
  start_year = OFFICIAL_SITE_START_YEAR
  this_year = Time.now.year
  if start_year == this_year
    start_year.to_s
  else
    [start_year, this_year].join("-")
  end
end

def link_to_osslab(lab = "松江オープンソースラボ")
  return link_to(lab, "/map/")
end

def link_to_rubyjr(subject = "Ruby.Jr(松江市主催)")
  return link_to(subject, "http://www1.city.matsue.shimane.jp/sangyoushinkou/ruby/rubycity/rubyjr/rubyjr.html")
end

def link_to_doorkeeper(subject, owner, event_id = nil)
  url = "http://#{owner}.doorkeeper.jp/"
  url = File.join(url, "events", event_id.to_s) if event_id
  return link_to(subject, url)
end

def link_to_dojo(subject: "コーダー道場 松江", event_id: nil)
  return link_to_doorkeeper(subject, "smalruby", event_id)
end

def link_to_sproutrb(subject: "スプラウト.rb", event_id: nil)
  return link_to_doorkeeper(subject, "sproutrb", event_id)
end

# http://ja.gravatar.com/site/implement/images/ruby/
def gravatar_image(hash)
  return %Q!<img src="http://www.gravatar.com/avatar/#{hash}" alt="">!
end

def matsuerb_members_list(path = 'resources/members.yml', public_only = true)
  members = YAML.load(File.read(path))
  members.reject! {|m| !m[:public]} if public_only
  return members.collect { |member|
    li_lists = {github: "https://github.com/", twitter: "https://twitter.com/", website: ""}.collect { |sym, url_base|
      url = member[sym]
      (!url.nil? && url != "") ? "<li>#{link_to(sym.to_s, url_base + member[sym])}</li>" : ""
    }.join
    if member[:products] && member[:products].length > 0
      product_lists = '<h4>プロジェクト</h4><div><ul class="links">'
      member[:products].each do |h|
        product_lists += "<li>#{link_to(h[:name], h[:url])}</li>"
      end
      product_lists += "</ul></div>"
    end
    %Q!<div class="wrp test clearfix"><div class="img">#{gravatar_image(member[:gravatar_hash])}</div><div class="text"><h3>#{member[:name]}</h3><p>#{member[:profile]}</p><h4>ウェブサイト</h4><ul class="links">#{li_lists}</ul>#{product_lists}</div></div>\n!
  }.join
end

def generate_calendar
  matsuerb_items = []
  # https://github.com/icalendar/icalendar/
  cal = Icalendar::Calendar.new
  cal.timezone do |t|
    t.tzid = "Asia/Tokyo"
    t.standard do |s|
      s.tzoffsetfrom = "+0900"
      s.tzoffsetto = "+0900"
      s.tzname = "JST"
      s.dtstart = "19700101T000000"
    end
  end

  articles.each do |item|
    # :calendarの内容は考慮していないので注意
    if item[:calendar] != nil
      calendar = item[:calendar]
      start_hour = calendar[:start_time].split(":")[0].to_i
      start_min = calendar[:start_time].split(":")[1].to_i
      end_hour = calendar[:end_time].split(":")[0].to_i
      end_min = calendar[:end_time].split(":")[1].to_i

      event = Icalendar::Event.new
      event.dtstart = DateTime.new(calendar[:year], calendar[:month], calendar[:day], start_hour, start_min)
      event.dtend = DateTime.new(calendar[:year], calendar[:month], calendar[:day], end_hour, end_min)
      event.summary = calendar[:summary]
      event.description = calendar[:description]
      event.location = calendar[:location]
      t = Time.mktime(calendar[:year], calendar[:month], calendar[:day])
      event.uid = t.strftime("%Y%m%dT%H:%M:%S+09:00_00000000@matsuerb")
      cal.add_event(event)
    end
  end
  cal.to_ical
end
