module ODFReport
  
  class SectionReader
    
    attr_accessor :name
    
    def initialize(opts)
      @name = opts[:name]
    end
    
    def get_section_content( doc )
      #
      # get requested bookmark (if present) or get all bookmarks in document
      #
      names   =   [@name] if @name
      names ||= doc.xpath(".//text:section").map{|node| node.attr("text:name")}
      result  = []
      
      names.each do |name|
        #
        # get text in sections
        #
        section = doc.xpath(".//text:section[@text:name='#{name}']")
        result << [name, section.text] if section.present?
        
      end
      
      result
    end #def
    
  end
  
end
