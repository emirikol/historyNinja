require 'nokogiri'
require 'ostruct'
require 'json'
require 'treetop'

class Foobar
  attr_accessor :source
  attr_reader   :svg, :parser, :mt
  def initialize(source)
    @source = source
    @mt = nil
    @parser = Treetop.load('foobar.tt').new
  end
  def inspect
    "Foobar<#{source}>"
  end
  def tag_provinces
    @svg=Nokogiri::XML(File.read(src_path('provinces4.svg')))
    
    defs = readlines('definition.csv').map{|d| d.split(';')}
    _ = defs.shift #headings
    defs.map!{|d|  OpenStruct.new(id: d[0], rgb: d[1,3].map(&:to_i) ) }
    # 1;128;34;64;Stockholm
    defs.each do |prov|
      path = svg.css("path[style='fill:#{rgb2hex(prov.rgb)}; stroke:none;']") # path = svg.css("path[fill='#{color}']")
      path.attr('data-province', prov.id) if path.size > 0
    end
    File.write(out_path('provinces3.svg'), svg.to_xml)
  end
  def province_json
    File.open(out_path('provinces.json'), 'w+') do |out|
      out << "{\n"
      Dir.glob(src_path('provinces/*')).each_with_index do |file, i|
        next if File.stat(file).size == 0
        print "\r#{i}"
        prov = parse(file) 
        id, name = file.split('-',2).map{|x|  File.basename(x,'.*').strip }
        hash = {name: name}
        owner = prov['controller']
        hash[:owner] = owner if owner
        out << %Q{"#{id}": #{JSON.dump(hash)},\n}
      end
      out << "\n}"
    end
    puts "\ndone\a"
    # File.write(out_path('provinces.json'), JSON.dump(provinces))
  end
  
  def country_json
    countries = readlines('countries.txt').each_with_object({}) do |country, hash|
      next if country.strip.empty? || country.start_with?('#')
      code, fname = country.split('=').map(&:strip)
      fnamei = Dir::glob(src_path(fname.delete('"')),  File::FNM_CASEFOLD).first 
      lines = self._readlines(fnamei)
      rgb = lines.detect{|c| c.start_with? 'color'}.scan(/\d+/).map(&:to_i)
      
      name = File.basename(fname,'.*').gsub(/([^A-Z])([A-Z][^A-Z])/, '\1 \2').gsub(/\d/, '').strip.split(' ').map(&:capitalize).join(' ').
        sub(/ The /, ' the ').
        sub(/ And /, ' and ').
        sub(/ofthe/, ' of the').
        sub(/ Of /, ' of ')
      
      hash[code] = {color: "rgb(#{rgb.join(',')})", name: name}
    end
    File.write(out_path('countries.json'), JSON.dump(countries))
  end
  
  def gen_country_history()
    countries = JSON.parse(File.read(out_path('countries.json')))
    country_cache = JSON.parse(File.read(out_path('countries.json')))
    res = Dir.glob(src_path('country_history/*')).each_with_object([]) do |file, arr|
      next if File.stat(file).size == 0
      code = File.basename(file).split('-')[0].strip.upcase
      parse(file).each do |key, val|
        countries[code]['gov'] = val.gsub('_', ' ') if key == 'government'
        country_cache[code]['gov'] = countries[code]['gov']
        next unless key =~ /^\d+\.\d\d?\.\d\d?/
        if val['monarch']
          mon = val['monarch']['name'].strip
          arr << {time: key_to_time(key), code: code, monarch: [mon, country_cache[code]['monarch']]} 
          country_cache[code]['monarch'] = mon
        end
        if val['government']
          gov = val['government'].strip.gsub('_', ' ')
          arr << {time: key_to_time(key), code: code, gov: [gov, country_cache[code]['gov']]}
          country_cache[code]['gov'] = gov
        end
        
      end
    end
    File.write(out_path('countries.json'), JSON.dump(countries))
    res
  end
  
  def gen_province_history()
    provinces = JSON.parse(File.read(out_path('provinces.json')))
    history = Dir.glob(src_path('provinces/*')).each_with_object([]) do |file, arr|
      next if File.stat(file).size == 0
      id = file.scan(/\d+/)[0]
      puts id 
      parse(file).each do |key, val|
        next unless key =~ /^\d+\.\d\d?\.\d\d?/
        new_owner = val['controller']
        new_owner =  provinces[id]['owner'] if new_owner.nil? && provinces[id]['controller'] == 'REB' && val['revolt'] == 'null' #owner get back province if revolt goes away
        next unless new_owner 
        
        time = key_to_time(key)
        arr << {time: time, id: [id], owner: new_owner, pre_owner: provinces[id]['controller'] || provinces[id]['owner']}
        provinces[id]['controller'] = new_owner
        provinces[id]['owner'] = val['owner'] if val['owner']
      end
    end
    history.sort_by!{|h| [h[:time] , h[:owner] || '0', h[:pre_owner]  || '0']  }
    zipped = [{}]
    history.each do |event|
      if zipped[-1].values_at(:date, :owner, :pre_owner) == event.values_at(:date, :owner, :pre_owner)
        zipped[-1][:id] << event[:id][0]
      else
        zipped << event
      end
    end
    zipped.shift
    zipped
  end
  
  def write_history(history)
    File.write(out_path('zipped_history.json'), JSON.dump(history.sort_by{|i|i[:time] || i['time']}))
  end
  
  def history_json
    write_history(gen_country_history.concat(gen_province_history))
  end
  
  def key_to_time(key)
    year,month,day = key.split('.').map(&:to_i)
    year*372+(month-1)*31+day
  end
  def readlines(path)
    self._readlines(src_path(path))
  end
  def _readlines(path)
    File.readlines(path, encoding: 'iso-8859-1').map{|p|p.chomp.encode('utf-8')}
  end
  def parse(path)
    @mt = path
    self.parser.parse(File.read(path, encoding: 'Windows-1251').encode('utf-8').gsub('{}', 'null ')).foo
  end
  def src_path(path)
    File.join('src',@source, path)
  end
  def out_path(path)
    File.join(@source, path)
  end
  
  def rgb2hex(rgb)
    rgb.each_with_object('#') {|c,s| s << c.to_s(16).rjust(2,'0')}
  end
  
end

class FooNode < Treetop::Runtime::SyntaxNode
end

#x= Encoding.list.map {|e| [e, File.readlines('provinces/826 - Choco.txt', encoding: e)[17].encode('utf-8')] rescue nil   };1          
#x.compact.select{|s| s[1] =~ /"[[:word:] ]+"/ rescue nil}.map {|s| s[0].to_s}
# encodings_141 = ["Windows-31J", "Big5-HKSCS", "Big5-UAO", "CP949", "GB18030", "GBK", "Shift_JIS", "Windows-1251", "IBM437", "IBM737", "IBM775", "CP850", "IBM852", "CP852", "IBM855", "CP855", "IBM857", "IBM860", "IBM861", "IBM862", "IBM863", "IBM865", "IBM866", "macCroatian", "macCyrillic", "macGreek", "macIceland", "macRoman", "macRomania", "macTurkish", "macUkraine", "CP951", "Windows-1252", "Windows-1250", "Windows-1256", "Windows-1254", "SJIS-DoCoMo", "SJIS-KDDI", "SJIS-SoftBank"]
# encodings_826 = ["Big5", "Big5-HKSCS", "Big5-UAO", "CP949", "GB18030", "GBK", "ISO-8859-4", "ISO-8859-5", "ISO-8859-14", "ISO-8859-16", "Windows-1251", "macCroatian", "macCyrillic", "macGreek", "macIceland", "macRoman", "macRomania", "macTurkish", "macUkraine", "CP950", "CP951"]
# encodings =     ["Big5-HKSCS", "Big5-UAO", "CP949", "GB18030", "GBK", "Windows-1251", "macCroatian", "macCyrillic", "macGreek", "macIceland", "macRoman", "macRomania", "macTurkish", "macUkraine", "CP951"]