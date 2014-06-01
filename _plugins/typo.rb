class Typography < String
  def to_html
    ar = [] 
    scan(/([^<]*)(<[^>]*>)/) {
      ar << [:text, $1] if $1 != ""
      ar << [:tag, $2] }
    pre = false
    text = ""
    ar.each { |t|
      if t.first == :tag
        text << t[1]
        if t[1] =~ %r!<(/?)(?:pre|code)[\s>]!
          pre = ($1 != "/")
        end
      else
        s = t[1]
        unless pre
          thin = '<span style="white-space:nowrap">&thinsp;</span>'
          s = s.gsub('“', '«&#160;').
                gsub('”', '&#160;»').
                gsub(' ?', thin+'?').
                gsub(' !', thin+'!').
                gsub(' ;', thin+';').
                gsub(' :', '&#160;:').
                gsub(' %', '&#160;%').
                gsub(/(?<=\d)+[ ]/, '&#160;')
        end
        text << s
      end }
    text
  end
end

module Typo
  def typo(text)
    Typography.new(text).to_html
  end
end

Liquid::Template.register_filter Typo

