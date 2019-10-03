module ODFReport
  class Style
  
    def initialize( style )
      @style = style
      @font  = {}
    end #def
    

    def add_style( xml )
    
      ns                                   = xml.collect_namespaces
      automatic_styles                     = xml.at("//office:automatic-styles", ns)
      automatic_styles                     << create_style( xml ) if automatic_styles.present?
      
      if @font.present?
        font_declarations                  = xml.at("//office:font-face-decls", ns)
        font_declarations                  << create_font( xml ) if font_declarations.present?
      end
      
    end #def
    
    private
    
    def create_font( xml )
      node                               = Nokogiri::XML::Node.new('style:font-face', xml)
      node["style:name"]                 = @font[:font_name]
      node["svg:font-family"]            = @font[:font_family]
      node["style:font-family-generic"]  = @font[:font_family_generic]
      node["style:font-pitch"]           = @font[:font_pitch]
      node
    end

    def create_style( xml )
        
      node            = Nokogiri::XML::Node.new('style:style', xml)
      
      #
      # common properties
      #
      case @style
      
        when :bold, :underline, :italic, :strikethrough, :sub, :sup, :code, :a 
          node["style:name"]                                  =@style.to_s
          node["style:family"]                                ="text"
          
          text_properties = Nokogiri::XML::Node.new('style:text-properties', xml)
          node << text_properties
          
        when /h(\d)/i
          node["style:name"]                                  =@style.to_s
          node["style:family"]                                ="paragraph"
          node["style:parent-style-name"]                     ="body"
          node["style:next-style-name"]                       ="subparagraph"
          node["style:default-outline-level"]                 =$1
          
          paragraph_properties = Nokogiri::XML::Node.new('style:paragraph-properties', xml)
          node << paragraph_properties
          
          text_properties = Nokogiri::XML::Node.new('style:text-properties', xml)
          node << text_properties
          
        when :p
          node["style:name"]                                  =@style.to_s
          node["style:family"]                                ="paragraph"
          node["style:parent-style-name"]                     ="body"
          node["style:next-style-name"]                       ="paragraph"
          node["style:default-outline-level"]                 =$1
          
          paragraph_properties = Nokogiri::XML::Node.new('style:paragraph-properties', xml)
          node << paragraph_properties
          
          text_properties = Nokogiri::XML::Node.new('style:text-properties', xml)
          node << text_properties
          
        when :subparagraph
          node["style:name"]                                  =@style.to_s
          node["style:family"]                                ="paragraph"
          node["style:parent-style-name"]                     ="paragraph"
          node["style:next-style-name"]                       ="subparagraph"
          node["style:default-outline-level"]                 =$1
          
          paragraph_properties = Nokogiri::XML::Node.new('style:paragraph-properties', xml)
          node << paragraph_properties
          
          text_properties = Nokogiri::XML::Node.new('style:text-properties', xml)
          node << text_properties

        when :center, :left, :right, :justify
          node["style:name"]                                  =@style.to_s
          node["style:family"]                                ="paragraph"
          node["style:parent-style-name"]                     ="paragraph"
          
          paragraph_properties = Nokogiri::XML::Node.new('style:paragraph-properties', xml)
          node << paragraph_properties
          
        when :quote, :pre
          node["style:name"]                                  =@style.to_s
          node["style:family"]                                ="paragraph"
          node["style:parent-style-name"]                     ="body"
          
          paragraph_properties = Nokogiri::XML::Node.new('style:paragraph-properties', xml)
          node << paragraph_properties
          
          text_properties = Nokogiri::XML::Node.new('style:text-properties', xml)
          node << text_properties
          
        when :table
          node["style:name"]                                  =@style.to_s
          node["style:family"]                                ="table"
          
          table_properties = Nokogiri::XML::Node.new('style:table-properties', xml)
          node << table_properties
          
        when :tr
          node["style:name"]                                  =@style.to_s
          node["style:family"]                                ="table-row"
          
          table_row_properties = Nokogiri::XML::Node.new('style:table-row-properties', xml)
          node << table_row_properties
          
        when :tc
          node["style:name"]                                  =@style.to_s
          node["style:family"]                                ="table-column"
          
          table_column_properties = Nokogiri::XML::Node.new('style:table-column-properties', xml)
          node << table_column_properties
          
        when :td
          node["style:name"]                                  =@style.to_s
          node["style:family"]                                ="table-cell"
          
          table_cell_properties = Nokogiri::XML::Node.new('style:table-cell-properties', xml)
          node << table_cell_properties
      end
      
      #
      # individual properties
      #
      case @style
      
        when :bold
          text_properties["fo:font-weight"]                   ="bold"
          text_properties["fo:font-weight-asian"]             ="bold"
                    
        when :underline
          text_properties["style:text-underline-type"]        ="single"
          text_properties["style:text-underline-style"]       ="solid"
          text_properties["style:text-underline-width"]       ="auto" 
          text_properties["style:text-underline-mode"]        ="continuous" 
                    
        when :italic
          text_properties["fo:font-style"]                    ="italic"
          text_properties["fo:font-style-asian"]              ="italic"
          
        when :strikethrough
          text_properties["style:text-line-through-style"]    ="solid"
          text_properties["style:text-line-through-type"]     ="single"
          
        when /h(\d)/i
          paragraph_properties["fo:text-align"]               ="left"
          paragraph_properties["fo:line-height"]              ="100%"
          paragraph_properties["fo:margin-left"]              ="0cm"
          paragraph_properties["fo:margin-right"]             ="0cm"
          paragraph_properties["fo:keep-with-next"]           ="always"
          paragraph_properties["fo:margin-top"]               ="1.25cm"
          paragraph_properties["fo:margin-right"]             ="0cm"
          paragraph_properties["fo:margin-bottom"]            ="0.5cm"
          paragraph_properties["fo:margin-left"]              ="1.25cm"
          paragraph_properties["fo:text-indent"]              ="-1.25cm"
          paragraph_properties["style:auto-text-indent"]      ="false"

          text_properties["fo:font-weight"]                   ="bold"
          text_properties["fo:font-weight-asian"]             ="bold"
          text_properties["fo:hyphenate"]                     ="true"
          
        when :center, :left, :right, :justify
          paragraph_properties["fo:text-align"]               =@style.to_s
          
        when :quote
          paragraph_properties["fo:text-align"]               ="justify"
          paragraph_properties["fo:line-height"]              ="150%"
          paragraph_properties["fo:margin-top"]               ="0.5cm"
          paragraph_properties["fo:margin-right"]             ="1cm"
          paragraph_properties["fo:margin-bottom"]            ="0.5cm"
          paragraph_properties["fo:margin-left"]              ="1cm"
          
          text_properties["fo:hyphenate"]                     ="true"
          text_properties["fo:font-style"]                    ="italic"
          text_properties["fo:font-style-asian"]              ="italic"
          
        when :pre
          paragraph_properties["fo:text-align"]               ="left"
          paragraph_properties["fo:line-height"]              ="100%"
          paragraph_properties["fo:margin-top"]               ="0.5cm"
          paragraph_properties["fo:margin-right"]             ="1cm"
          paragraph_properties["fo:margin-bottom"]            ="0.5cm"
          paragraph_properties["fo:margin-left"]              ="1cm"
          paragraph_properties["fo:background-color"]         ="transparent"
          paragraph_properties["fo:padding"]                  ="0.05cm"
          paragraph_properties["fo:border"]                   ="0.06pt solid #000000"
          
          text_properties["fo:hyphenate"]                     ="true"
          text_properties["fo:font-style"]                    ="normal"
          text_properties["fo:font-style-asian"]              ="normal"
          text_properties["style:font-name"]                  ="Courier New"
          @font = {
            :font_name           => "Courier New", 
            :font_family         => "'Courier New'", 
            :font_family_generic => "system",
            :font_pitch           => "fixed"
          }

        when :code
          text_properties["style:font-name"]                  ="Courier New"
          @font = {
            :font_name           => "Courier New", 
            :font_family         => "'Courier New'", 
            :font_family_generic => "system",
            :font_pitch           => "fixed"
          }
          
        when :sup
          text_properties["style:text-position"]              ="super 58%"
          
        when :sub
          text_properties["style:text-position"]              ="sub 58%"
          
        when :a
          text_properties["fo:color"]                         ="#0000ff"
          text_properties["style:text-underline-type"]        ="single"
          text_properties["style:text-underline-style"]       ="solid"
          text_properties["style:text-underline-width"]       ="auto" 
          text_properties["style:text-underline-mode"]        ="continuous" 
        
        when :table
          table_properties["style:rel-width"]                 ="100%"
          table_properties["fo:margin-top"]                   ="0.5cm"
          table_properties["fo:margin-right"]                 ="0cm"
          table_properties["fo:margin-bottom"]                ="0.5cm"
          table_properties["fo:margin-left"]                  ="0cm"
          table_properties["fo:text-align"]                   ="left"
          
        when :tr
          # currently, nothing
          
        when :tc
          table_column_properties["style:column-width"]       ="auto"
          
        when :td
          table_cell_properties["style:writing-mode"]         ="lr-tb"
          table_cell_properties["fo:text-align"]              ="left"
          table_cell_properties["fo:border"]                  ="lr-tb"
          table_cell_properties["fo:padding-top"]             ="0.1cm"
          table_cell_properties["fo:padding-right"]           ="0.1cm"
          table_cell_properties["fo:padding-bottom"]          ="0.1cm"
          table_cell_properties["fo:padding-left"]            ="0.1cm"
          table_cell_properties["fo:border"]                  ="0.06pt solid #000000"
          
      end
      
      node
    end #def
    
    
  end
end