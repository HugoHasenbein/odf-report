module ODFReport

  class Bookmark < Field
    
    def replace!(doc, data_item = nil)
    
      nodes = find_bookmark_nodes(doc)
      return if nodes.blank?
      
      value = sanitize( get_value(data_item) )
      text_node = Nokogiri::XML::Text.new(value, doc)
      
      nodes.each do |node|
      
        case node[0].name
        
          when "bookmark"
            node.after(text_node)
            
          when "bookmark-start"
            #
            # get text between bookmark-start and bookmark-end
            #
            bms = "text:bookmark-start[@text:name='#{@name}']"
            bme = "text:bookmark-end[@text:name='#{@name}']"
            bm = doc.xpath(".//text()[preceding-sibling::#{bms} and following-sibling::#{bme}]")
            # delete content
            bm.each {|b| b.remove }
            # and add content
            node.after(text_node)
            
        end
        
      end #each
      
    end

    private

    def find_bookmark_nodes(doc)
    
      result = []
      
      #
      # get simple and enclosing bookmark nodes
      #
      bm = doc.xpath(".//*[self::text:bookmark[@text:name='#{@name}'] or self::text:bookmark-start[@text:name='#{@name}']]")
      result << bm if bm.present?
      
      result
      
    end #def

  end

end
