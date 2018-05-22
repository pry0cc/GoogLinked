#!/usr/bin/env ruby

require 'rubygems'
require 'nokogiri'
require 'mechanize'


class GoogLinked
	def initialize(companyname, domain)
		@agent = Mechanize.new()
		@agent.user_agent = "Mozilla/5.0 (Windows; U; Windows NT 6.0;en-US; rv:1.9.2 Gecko/20100115 Firefox/4.6"
		@companyname = companyname
		@domain = domain
		@proxies = get_proxies()
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
			tarr = title.split("-")[0].split("|")[0].split(" ")
			emails.push(tarr[0].downcase+"."+tarr[-1].downcase+"@"+@domain)
		end

		puts emails

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
				randomize_proxy()
				results = @agent.get("https://www.google.co.uk/search?num=100&start=#{page*100}&hl=en&q=site:linkedin.com/in+#{companyname.gsub! " " "+"}").body()
			rescue
				search_failed = true
			else
				search_failed = false
				return results
			end
		end
	end

	def randomize_proxy()
		check_failed = true
		proxy = []
		while(check_failed) do
			begin
				Timeout::timeout(5) {
					# puts "Trying new proxy. " + @proxies.length.to_s + " proxies left."
					# print "+"
					proxy = @proxies.sample
					ua = @useragents.sample
					@agent.set_proxy(proxy[0], proxy[1])
					@agent.user_agent = ua
					ip = @agent.get("http://icanhazip.com").body().chomp
					if ip != proxy[0]
						break
					end
				}
			rescue
				check_failed = true
				# puts "Proxy Failed - removing from list"
				# print "-"
				@proxies.delete(proxy)
			else
				check_failed = false
				# puts "Proxy worked!"
			end
		end
	end

	def get_proxies()
		results = []
		host = "127.0.0.1"
		ports = 5001..5045

		ports.each do |port|
			results.push([host, port])
		end

		return results
	end

end


searcher = GoogLinked.new("Microsoft", "microsoft.com")
searcher.run_search()


