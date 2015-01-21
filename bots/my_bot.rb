
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
	if @life >= 95
		@healing = false
	end
	
	#puts "hero munber = "+ state["hero"]["id"].to_s
    @game = Game.new state
	#next_mine state, @game.heroes_locs, @game.mines_locs
	my_pos = [ @game.heroes_locs[@hero_no][1], @game.heroes_locs[@hero_no][0]]
	@position = my_pos
	
	#if @path.e@mpty?		#find next closest mine
	@threads = []
	
	@mp = state['game']['board']['tiles']		#get map and line size from state
	@sz = state['game']['board']['size']
	@sz = @sz*2
	@new_map = ""
	(0..@mp.length - 1).step(@sz).each do |i|		#add \n to get split in find path
		@new_map << @mp[i..i+(@sz-1)].to_s + "\n"
	end
	
	if @life < 50 || @healing
		puts "I'm dayyyyunnnnn"
		@healing = true
		find_tavern
	else
		if state['hero']['mineCount'] < 1
			find_mine
		else
			find_flanders
		end
	end
	
	if @thread_results.empty?
		find_tavern
	end
	
	min = @thread_results[0].length		#find the shortest path to a mine
	@path = @thread_results[0]
	@thread_results.each do |r|
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
	@game.heroes_locs.each do |key, value|
		if key != @hero_no
			hero_pos = [value[1],value[0]]		#switch coordinates
			@threads<< Thread.new{thread_find_paths(@new_map, @position, hero_pos)}
		end
	end
	
	@thread_results = []
	@threads.each do |t|
		t.join
		@thread_results <<  t[:output]
	end
  end
  
  def find_tavern
	puts "Gettin that life Bitch!"
	@game.taverns_locs.each do |locs|
		tavern_pos = [locs[1],locs[0]]		#switch coordinates
		@threads<< Thread.new{thread_find_paths(@new_map, @position, tavern_pos)}
	end
	
	@thread_results = []
	@threads.each do |t|
		t.join
		@thread_results <<  t[:output]
	end
  end
  
  def find_mine
	@game.mines_locs.each do |key, value|
		if value != @hero_no					#if not our mine already
			mine_pos = [key[1],key[0]]		#switch coordinates
			@threads<< Thread.new{thread_find_paths(@new_map, @position, mine_pos)}
		end
	end
	@thread_results = []
	@threads.each do |t|
		t.join
		@thread_results <<  t[:output]
	end
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

	m = TileMap::Map.new(map, my_pos, mine_pos) 	
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