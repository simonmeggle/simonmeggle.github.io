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

  def englishdate(date)
    date = date.gsub('01 ', '1<sup>th</sup> ')
    date = date.gsub('02 ', '2<sup>nd</sup> ')
    date = date.gsub('03 ', '3<sup>rd</sup> ')
    date = date.gsub('04 ', '4 ')
    date = date.gsub('05 ', '5 ')
    date = date.gsub('06 ', '6 ')
    date = date.gsub('07 ', '7 ')
    date = date.gsub('08 ', '8 ')
    date = date.gsub('09 ', '9 ')
  end

  def frenchdate(date)
    date = date.gsub('01 ', '1<sup>er</sup> ')
    date = date.gsub('02 ', '2 ')
    date = date.gsub('03 ', '3 ')
    date = date.gsub('04 ', '4 ')
    date = date.gsub('05 ', '5 ')
    date = date.gsub('06 ', '6 ')
    date = date.gsub('07 ', '7 ')
    date = date.gsub('08 ', '8 ')
    date = date.gsub('09 ', '9 ')    
    date = date.gsub('January',  'janvier')
    date = date.gsub('February', 'février')
    date = date.gsub('March',    'mars')
    date = date.gsub('April',    'avril')
    date = date.gsub('May',      'mai')
    date = date.gsub('June',     'juin')
    date = date.gsub('July',     'juillet')
    date = date.gsub('August',   'août')
    date = date.gsub('September','septembre')
    date = date.gsub('October',  'octobre')
    date = date.gsub('November', 'novembre')
    date = date.gsub('December', 'décembre')
  end
end

Liquid::Template.register_filter Typo

