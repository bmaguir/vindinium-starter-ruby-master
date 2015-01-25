require 'json'

class ValueFunction
	attr_accessor :mine, :tavern, :kill, :run
	
	def initialize m, t, k, r
		@mine = m
		@tavern = t
		@kill = k
		@run = r
	end
end

class MonteCarlo

	def initialize
		myL = ['d','l','m','h']
		myW = ['l','m','h']
		eL = ['d','l','m','h']
		eD = ['c','m','f', 'v']
		eW = ['l','m','h']
		mD = ['c','m','f', 'v']
		tD = ['c','m','f','v']
		keys = []
		hash = {}
		
		myL.each do |ml|
			myW.each do |mw|
				eL.each do |el|
					eD.each do |ed|
						eW.each do |ew|
							mD.each do |md|
								tD.each do |td|
									str = ml + mw + el + ed + ew + md + td
									puts str
									keys<< str
									hash[str] = [90.0, 106.0, 104.0]
								end
							end
						end
					end
				end
			end
		end
		
		puts "length = " + keys.length.to_s
		
		#puts hash["dldclcc"].mine
		
		myJson = File.open("json.json", "w")
		myJson.write(JSON.pretty_generate(hash))
		myJson.close
		
		jFile = File.read("json.json")
		readJson = JSON.parse(jFile)
		stateHash = {}
#=begin
		myL.each do |ml|
			myW.each do |mw|
				eL.each do |el|
					eD.each do |ed|
						eW.each do |ew|
							mD.each do |md|
								tD.each do |td|
									str = ml + mw + el + ed + ew + md + td
									stateHash[str] =readJson[str]
								end
							end
						end
					end
				end
			end
		end
#=end

	puts stateHash["dldclcc"][0]
	end
	
	def state_of_life life
		case life
		
		when 0..24
			return 'd'
		when 25..49
			return 'l'
		when 50..74
			return 'm'
		when 75..100
			return 'h'
		else
			raise "error, invalid health"
		end
	end
	
	def state_of_enemy_dist dist
		case dist
		when 0..1
			return 'c'
		when 2..3
			return 'm'
		when 4..5
			return 'f'
		when dist > 5
			return 'v'
		else
			raise "invalid enemy dist"
		end
	end
	
	def state_of_dist dist
		case dist
		when 0..3
			return 'c'
		when 4..5
			return 'm'
		when 10..19
			return 'f'
		when dist > 19
			return 'v'
		else
			raise "invalid dist"
		end
	end
	
	def state_of_wealth mine_count, total_mines
		mine_share = mine_count.to_f/total_mines.to_f*100.0
		
		case mine_share
		
		when mine_share < 12.5
			return 'l'
		when mine_share >12.5 && mine_share < 25
			return 'm'
		when mine_share > 25
			return 'h'
		else
			raise "invalid wealth"
		end
	end

end

#MonteCarlo.new