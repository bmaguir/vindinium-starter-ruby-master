
class MyBot < BaseBot

attr_accessor :hashTable
	
	def initialize hashTable
		@hashTable = hashTable
		@path = Array.new
		@position = [0,0]
		@hero_no = "1"
		@life = 100
		@healing = false 
		@curr_state = nil
		@episode_array = []
		@greed = 0.1
	end

  def move state  

	start_time = Time.now.to_f
  
	@hero_no = state["hero"]["id"].to_s
	@life =  state["hero"]["life"]
	@mineCount = state['hero']['mineCount']
	if @life >= 95
		@healing = false
	end
	
	if @curr_state == nil
		@curr_state = Game.new(state)
		@prev_state = @curr_state
	else
		@prev_state = @curr_state
		@curr_state = Game.new(state)
	end
	
	#has episode ended
	case 
	when mine_captured?
		puts "captured mine "
		ep_end = "mine"
		calculate_rewards ep_end
	when got_health?
		puts "got health"
		ep_end = "tavern"
		calculate_rewards ep_end
	when hero_died?
		puts "I died"
		ep_end = "died"
		calculate_rewards ep_end
#	when enemy_died?
#		calculate_rewards ep_end
#		ep_end = "kill"
	end
	
    @game = Game.new state
	
	#switch x and y values 
	@position = [ @game.heroes_locs[@hero_no][1], @game.heroes_locs[@hero_no][0]]
	
	@threads = []
	
	@mp = state['game']['board']['tiles']		#get map and line size from state
	@sz = state['game']['board']['size']
	@sz = @sz*2									#size*2 for double chars in map
	@new_map = ""
	(0..@mp.length - 1).step(@sz).each do |i|		#add \n to get split in find path
		@new_map << @mp[i..i+(@sz-1)].to_s + "\n"
	end
	
	path_cost = Path_Cost.new(@life, @mineCount, @game.mines_locs.length, @sz, @hero_no)
	
	#get distance and paths to taverns
	tavern_paths = []
	tavern_paths = find_tavern
	closest_tavern = tavern_paths[0]
	min = tavern_paths[0].length
	tavern_paths.each do |tp|
		if tp.length<min
			min = tp.length
			closest_tavern = tp
		end
	end

	#get distance and paths to mines
	mine_paths = []
	mine_paths = find_mine
	closest_mine = mine_paths[0]
	min = mine_paths[0].length
	mine_paths.each do |mp|
		if mp.length < min
			min = mp.length
			closest_mine = mp
		end
	end
	
	enemies =[]
	enemies = find_flanders
	closest_enemy = find_flanders[0]
	min = closest_enemy.length
	enemy_index =0
	enemies.each_with_index do |e, i|
		if e.length< min
			min = e.length
			closest_enemy = e
			enemy_index = i
		end
	end
	
	myL = state_of_life @life
	myW = state_of_wealth @mine_count, @curr_state.mines_locs.length
	eL = state_of_life l =  state["game"]["heroes"][enemy_index]["life"]
	eW = state_of_wealth state["game"]["heroes"][enemy_index]["mineCount"], @curr_state.mines_locs.length
	eD = state_of_enemy_dist closest_enemy.length
	mD = state_of_dist closest_mine.length
	tD = state_of_dist closest_tavern.length
	
	#key is index for state value hash table
	key = myL + myW + eL + eD + eW + mD + tD
	
	move_choice = @hashTable[key]
	
	r = Random.new
	rNext = r.rand
	if rNext < 1.0 - @greed
		next_move = move_choice.index(move_choice.max)
	else
		rChoice = r.rand(0..300)
		rSum = move_choice[0]
		i = 0
		while rSum <= rChoice
			rSum += move_choice[i]
			i += 1
		end
		puts i
			next_move = i
	end
	
	
	
	#keep track of actions and states for rewards
	@episode_array << [key, next_move]
	
	case next_move
	when 0
		@path = closest_tavern
		puts "going to tavern"
	when 1
		@path = closest_mine
		puts "going to Mine"
	when 2
		@path = closest_enemy
		puts "going to kill"
	else
		raise "invalide next move"
	end
	
	# Returns second since epoch which includes microseconds
	end_time = Time.now.to_f
	time_taken = end_time - start_time
	puts "time taken in move  = " + time_taken.to_s
	
	follow_path
  end

  def find_flanders
	results = []
	@game.heroes_locs.each do |key, value|
		if key != @hero_no
			hero_pos = [value[1],value[0]]		#switch coordinates
			results << thread_find_paths(@new_map, @position, hero_pos)
		end
	end
	return results
  end
  
  def find_tavern
	results = []
	@game.taverns_locs.each do |locs|
		tavern_pos = [locs[1],locs[0]]		#switch coordinates
		results << thread_find_paths(@new_map, @position, tavern_pos)
	end
	return results
  end
  
  def find_mine
	results = []
	@game.mines_locs.each do |key, value|
		if value != @hero_no					#if not our mine already
			mine_pos = [key[1],key[0]]		#switch coordinates
			results<<thread_find_paths(@new_map, @position, mine_pos)
		end
	end
	return results
  end
  
  def follow_path 		#gets first step of path, converts it into either north, south, west or east
		next_pos = @path[1]	

		if next_pos[0] > @position[0]
			puts "east"
			return "East"
		elsif next_pos[0] < @position[0]
			puts "west"
			return "West"
		end
		
		if next_pos[1]>@position[1]
			puts "south"
			return "South"
		elsif next_pos[1]<@position[1]
			puts "north"
			return "North"
		end
		puts next_pos
		puts "invalid path"
	end
  
  def thread_find_paths map, my_pos, mine_pos 
	new_map = map
	x = mine_pos[0] 
	y = mine_pos[1]
	new_map[y*(@sz+1)+x*2] = "X"
	new_map[y*(@sz+1)+x*2+1] = "X"

	m = TileMap::Map.new(new_map, my_pos, mine_pos, @hero_no) 	
	results = TileMap.a_star_search(m)
	return results
  
  end
  
  def enemy_died?
    if @prev_state.last_enemy_target.life + 51 < @curr_state.last_enemy_target.life
      return true
    end
  end
  def hero_died?
    if @prev_state.life + 51 < @curr_state.life
      return true
    end
  end
  def mine_captured?
  	if @curr_state.mine_count > @prev_state.mine_count
		return true
	end
	if @curr_state.mine_count < @prev_state.mine_count
		return false
	end
	@prev_state.mines_locs.each do |key, value|
		if value == @hero_no && @curr_state.mines_locs[key] != value
			return true
		end
	end
  end
  
  def got_health?
	puts "curr lfe ;" + @curr_state.life.to_s 
	puts "prev life " + @prev_state.life.to_s
    if @curr_state.life -@prev_state.life > 45 && @curr_state.life - @prev_state.life < 55
      return true
    end
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
		case 
		when dist<=1
			return 'c'
		when dist>1&&dist<=3
			return 'm'
		when dist>3 && dist<=5
			return 'f'
		when dist>5
			return 'v'
		else
			raise "invalid enemy dist"
		end
	end
	
	def state_of_dist dist
		case 
		when dist <= 3
			return 'c'
		when dist > 3 && dist<=5
			return 'm'
		when dist >5 && dist <=10
			return 'f'
		when dist > 10
			return 'v'
		else
			raise "invalid dist"
		end
	end
	
	def state_of_wealth mine_count, total_mines
		mine_share = mine_count.to_f/total_mines.to_f*100.0
		
		case mine_share	
		when  0..12.5
			return 'l'
		when 12.6..25.0
			return 'm'
		when 25.1..100
			return 'h'
		else
			raise "invalid wealth"
		end
	end
	
	def calculate_rewards reason
		case reason
		when "mine"
			reward = 5.0
		when "kill"
			reward = 10.0
		when "tavern"
			reward =1.0
		when "died"
			reward = -10.0
		end
		
		values = []
		@episode_array.each do |ep_array|
			values = @hashTable[ep_array[0]]
			sum = 0
			if reward < 0
				sum = (values[ep_array[1]].to_f/100.0)*reward*-1
				values[ep_array[1]] -= sum
				values.each_with_index do |v, i|
					if ep_array[1] != i
						v +=(sum/2)
					end
				end
			else
				values.each_with_index do |v, i|
					if ep_array[1] != i
						sum += (v/100.0)*reward
						v -= (v/100.0)*reward
					end
				end
				values[ep_array[1]] += sum
			end
			@hashTable[ep_array[0]] = values
		end
		@episode_array.clear
	end
  
end