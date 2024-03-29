require 'zip'

def unzip_file (file, destination)
  Zip::File.open(file) { |zip_file|
    zip_file.each { |f|
      f_path=File.join(destination, f.name)
      FileUtils.mkdir_p(File.dirname(f_path))
      zip_file.extract(f, f_path) unless File.exist?(f_path)
    }
  }
  begin
    File.delete(file)
  rescue
    puts "#{file} not deleted"
  end
end

def create_sites_list
  sites = []
  Dir.foreach('public/uploads/sites') do |site|
    next if site == '.' or site == '..' or File.extname(site) == '.zip'
    Dir.foreach('public/uploads/sites/'+site) do |item|
      next if item == '.' or item == '..'
      # do work on real items
      if File.extname(item) == '.html'
        sites.push('uploads/sites/' + site + '/' + item)
      end
    end
  end
  sites
end