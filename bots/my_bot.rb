
class MyBot < BaseBot

	def initialize
		@path = Array.new
		@position = [0,0]
		@hero_no = "1"
		@life = 100
		@healing = false 
	end

  def move state  
	@hero_no = state["hero"]["id"].to_s
	@life =  state["hero"]["life"]
	@mineCount = state['hero']['mineCount']
	if @life >= 95
		@healing = false
	end
    @game = Game.new state
	
	my_pos = [ @game.heroes_locs[@hero_no][1], @game.heroes_locs[@hero_no][0]]
	@position = my_pos
	
	@threads = []
	
	@mp = state['game']['board']['tiles']		#get map and line size from state
	@sz = state['game']['board']['size']
	@sz = @sz*2
	@new_map = ""
	(0..@mp.length - 1).step(@sz).each do |i|		#add \n to get split in find path
		@new_map << @mp[i..i+(@sz-1)].to_s + "\n"
	end
	
	path_cost = Path_Cost.new(@life, @mineCount, @game.mines_locs.length, @sz, @hero_no)
	
	tavern_paths = []
	tavern_paths = find_tavern
	tavern_paths.each do |tp|
		path_cost.add_tavern(tp, @position)
	end

	mine_paths = []
	mine_paths = find_mine
	mine_paths.each do |mp|
		path_cost.add_mine(mp, @position)
	end

	enemies =[]
	@game.heroes_locs.each do |key, value|
		if key != @hero_no
			hero_pos = [value[1],value[0]]		#switch coordinates
			l =  state["game"]["heroes"][key.to_i-1]["life"]
			mC =  state["game"]["heroes"][key.to_i-1]["mineCount"]
			enemies<< Enemy.new(l, mC, hero_pos)
		end
	end
	
	path_cost.add_enemy(enemies, @position, @new_map)
	
	puts "North: " + path_cost.north.to_s
	puts "South: " + path_cost.south.to_s
	puts "East: " + path_cost.east.to_s
	puts "West: " + path_cost.west.to_s
	
#=end
	thread_results = []
	
	if @life < 50 || @healing
		puts "I'm dayyyyunnnnn"
		@healing = true
		thread_results = find_tavern
	else
		if state['hero']['mineCount'] < 1
			puts "more mines!"
			thread_results = find_mine
		else
			thread_results = find_flanders
		end
	end
	
	if thread_results.empty?
		puts "no more mines"
		find_tavern
	end
	puts thread_results.length
	min = thread_results[0].length		#find the shortest path to a mine
	@path = thread_results[0]
	thread_results.each do |r|
		if r.length < min
			min = r.length
			@path = r
		end
	end
	@path.delete_at(0)		#removes current position
	#end
	puts @life
	follow_path
  end

  def find_flanders
	threads =[]
	@game.heroes_locs.each do |key, value|
		if key != @hero_no
			hero_pos = [value[1],value[0]]		#switch coordinates
			threads<< Thread.new{thread_find_paths(@new_map, @position, hero_pos)}
		end
	end
	
	results = []
	threads.each do |t|
		t.join
		results <<  t[:output]
	end
	return results
  end
  
  def find_tavern
	puts "Gettin that life Bitch!"
	threads =[]
	@game.taverns_locs.each do |locs|
		tavern_pos = [locs[1],locs[0]]		#switch coordinates
		threads<< Thread.new{thread_find_paths(@new_map, @position, tavern_pos)}
	end
	
	results = []
	threads.each do |t|
		t.join
		results <<  t[:output]
	end
	return results
  end
  
  def find_mine
  puts "gettig them minezzzzz"
	threads =[]
	@game.mines_locs.each do |key, value|
		if value != @hero_no					#if not our mine already
			mine_pos = [key[1],key[0]]		#switch coordinates
			threads<< Thread.new{thread_find_paths(@new_map, @position, mine_pos)}
		end
	end
	results = []
	threads.each do |t|
		t.join
		results <<  t[:output]
	end
	return results
  end
  
  def follow_path 
	next_pos = @path[0]
	@path.delete_at(0)
	
	#puts next_pos[0].to_s + " , " + next_pos[1].to_s + " my pos = " + @position[0].to_s + " , " + @position[1].to_s
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
	end
  
  def next_mine state, heroes, mines
	@mp = state['@game']['board']['tiles']
	@sz = state['@game']['board']['size']
	@sz = @sz*2
	@new_map = ""
	(0..@mp.length - 1).step(@sz).each do |i|
		@new_map << @mp[i..i+(@sz-1)].to_s + "\n"
	end
	y = 4
	x = 0
	@new_map[y*(@sz+1)+x] = "X"
	@new_map[y*(@sz+1)+x+1] = "X"
	puts "------------------\n" + @new_map + "\n-------------------"
	
#=begin
	mines.each do |key, value|
		m = TileMap::Map.new(@new_map,[ heroes["1"][1], heroes["1"][0]], [key[1],key[0]]) 	
		results = TileMap.a_star_search(m)
		t = m.get_tiles
		for i in (0 .. t.length-1)
			for j in (0 .. t[i].length)
				if t[i][j] == nil
					print "#"
				else
					for p in (0 .. results.length-1)
						if results[p][0].to_i == j && results[p][1].to_i == i
							t[i][j] = 8
						end
					end
					print t[i][j]
				end
			end
			puts
		end
		puts
	end
#=end

  end
  
  def thread_find_paths map, my_pos, mine_pos 
	x = mine_pos[0] 
	y = mine_pos[1]
	map[y*(@sz+1)+x*2] = "X"
	map[y*(@sz+1)+x*2+1] = "X"

	m = TileMap::Map.new(map, my_pos, mine_pos, @hero_no) 	
	results = TileMap.a_star_search(m)
=begin
	t = m.get_tiles
		for i in (0 .. t.length-1)
			for j in (0 .. t[i].length)
				if t[i][j] == nil
					print "#"
				else
					for p in (0 .. results.length-1)
						if results[p][0].to_i == j && results[p][1].to_i == i
							t[i][j] = 8
						end
					end
					print t[i][j]
				end
			end
			puts
		end
		puts
=end
	Thread.current[:output] = results
  
  end
  
  
end