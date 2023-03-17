#! /usr/bin/ruby -w

# basically remove html entities, and the TEIform attribut that emacs would stick
# to all elements 
require 'nokogiri'

file2read = ARGV[0]  #|| 'tei/orig/creanga-amintiri.xml' 

# bac = File.read('tei/orig/bacovia-plumb.xml')
# creanga = File.read('tei/orig/creanga-amintiri.xml')
cnt = File.read(file2read)
xml = Nokogiri::XML(cnt) do |config|
    config.noent.strict.noblanks
end
xml.xpath("//*[@TEIform]").each do |n|
    teiform_attr = n.attribute('TEIform')
    # puts teiform_attr
    if teiform_attr then
        teiform_attr.remove()
    end
end

xml.xpath("//text()").each do |t|
    t.content = t.content.strip
end
puts xml.to_xml(:indent => 2, :encoding => 'utf-8')
