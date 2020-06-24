# coding: utf-8
require 'net/https'
require 'open-uri'
require 'nokogiri'
require 'json'


config_path = ENV['cpath']
config = JSON.parse(File.read("#{config_path}config.json"))
history = {}

if File.exists?("#{config_path}history.json")
  history = JSON.parse(File.read("#{config_path}history.json"))
end

url = config['url']

charset = nil

html = open(url) do |f|
  charset = f.charset
  f.read
end

scores = []
table = {}
begin
  doc = Nokogiri::HTML.parse(html, nil, charset)
  doc.css('#gm_card .bb-score__item').each do |n|
    fn, sn = n.css('.bb-score__team p').map(&:text)
    fs, _, ss = n.css('.bb-score__status .bb-score__score').map(&:text)
    # 以前取得した情報とおなじなら無視。
    table["#{fn}-#{sn}"] = {fn => fs, sn => ss}
    if history["#{fn}-#{sn}"] && history["#{fn}-#{sn}"][fn] == fs && history["#{fn}-#{sn}"][sn] == ss
      next
    else
      scores << "#{fn} VS #{sn} (#{fs} - #{ss})"
    end
  end
  exit if scores.size.zero?
  data = { "text" => scores.join("\n"), "channel" => config['channel'] }
  uri = URI.parse(config['hook'])
  Net::HTTP.post_form(uri, {"payload" => data.to_json})
  File.open("#{config_path}history.json", 'w'){|f| f.write(table.to_json)}
rescue => e
  p e.backtrace
  p "failed get web page."
end
