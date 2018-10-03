#!/usr/bin/env ruby

require 'rubygems'
require 'nokogiri'
require 'mechanize'
require 'optparse'

class String
	def is_upper?
		self == self.upcase
	end
	def is_lower?
		self == self.downcase
	end
end


class GoogLinked
	def initialize(companyname, domain)
		@agent = Mechanize.new()
		@agent.user_agent = "Mozilla/5.0 (Windows; U; Windows NT 6.0;en-US; rv:1.9.2 Gecko/20100115 Firefox/4.6"
		@companyname = companyname
		@domain = domain
		@useragents = [
			"Mozilla/5.0 (Windows; U; Windows NT 6.0;en-US; rv:1.9.2 Gecko/20100115 Firefox/3.6",
			"Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/41.0.2227.0 Safari/537.36",
			"Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/41.0.2227.0 Safari/537.36",
			"Mozilla/5.0 (Windows NT 10.0) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/40.0.2214.93 Safari/537.36",
			"Mozilla/5.0 (Windows NT 5.1; rv:31.0) Gecko/20100101 Firefox/31.0"
		]

	end
	
	def run_search()
		init = search(@companyname, 0)
		pages = get_pages(init)
		results = ""
		names = []
		
		(0..pages).each do |pagen|
			# puts "Seaching #{pagen}"
			results += search(@companyname, pagen)
	
			Nokogiri::HTML(results).css(".r").css("a").each do |name|
				names.push(name.text)
			end
		end

		emails = []

		names.each do |title|
			tarr = title.split("-")[0].split("|")[0].split(",")[0].split(" ")
				if tarr.length > 2
					if tarr[2].length >= 2
						if tarr[2][0].is_upper? and tarr[2][1].is_upper?
							tarr.delete_at(2)
						end
					end
				end
			emails.push(tarr[0].downcase+"."+tarr[-1].downcase+"@"+@domain)
		end

        return emails
	end

	def get_pages(init)
		pages = []

		Nokogiri::HTML(init).css(".fl").css("a").each do |page|
			pages.push(page.text)
		end

		return pages[-2].to_i - 2
	end

	def search(companyname, page)
		search_failed = true
		while(search_failed) do
			begin
				randomize_useragent()
				results = @agent.get("https://www.google.co.uk/search?num=100&start=#{page*100}&hl=en&q=site:linkedin.com/in+#{companyname.gsub! " " "+"}").body()
			rescue
				search_failed = true
			else
				search_failed = false
				return results
			end
		end
	end

	def randomize_useragent()
		ua = @useragents.sample
		@agent.user_agent = ua
	end
end


options = {}
optparse = OptionParser.new do|opts|
  # Set a banner, displayed at the top
  # of the help screen.
  opts.banner = "Usage: optparse1.rb [options] file1 file2 ..."
  # Define the options, and what they do
  options[:output] = nil
  opts.on( '-o', '--output FILE', 'Write emails to FILE' ) do|file|
    options[:output] = file
  end
  opts.on('-d', '--domain DOMAIN', 'Domain to search for') do |domain|
    options[:domain] = domain
  end
  opts.on('-c', '--company COMPANY NAME LLC', 'Company name to search for') do |companyname|
    options[:companyname] = companyname
  end
  # This displays the help screen, all programs are
  # assumed to have this option.
  opts.on( '-h', '--help', 'Display this screen' ) do
    puts opts
    exit
  end
end

optparse.parse!

if options[:companyname] != nil and options[:domain] != nil
  puts "[+] Beginning search..."
  searcher = GoogLinked.new(options[:companyname], options[:domain])
  output = searcher.run_search()
  puts "[*] Search complete!"
  if options[:output] != nil
    filename = options[:output]
    out = File.open(filename, "w")
    output.each do |email|
      out.puts email+"\n"
    end
    puts "[+] Emails for #{options[:companyname]} saved to #{filename}"
  else
    puts output
  end
end

