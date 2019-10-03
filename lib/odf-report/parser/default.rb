module ODFReport

module Parser


  # Default HTML parser
  #
  # sample HTML
  #
  # <p> first paragraph </p>
  # <p> second <strong>paragraph</strong> </p>
  # <blockquote>
  #     <p> first <em>quote paragraph</em> </p>
  #     <p> first quote paragraph </p>
  #     <p> first quote paragraph </p>
  # </blockquote>
  # <p> third <strong>paragraph</strong> </p>
  #
  # <p style="margin: 100px"> fourth <em>paragraph</em> </p>
  # <p style="margin: 120px"> fifth paragraph </p>
  # <p> sixth <strong>paragraph</strong> </p>
  #

  class Default

    attr_accessor :paragraphs
    
    INLINE     = %w(a span strong b em i ins u del strike sub sup code)
    TEXTINLINE = %w(text:a text:span text:strong text:b text:em text:i text:ins text:u text:del text:strike text:sub text:sup text:code)
    
    def initialize(text, template_node, opts={})
      @text = text
      @paragraphs = []
      @template_node = template_node
      @doc                 = opts[:doc]
      @remove_classes      = opts[:remove_classes]
      @remove_class_prefix = opts[:remove_class_prefix]
      @remove_class_suffix = opts[:remove_class_suffix]
      parse
    end

    def parse
    
      xml = @template_node.parse(@text)
            
      xml.css("h1", "h2", "h3", "h4", "h5", "h6", "p", "pre", "blockquote", "ul", "ol", "table").each do |p|
      
        unless @remove_classes.present? && @remove_classes.include?( p['class'] )
          case p.name
            
            #
            # items, which cannot / should not be nested
            #
            when "h1", "h2", "h3", "h4", "h5", "h6", "p", "pre"
              node  = parse_formatting(p).root
              @paragraphs << node
            #
            # nestable items
            #
            when "ul", "ol" 
              if p.ancestors("ul").length == 0 && p.ancestors("ol").length == 0 # let us do traversing into the nested <ul>
               node  = parse_formatting(p).root
               @paragraphs << node
              end
              
            #
            # tables
            #
            when "table"
              if p.ancestors("table").length == 0 # let us do traversing into the nested <table>
               node  = parse_formatting(p).root
               @paragraphs << node
              end
              
            #
            # , blockquotes
            #
            when "blockquote"
              node  = parse_formatting(p).root
              node.children.each do |child|
              @paragraphs << child
              end
          end
          
        end
        
      end #each
      
    end #def
    
    
    private
    
    def parse_formatting(tag)
    
      html = Nokogiri::XML( tag.to_s.gsub(/\n|\r|\t/, "").strip, @doc )
      
      #
      # remove requested tags with class
      #
      if @remove_classes.present?
        contains = @remove_classes.join(" ")
        nodes = html.xpath(".//*[@class[ contains('#{contains}', .)]]")
        nodes.each { |node| node.remove }
      end
      
      #
      # remove requested class prefixes
      #
      if @remove_class_prefix.present?
        nodes = html.xpath(".//*[@class[ contains(., '#{@remove_class_prefix}')]]")
        nodes.each do |node| 
          css_classes = node.attr("class").split(" ").select{|c| c.present?}
          css_classes.map{ |css_class| css_class.gsub!(/#{@remove_class_prefix}(.*)\z/) { $1 } }
          node.set_attribute("class", css_classes.join(" "))
        end
      end
      
      #
      # remove requested class suffixes
      #
      if @remove_class_suffix.present?
        nodes = html.xpath(".//*[@class[ contains(., '#{@remove_class_suffix}')]]")
        nodes.each do |node| 
          css_classes = node.attr("class").split(" ").select{|c| c.present?}
          css_classes.map{ |css_class| css_class.gsub!(/\A(.*?)#{@remove_class_suffix}/) { $1 } }
          node.set_attribute("class", css_classes.join(" "))
        end
      end
      
      #
      # --- html elements and entities --------------------------------------------------
      #
      
      #
      # newline
      #
      html.xpath("//*[self::br]").each {|node| node.replace(text_node( "line-break")) }
      
      #
      # --- html block elements ---------------------------------------------------------
      #
      
      #
      # headings
      #
      html.xpath("//*[self::h1]").each  {|node| node.replace(text_node( "p", node)) }
      html.xpath("//*[self::h2]").each  {|node| node.replace(text_node( "p", node)) }
      html.xpath("//*[self::h3]").each  {|node| node.replace(text_node( "p", node)) }
      html.xpath("//*[self::h4]").each  {|node| node.replace(text_node( "p", node)) }
      html.xpath("//*[self::h5]").each  {|node| node.replace(text_node( "p", node)) }
      html.xpath("//*[self::h6]").each  {|node| node.replace(text_node( "p", node)) }
      
      #
      # paragraph
      #
      html.xpath("//*[self::p]").each   {|node| node.replace(text_node( "p", node)) }
      
      #
      # pre
      #
      html.xpath("//*[self::pre]").each {|node| node.replace(text_node( "p", node)) }
      
      #
      # --- html inline elements ---------------------------------------------------------
      #
      
      #
      # bold
      #
      html.xpath("//*[self::strong or self::b]").each   {|node| node.replace(text_node( "span", "bold", node)) }
      
      #
      # italic
      #
      html.xpath("//*[self::em or self::i]").each       {|node| node.replace(text_node( "span", "italic", node)) }
      
      #
      # underline
      #
      html.xpath("//*[self::ins or self::u]").each      {|node| node.replace(text_node( "span", "underline", node)) }
      
      #
      # strikethrough
      #
      html.xpath("//*[self::del or self::strike]").each {|node| node.replace(text_node( "span", "strikethrough", node)) }
      
      #
      # superscript and subscript
      #
      html.xpath("//*[self::sup]").each                 {|node| node.replace(text_node( "span", "sup", node)) }
      html.xpath("//*[self::sub]").each                 {|node| node.replace(text_node( "span", "sub", node)) }
      
      #
      # code
      #
      html.xpath("//*[self::code]").each                {|node| node.replace(text_node( "span", "code", node)) }
      
      #
      # hyperlink or anchor or anchor with content
      #
      html.xpath("//*[self::a]").each do |node|
        
        #
        # self closing a-tag: bookmark
        #
        if node.children.blank?
          a = text_node("bookmark")
          a["text:name"]=node['name']
        else
          cont = text_node("span", "a", node)
          a = text_node("a") << cont
          
          if node['href'].present?
            a["xlink:href"]= node['href']
            a["office:target-frame-name"]="_top"
            a["xlink:show"]="replace"
          end
          node.replace(a)
        end
        
      end
      
      #
      # --- html nestable elements -------------------------------------------------------
      #
      
      #
      # nested list items
      #
      html.xpath("//*[self::li]").each do |node|
        
        li = text_node("list-item")
        
        node.xpath("./text()").each do |text|
          text.replace( blank_node("p", "li", text) ) if text.text.present?
          text.remove unless text.text.present?
        end
        
        node.children.each do |child|
          child = child.replace( text_node("p", "li") << child.dup ) if INLINE.include?(child.name)
          child = child.replace( text_node("p", "li") << child.dup ) if TEXTINLINE.include?(child.name)
          li << parse_formatting(child).root
        end
        
        node.replace( li )
      end
      
      #
      # nested unordered lists
      #
      html.xpath("//*[self::ul]").each do |node|
        ul  = text_node("list", "ul", node)
        node.replace( parse_formatting(ul).root )
      end
      
      #
      # nested unordered lists
      #
      html.xpath("//*[self::ol]").each do |node|
        ol  = text_node("list", "ol", node)
        node.replace( parse_formatting(ol).root )
      end
      
      #
      # --- html tables -----------------------------------------------------------------
      #
      
      #
      # table cells
      #
      html.xpath("//*[self::td]").each do |node|
        
        td = table_node("table-cell", "td")
        
        node.xpath("./text()").each do |text|
          text.replace( blank_node("p", "p", text) ) if text.text.present?
          text.remove unless text.text.present?
        end
        
        node.children.each do |child|
          child = child.replace( text_node("p", "p") << child.dup ) if INLINE.include?(child.name)
          child = child.replace( text_node("p", "p") << child.dup ) if TEXTINLINE.include?(child.name)
          td << parse_formatting(child).root
        end
        
        td["table:number-columns-spanned"]=node['colspan'] if node['colspan'].present?
        td["table:number-rows-spanned"]   =node['rowspan'] if node['rowspan'].present?
        
        node.replace( td )
      end
      
      #
      # table rows
      #
      html.xpath("//*[self::tr]").each do |node|
        tr  = table_node("table-row", "tr", node)
        node.replace( parse_formatting(tr).root )
      end
      
      #
      # table tbodies - just unpack
      #
      html.xpath("//*[self::tbody]").each do |node|
        node.parent << node.children
        node.remove
      end

      #
      # tables
      #
      html.xpath("//*[self::table]").each do |node|
        table  = table_node("table", "table", node)
        table["table:template-name"]="Academic"
        new = node.replace( parse_formatting(table).root )
        
        # count maximum number of colums in one row
        max_cols = node.
          xpath("//*[local-name()='table:table-row']").
            map{|tr| tr.xpath("*[local-name()='table:table-cell']")}.
              map{|a| a.length}.max
              
        tc = table_node("table-column", "tc")
        tc["table:number-columns-repeated"] = max_cols
        new.children.first.before( tc )
      end
      
      html
    end #def
    
    
    def blank_node( name, node_or_style=nil, node=nil )
      p  = text_node( name, node_or_style ) 
      p.content = node.text if node
      p
    end
    
    def text_node( name, node_or_style=nil, node=nil )
    
      p  = Nokogiri::XML::Node.new("text:#{name}", @doc)
      
      if node_or_style.blank?
        #nothing
      elsif node_or_style.is_a?(String)
        p['text:style-name']=node_or_style 
        p << node.dup.children if node
      else
        p['text:style-name']=check_style( node_or_style )
        p << node_or_style.dup.children
      end
      p
    end
        
    def table_node( name, node_or_style=nil, node=nil )
    
      p  = Nokogiri::XML::Node.new("table:#{name}", @doc)
      
      if node_or_style.blank?
        #nothing
      elsif node_or_style.is_a?(String)
        p['table:style-name']=node_or_style 
        p << node.dup.children if node
      else
        p['table:style-name']=check_style( node_or_style )
        p << node_or_style.dup.children
      end
      p
    end
    
    def check_style(node)
    
      style = ""
      
      #
      # header… or…
      #
      if node.name =~ /h(\d)/i
        style = node.name.downcase
        
      #
      # …quote… or…
      #
      elsif node.name == "p" && node.parent && node.parent.name == "blockquote"
        style = "quote"
        
      #
      # …pre
      #
      elsif node.name == "pre"
        style = "pre"
        
      #
      # paragraph
      #
      elsif node.name == "p"
        style = "paragraph"
        
      end
      
      #
      #  class overrides header / quote
      #
      if node["class"].present?
      
        style = node["class"]
        style = remove_prefixes(  @remove_class_prefix, style ) if @remove_class_prefix.present?
        style = remove_suffixes(  @remove_class_suffix, style ) if @remove_class_suffix.present?
      end
      
      #
      #  style overrides class
      #
      case node["style"]
        when /text-align:(\s*)center/
          style = "center"
        when /text-align:(\s*)left/
          style = "left"
        when /text-align:(\s*)right/
          style = "right"
        when /text-align:(\s*)justify/
          style = "justify"
      end
      
      style
    end #def
    
    def remove_prefixes( prefix_array, classes_string)
      css_classes = classes_string.split(/\s+/)
      regex_raw = prefix_array.map{ |p| "\\A#{p}(.*?)\\z" }.join("|")
      css_classes.map{ |css_class| (v = css_class.match(/#{regex_raw}/) { $1.to_s + $2.to_s + $3.to_s }; v.present? ? v : css_class) }.join(" ")
    end #def
    
    def remove_suffixes( prefix_array, classes_string)
      css_classes = classes_string.split(/\s+/)
      regex_raw = prefix_array.map{ |p| "\\A(.*?)#{p}\\z" }.join("|")
      css_classes.map{ |css_class| (v = css_class.match(/#{regex_raw}/) { $1.to_s + $2.to_s + $3.to_s }; v.present? ? v : css_class) }.join(" ")
    end #def

  end

end

end
