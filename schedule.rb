require 'open-uri'
require 'thread/pool'

def schedule(ccn, stats)
	numbers = []
	nums = []

	doc = open('https://telebears.berkeley.edu/enrollment-osoc/osc?_InField1=RESTRIC&_InField2=' + ccn + '&_InField3=13B4')
	doc.each_line do |line|
		if line.include?('limit')
			a = line.scan(Regexp.new(/([0-9]+)/))
			nums += a[0] + a[1]
		end
	end

	nums += ['0']*4
	enrolled, limit, wait_list, wait_limit = nums
	stats[ccn] = (enrolled + '/' + limit), (wait_list + '/' + wait_limit)
end


def main()
	dept = ARGV.slice(0..-2).join('+')
	num = ARGV.last
	
	class_url = 'https://osoc.berkeley.edu/OSOC/osoc?y=0&p_term=SP&p_deptname=--+Choose+a+Department+Name+--&p_classif=--+Choose+a+Course+Classification+--&p_presuf=--+Choose+a+Course+Prefix%2fSuffix+--&p_course=' + num + '&p_dept=' + dept + '&x=0'
	doc = open(class_url).read
	ccn_regex = Regexp.new(/input type="hidden" name="_InField2" value="([0-9]*)"/)
	ccns = []
	doc.scan(ccn_regex).each do |ccn|
		ccns << ccn[0]
	end

	stats = Hash.new
	pool = Thread::Pool.new(15)
	ccns.each do |lookup_ccn|
		pool.process {
			schedule(lookup_ccn, stats)
		}
	end
	pool.shutdown

	data = []
	doc.each_line do |line|
		if line.include?(':&#160;')
			raw = line.scan(Regexp.new(/>([^<]+)/))
			data << raw[1][0].strip().split(':&#160;')[0]
		end
	end

	# sections contains a list per section:
	# [course, coursetitle, location, instructor, status, ccn, units, 
	#  finalgroup, restrictions, note]

	puts ['Section', 'Enrolled', 'Waitlist'].map{|x| x.ljust(10)}.join('')
	data.each_slice(11).zip(ccns).each do |section, lookup_ccn|
		name = section[0].split(' ')[-2,2].join(' ')
		e, w = stats[lookup_ccn]
		puts [name, e, w].map{|x| x.ljust(10)}.join('')
	end
end

if __FILE__ == 'schedule.rb'
	main()
end


