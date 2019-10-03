module ODFReport
  
  class BookmarkReader
    
    attr_accessor :name
    
    def initialize(opts={})
      @name = opts[:name]
    end
    
    def get_bookmark_content( doc )
      #
      # get requested bookmark (if present) or get all bookmarks in document
      #
      names   =   [@name] if @name
      names ||= doc.xpath(".//*[self::text:bookmark or self::text:bookmark-start]").map{|node| node.attr("text:name")}
      result  = []
      
      names.each do |name|
        #
        # get text between single bookmark and paragraph end
        #
        bm = doc.xpath(".//text()[preceding-sibling::text:bookmark[@text:name='#{name}']]")
        result << [name, bm.text] if bm.present?
        
        #
        # get text between bookmark-start and bookmark-end
        #
        bms = "text:bookmark-start[@text:name='#{name}']"
        bme = "text:bookmark-end[@text:name='#{name}']"
        bm = doc.xpath(".//text()[preceding-sibling::#{bms} and following-sibling::#{bme}]")
        result << [name, bm.text]  if bm.present?
        
      end
      result
    end #def
    
   end
  
end
