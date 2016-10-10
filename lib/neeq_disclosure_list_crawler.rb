# coding: UTF-8

require 'net/http'
require 'date'
require 'pdf/reader'
require 'open-uri'
require_relative 'mongodb_init'

class NeeqDiscListCrawler
  
  def crawl_all
    today = Date.today
    startDate = Date.new(2006, 1, 1)

    last_run = LastUpdate.where(job_name: "disclosure_crawler").first
    if last_run
      startDate = last_run.last_data["endDate"].to_date 
    else
      last_run = LastUpdate.new()
      last_run.job_name = "disclosure_crawler"
    end
 
    while startDate < today 
      endDate = startDate + 1
      crawl_disclosure(startDate, endDate)
      startDate = endDate + 1
      
      last_run.last_runtime = Time.now
      if endDate < today
        last_run.last_data = {:endDate => endDate}
      else
        last_run.last_data = {:endDate => today}
      end
      last_run.upsert
    end
    
    puts "END neeq-disclosure-list-crawler"
  end
  
  def crawl_disclosure(startDate, endDate)
    puts "Crawling disclosure from #{startDate} to #{endDate}"
    page = 0
    is_last_page = false
    while !is_last_page
      result = get_disc_list(startDate, endDate, page)
      total_result, count, is_last_page = eval(result.force_encoding('UTF-8'))
      puts "Parsed page #{page}, total #{total_result} result(s), saved #{count} disclosure(s)."
      page += 1
      sleep(1)
    end
  end
  
  def get_disc_list(startDate, endDate, page)
    retry_times = 3
    begin
        uri = URI('http://www.neeq.com.cn/disclosureInfoController/infoResult.do?callback=parse')
        form = {'disclosureType' => '5', 'page' => page, 'isNewThree' => '1', 
                'startTime' => startDate, 'endTime' => endDate}
        res = Net::HTTP.post_form(uri, form)
        if !res.body.start_with?("parse")
          puts res.body
          raise Exception.new("Failed to get data from neeq.com.cn")
        end
      rescue Exception => e
        if retry_times > 0
          puts e.backtrace
          retry_times -= 1
          retry
        end
        raise e
      end
      result = res.body.gsub('null', 'nil')
      result
  end
  
  # Parse the returned data from neeq disclosure list api
  def parse(result)
    count = 0
    for disc in result[0][:listInfo][:content]
      begin
      d = Disclosure.new()
      d.company_code = disc[:companyCd]
      d.company_name = disc[:companyName]
      d.disclosure_date = disc[:publishDate]
      d.disclosure_title = disc[:disclosureTitle]
      d.disclosure_link = disc[:destFilePath]
      d.save
      count += 1
      rescue Exception => e
        raise if !e.message.start_with?("E11000")
      end  
    end 
    
    is_last_page = result[0][:listInfo][:lastPage].to_s == "true"
    total_result = result[0][:listInfo][:totalElements]
    return [total_result, count, is_last_page]
  end
end

if __FILE__ == $0
  crawler = NeeqDiscListCrawler.new
  crawler.crawl_all
end