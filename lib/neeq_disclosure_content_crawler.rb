# coding: UTF-8

require 'net/http'
require 'date'
require 'pdf/reader'
require 'open-uri'
require 'concurrent/executors'
require_relative 'mongodb_init'

class NeeqDiscContentCrawler
  NEEQURI = "http://www.neeq.com.cn"

  def initialize
    @pool = Concurrent::CachedThreadPool.new
  end
    
  def crawl_all
    last_run = LastUpdate.where(job_name: "disclosure_content_crawler").first
    unless last_run
      last_run = LastUpdate.new()
      last_run.job_name = "disclosure_content_crawler"
    end
 
    results = Disclosure.where(:disclosure_content.exists => false).sort(:disclosure_date => 1)
    results.each { |result|
      @pool.post {
        content = get_content(NEEQURI + result.disclosure_link)
        if content
          result.disclosure_content = content
          result.disc_cont_date = Time.now
          result.update
          puts "Successfully saved disclosure #{result._id} #{result.disclosure_date}: #{result.disclosure_title}"
        else
          puts "Failed to get disclosure #{result.disclosure_date}: #{result.disclosure_title}"
        end
      }
      sleep(1)
    }

    last_run.last_runtime = Time.now
    last_run.upsert  
    puts "END neeq-disclosure-content-crawler"
  end
  
  def get_content(link)
    filename = link.split("/").last
    data = ""
    retry_times = 3
    begin
      data = open(link).read
    rescue Exception => e
      puts e.backtrace
      if retry_times > 0
        retry_times -= 1
        retry
      end
      return nil
    end
    return data.force_encoding("GBK").encode("UTF-8") if filename.end_with?("txt")
    return nil unless filename.end_with?("pdf")
    
    # run pdftotext to extract content
    content = ""
    begin
      open("/tmp/#{filename}", 'wb') do |file|
        file.write(data)
      end
      system("pdftotext", "/tmp/#{filename}", "/tmp/#{filename}.txt")
      if File.file?("/tmp/#{filename}.txt")
        open("/tmp/#{filename}.txt") do |file|
          content = file.read
        end
        system("rm", "/tmp/#{filename}.txt")
      end
      system("rm", "/tmp/#{filename}")
    rescue Exception => e
      puts e.backtrace
      return nil
    end
    
    content
  end
end


if __FILE__ == $0
  crawler = NeeqDiscContentCrawler.new
  crawler.crawl_all
end