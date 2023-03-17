#! /usr/bin/ruby -w

# replace all styles that have parent lg with lg for better processing with the
# tei stylesheets

# represents an oo style elem
class OOStyle

    def initialize(name, xml_elem, parent = null)
        @name = name
        @xml_elem = xml_elem
        @parent = parent
    end

    # is_style_or_child_of_style('lg') returns true if 
    # 'this' is actually named 'lg', or if any of the parents (ancestors) is named 'lg'
    def is_style_or_child_of_style(stylename)
        return (
            stylename == @name || (@parent && @parent.is_style_or_child_of_style(stylename))
        )
    end

    # returns true only if this is a descendent of 'stylename'
    # returns false if 'this' is actually named 'stylename'
    # useful to detect the 'impostors', aka automatically generated descendants
    def is_child_of_style(stylename)
        return stylename != @name && @parent && @parent.is_style_or_child_of_style(stylename)
    end

    def to_s 
        if @parent then
            @name + " -> " + @parent.to_s
        else
            @name
        end
    end
    
end

class FodtStyleReplacer 
    attr_reader :xml
    attr_reader :replacements_counter

    FODT_NAMESPACES = {
        "office" => "urn:oasis:names:tc:opendocument:xmlns:office:1.0",
        "style"  => "urn:oasis:names:tc:opendocument:xmlns:style:1.0",
        "text"   => "urn:oasis:names:tc:opendocument:xmlns:text:1.0" ,
        "table"  => "urn:oasis:names:tc:opendocument:xmlns:table:1.0",
        "draw"   => "urn:oasis:names:tc:opendocument:xmlns:drawing:1.0",
        "fo" => "urn:oasis:names:tc:opendocument:xmlns:xsl-fo-compatible:1.0",
        "xlink" => "http://www.w3.org/1999/xlink" ,
        "dc" => "http://purl.org/dc/elements/1.1/" ,
        "meta"=> "urn:oasis:names:tc:opendocument:xmlns:meta:1.0",
        "number"=>"urn:oasis:names:tc:opendocument:xmlns:datastyle:1.0" ,
        'svg'=>"urn:oasis:names:tc:opendocument:xmlns:svg-compatible:1.0" ,
        'chart'=>"urn:oasis:names:tc:opendocument:xmlns:chart:1.0" ,
        'dr3d'=>"urn:oasis:names:tc:opendocument:xmlns:dr3d:1.0" ,
        'math'=>"http://www.w3.org/1998/Math/MathML" ,
        'form'=>"urn:oasis:names:tc:opendocument:xmlns:form:1.0" ,
        'script'=>"urn:oasis:names:tc:opendocument:xmlns:script:1.0" ,
        'config'=>"urn:oasis:names:tc:opendocument:xmlns:config:1.0", 
        'ooo'=>"http://openoffice.org/2004/office" ,
        'ooow'=>"http://openoffice.org/2004/writer" ,
        'oooc'=>"http://openoffice.org/2004/calc", 
        'dom'=>"http://www.w3.org/2001/xml-events",
        'xforms'=>"http://www.w3.org/2002/xforms",
        'xsd'=>"http://www.w3.org/2001/XMLSchema",
        'xsi'=>"http://www.w3.org/2001/XMLSchema-instance" ,
        'rpt'=>"http://openoffice.org/2005/report" ,
    }

    def initialize(xmlcontent)
        require 'nokogiri'
        @xml = Nokogiri::XML(xmlcontent)

        # fodt style hierarchy
        @styles = {}

        _office_styles = @xml.xpath("/office:document/office:styles/style:style", FODT_NAMESPACES)

        raise unless _office_styles && _office_styles.length > 1
        _automatic_styles = @xml.xpath('/office:document/office:automatic-styles/style:style', FODT_NAMESPACES)
        raise unless _automatic_styles && _automatic_styles.length > 0

        (_office_styles + _automatic_styles).each do |it|
            name = it['style:name']
            # displayName = it['style:display-name']
            parent_name = it['style:parent-style-name']
            parent_oostyle = (@styles[parent_name] if parent_name)

            oostyle = OOStyle.new(name, it, parent_oostyle)
            @styles[name] = oostyle
        end

        # @styles.values.each { |it| 
        #     s = it.to_s
        #     s = "*lg " + s if it.is_style_or_child_of_style('lg')
        #     s = "*Author " + s if it.is_style_or_child_of_style('Author')
        #     s = "*Title " + s if it.is_style_or_child_of_style('Title')
        #     STDERR.puts s
        # }

    end

    # libreoffice sometimes replaces in the doc xml the displayed styles (like 'lg', 'Author')
    # 'Title' etc, by automatically generated styles, which do descend from the displayed style.
    #
    # This makes it hard for tei stylesheets to realize that a given p is marked as an lg, for example.
    #
    # This method replaces the automatically generated styles by their properly named parents.
    def replace_automated_styles

        # this are the 'problem' styles (that soemtimes get replaced)
        handnamed_stylenames = ['lg', 'Author','Title', 
            'Subtitle', 'Epigraph', 'Trailer',
            'License', 'DocumentLanguage', 'SourceDesc',
            'Quote', 'Quotations', 'Quotation'
        ]

        paras = @xml.xpath('/office:document/office:body/office:text/text:p', FODT_NAMESPACES)
        raise unless paras && paras.length > 0 # non-empty doc

        @replacements_counter = 0
        paras.each do |p|
            style_name = p['text:style-name']
            oostyle = @styles[style_name]
            raise unless oostyle # we should have registered that style correctly

            automatically_generated_descendant_style =  
                handnamed_stylenames.select { |it| oostyle.is_child_of_style(it) };

            raise "style #{oostyle} of paragraph #{p} has more than one parents #{automatically_generated_descendant_style}, expected exactly one" if automatically_generated_descendant_style.length > 1;

            if automatically_generated_descendant_style.length > 0 then
                @replacements_counter = @replacements_counter + 1
                sty = automatically_generated_descendant_style.first
                # STDERR.puts style_name + " - " + sty.to_s + " -> " + p.text[0..50]
                p['text:style-name'] = sty
            end
        end
        STDERR.puts "replaced #{@replacements_counter} (out of #{paras.length}) paragraphs with automatically generated styles"
    end

end

if __FILE__==$0
    file = ARGV[0]
    raise "file argument required" unless file
    raise "file '#{file}' does not exist " unless File.exist?(file)
    replacer = File.open(file) { |f|  FodtStyleReplacer.new(f)}
    replacer.replace_automated_styles

    if (ARGV.length > 1) then
        outfile = ARGV[1]
        File.write(outfile, replacer.xml)
    else
        puts replacer.xml
    end
end
  