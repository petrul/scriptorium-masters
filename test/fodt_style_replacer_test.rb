require "test/unit"
require_relative "../lib/fodt_style_replacer"

# test for FodtStyleReplacer
class TestFodtStyleReplacer < Test::Unit::TestCase
    def test_replace_styles_fodt
        thisdir = File.dirname(__FILE__)
        
        replacer = File.open(thisdir + '/resources/Cosbuc,G-Poezii.fodt') { |f| FodtStyleReplacer.new(f)} 
        replacer.replace_automated_styles()

        assert replacer.replacements_counter > 0
        result = replacer.xml.to_s

        replacer2 = FodtStyleReplacer.new(result)
        replacer2.replace_automated_styles()

        assert replacer2.replacements_counter == 0
    end
end