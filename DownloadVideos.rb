=begin
  Script to download video files, given a list of links in a text file
  Videos are saved in ~/Videos/
  Andres O. Vela
  February 22, 2016
=end

require "open-uri"
require "progressbar"
require "mechanize"
require "io/console"
require "nokogiri"
require "open_uri_redirections"

def find_videos(path)
  videoList = []
  a = []
  line_num=0
  text = File.open(path).read
  text.gsub!(/\r\n?/, "\n")
  text.each_line do |line|
    videoList << line
  end
  videoList
end

def format_video_url(url)
  url.gsub!(/\//,"%2F")
  url.gsub!(/:/,"%3A")
  url
end

def save_video(url,count,total)
  videoURL = format_video_url url
  best_quality_link = ""
  name = ""
  a = Mechanize.new
  a.get("https://www.vededown.com/mainpage.php?page=home&url=#{videoURL}") do |page|
      best_quality = page.links_with(:href => /http:\/\/www.vededown.com\/\?action=dl/).last
      name = page.search('div.vtitle').text
      best_quality_link = best_quality.href
  end
  http_download_with_words(best_quality_link,name,count,total)
end

#This function can download any type of file
def http_download_with_words(url, name, count, total)
  dbar = nil
  uri = URI(url)
  filename = ENV['HOME'] + "/Videos/#{name}.mp4"
  uri.open(
           read_timeout: 500,
           :allow_redirections => :all,
           :content_length_proc => lambda { |t|
           if t && 0 < t
             dbar = ProgressBar.new("Video (#{count}/#{total})", t)
             dbar.file_transfer_mode
           end
           },
           :progress_proc => lambda {|s|
             dbar.set s if dbar
           }
           ) do |file|
    open filename, 'w' do |io|
      file.each_line do |line|
        io.write line
      end
    end
  end
  message = "#{name}.mp4 successfully downloaded."
  twidth = `tput cols`
  puts message + (" " * (twidth.to_i - message.length))
end

def main
  list = find_videos(ENV['HOME'] + "/Desktop/downloadlist.txt")
  puts "Found #{list.length} video(s)."
  if list.length > 0
    unless File.exists?(ENV['HOME'] + "/Videos/")
      Dir.mkdir(ENV['HOME'] + "/Videos/")
      puts "Directory created: ~/Videos/"
    end
    puts "Downloading..."
    i = 0
    total = list.length
    list.each do |video|
      i = i + 1
      save_video(video,i,total)
    end
    puts "End of program."
  end
end

main()