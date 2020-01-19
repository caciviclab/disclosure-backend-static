require "selenium-webdriver" # load in the webdriver gem to interact with Selenium
include Selenium::WebDriver::Support


# create a driver object
# options = Selenium::WebDriver::Chrome::Options.new
# options.add_argument('--headless')
# driver = Selenium::WebDriver.for :chrome, options: options
driver = Selenium::WebDriver.for :chrome

# navigate to the City of San Diego Public Portal for Campaign Finance Disclosure
driver.navigate.to "https://public.netfile.com/pub2/?aid=CSD"

# find the year select element and select 2020
select_year_element = driver.find_element(id: 'ctl00_phBody_DateSelect')
select_year_element.click
year2019 = driver.find_element(xpath: '//*[@id="ctl00_phBody_DateSelect"]/option[1]')
year2019.click

# find the Export All link and click it
export_all_link = driver.find_element(id: 'ctl00_phBody_GetExcel')
export_all_link.click

wait = Selenium::WebDriver::Wait.new(:timeout => 10)
wait.until { 
  download_file = ENV['HOME'] + '/Downloads/2020_CSD.zip'
  File.exist?(download_file)
}

driver.quit
