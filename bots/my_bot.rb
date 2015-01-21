
class MyBot < BaseBot

	def initialize
		@path = Array.new
		@position = []
		@hero_no = "1"
	end

  def move state
    game = Game.new state
	#next_mine state, game.heroes_locs, game.mines_locs
	my_pos = [ game.heroes_locs[@hero_no][1], game.heroes_locs[@hero_no][0]]
	@position = my_pos
	if @path.empty?
		threads = []
		
		mp = state['game']['board']['tiles']
		sz = state['game']['board']['size']
		sz = sz*2
		new_map = ""
		(0..mp.length - 1).step(sz).each do |i|
			new_map << mp[i..i+(sz-1)].to_s + "\n"
		end
		#for each mine, finds the shortest path to it
		game.mines_locs.each do |key, value|
			mine_pos = [key[1],key[0]]
			threads<< Thread.new{thread_find_paths(new_map, sz, my_pos, mine_pos)}
		end
		
		thread_results = []
		threads.each do |t|
			t.join
			#puts t[:output]
			thread_results <<  t[:output]
		end
		
		#thread_results.sort_by{|s| s.length }[0]
		@path = thread_results[0]
		#puts thread_results[0]
	end

	follow_path
  end

  def follow_path 
	next_pos = @path[0]
	@path.delete_at(0)
	
	puts next_pos[0].to_s + " , " + next_pos[1].to_s + " my pos = " + @position[0].to_s + " , " + @position[0].to_s
	
	if next_pos[0] > @position[0]
		puts "east"
		return "East"
	elsif next_pos[0] < @position[0]
		puts "west"
		return "West"
	end
	
	if next_pos[1]>@position[1]
		puts "north"
		return "North"
	elsif next_pos[1]<@position[1]
		puts "south"
		return "South"
	end
	end
  
  def next_mine state, heroes, mines
	mp = state['game']['board']['tiles']
	sz = state['game']['board']['size']
	sz = sz*2
	new_map = ""
	(0..mp.length - 1).step(sz).each do |i|
		new_map << mp[i..i+(sz-1)].to_s + "\n"
	end
	y = 4
	x = 0
	new_map[y*(sz+1)+x] = "X"
	new_map[y*(sz+1)+x+1] = "X"
	puts "------------------\n" + new_map + "\n-------------------"
	
#=begin
	mines.each do |key, value|
		m = TileMap::Map.new(new_map,[ heroes["1"][1], heroes["1"][0]], [key[1],key[0]]) 	
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
  
  def thread_find_paths map, sz, my_pos, mine_pos 
	x = mine_pos[0] 
	y = mine_pos[1]
	map[y*(sz+1)+x*2] = "X"
	map[y*(sz+1)+x*2+1] = "X"

	m = TileMap::Map.new(map, my_pos, mine_pos) 	
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
	
	Thread.current[:output] = results
  
  end
  
  
end