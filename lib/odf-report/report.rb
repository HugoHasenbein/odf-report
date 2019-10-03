module ODFReport

  class Report
    include Images
    
    def initialize(template_name = nil, io: nil)
    
      @template = ODFReport::Template.new(template_name, io: io)
      
      @texts = []
      @fields = []
      @tables = []
      @images = {}
      @image_names_replacements = {}
      @sections = []
      @section_readers = []
      @bookmarks = []
      @bookmark_readers = []
      
      @styles = []
      @list_styles = []
      
      yield(self) if block_given?
      
    end
    
    def add_field(field_tag, value='')
      opts = {:name => field_tag, :value => value}
      field = Field.new(opts)
      @fields << field
    end
    
    def add_text(field_tag, value, opts={})
      opts.merge!(:name => field_tag, :value => value)
      text = Text.new(opts)
      @texts << text
    end
    
    def add_table(table_name, collection, opts={})
      opts.merge!(:name => table_name, :collection => collection)
      tab = Table.new(opts)
      @tables << tab
  
      yield(tab)
    end
    
    def add_section(section_name, collection, opts={})
      opts.merge!(:name => section_name, :collection => collection)
      sec = Section.new(opts)
      @sections << sec
  
      yield(sec)
    end
    
    def add_section_reader(section_name=nil)
      opts={}; opts.merge(:name => section_name) if section_name
      opts.merge!(opts)
      sec = SectionReader.new(opts)
      @section_readers << sec
    end
    
    def add_bookmark_reader(bookmark_name=nil)
      opts={}; opts.merge!(:name => bookmark_name) if bookmark_name
      bmr = BookmarkReader.new(opts)
      @bookmark_readers << bmr
    end
    
    def add_bookmark(bookmark_name, value, opts={})
      opts.merge!(:name => bookmark_name, :value => value)
      bm = Bookmark.new(opts)
      @bookmarks << bm
    end

    def add_image(name, path)
      @images[name] = path
    end
    
    def add_style( *styles )
      styles.each do |style|
        styledef = Style.new( style )
        @styles << styledef
      end
    end
    
    def add_list_style( *list_styles )
      list_styles.each do |list_style|
        listdef = ListStyle.new( list_style )
        @list_styles << listdef
      end
    end
  
    def extract
      results = {}
      @template.get_content do |name, doc|
        key = File.basename(name, File.extname(name)).parameterize.to_sym
        results[key]={}
        results[key][:sections]  = @section_readers.map  { |sr|   sr.get_section_content(doc)  }.inject(:+).to_h
        results[key][:bookmarks] = @bookmark_readers.map { |bmr| bmr.get_bookmark_content(doc) }.inject(:+).to_h
      end
      results
    end 
    
    
    def generate(dest = nil)
    
      @template.update_content do |file|
      
        file.update_files do |doc|
        
          @styles.each      { |s| s.add_style(doc) }
          @list_styles.each { |s| s.add_list_style(doc)  }
          
          @sections.each    { |s| s.replace!(doc)  }
          @tables.each      { |t| t.replace!(doc)  }
          
          @texts.each       { |t| t.replace!(doc)  }
          @fields.each      { |f| f.replace!(doc)  }
          
          @bookmarks.each   { |b| b.replace!(doc)  }
          
          find_image_name_matches(doc)
          avoid_duplicate_image_names(doc)
          
        end
        
        include_image_files(file)
        
      end
      
      if dest
        ::File.open(dest, "wb") {|f| f.write(@template.data) }
      else
        @template.data
      end
      
    end
    
  end
  
end
