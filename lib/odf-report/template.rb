module ODFReport
  class Template
    
    #
    # constant - we only work and content and styles (contains headers and footers) parts of odf
    #
    CONTENT_FILES = ['content.xml', 'styles.xml']
    
    attr_accessor :output_stream
    
    #
    # initialize: called on new
    #
    def initialize(template = nil, io: nil)
      raise "You must provide either a filename or an io: string" unless template || io
      raise "Template [#{template}] not found." unless template.nil? || ::File.exist?(template)

      @template = template
      @io = io
    end
    
    
    def get_content(&block)
    
      #
      # open zip file and loop through files in zip file
      #
      get_template_entries.each do |entry|
      
        next if entry.directory?
        
        entry.get_input_stream do |is|
        
          data = is.sysread
          
          if CONTENT_FILES.include?(entry.name)
            yield entry.name, get_content_from_data(data)
          end
          
        end
      end
    end
    
    #
    # update_content: create write buffer for zip 
    #
    def update_content
      @buffer = Zip::OutputStream.write_buffer do |out|
        @output_stream = out
        yield self
      end
    end
    
    #
    # update_files: open and traverse zip directory, pick content.xml 
    #               and styles.xml process and eventually write contents 
    #               to buffer
    #
    def update_files(&block)
    
      get_template_entries.each do |entry|
      
        next if entry.directory?
        
        entry.get_input_stream do |is|
        
          data = is.sysread
          
          if CONTENT_FILES.include?(entry.name)
            process_entry(data, &block)
          end
          
          @output_stream.put_next_entry(entry.name)
          @output_stream.write data
          
        end
      end
    end
    
    #
    # data: just a handle to data in buffer
    # 
    def data
      @buffer.string
    end
    
    private
    
    #
    # get_template_entries: just open zip file or buffer
    # 
    def get_template_entries
    
      if @template
        Zip::File.open(@template)
      else
        Zip::File.open_buffer(@io.force_encoding("ASCII-8BIT"))
      end
    end
    
    #
    # get_content_from_entry: read data from file
    # 
    def get_content_from_data(raw_xml)
      Nokogiri::XML(raw_xml)
    end
    
    #
    # process_entry: provide Nokogiri Object to caller, after having provided a file
    # 
    def process_entry(entry)
      doc = Nokogiri::XML(entry)
      yield doc
      entry.replace(doc.to_xml(save_with: Nokogiri::XML::Node::SaveOptions::AS_XML))
    end
    
  end
end
