class Path_Cost
attr_accessor :north, :south, :east, :west

	def initialize life, mine_count, total_mines, size, hero_no
		@north = @south = @east = @west =0.0
		@life = life.to_f
		@mine_count = mine_count.to_f
		@total_mines = total_mines.to_f
		@sz = size
		@hero_no = hero_no
	end
	
	def add_enemy enemies, position, map
		enemies.each do |enemy|
			#@east
			new_pos = [position[0]+1, position[1]]
			if map[new_pos[1]*(@sz+1)+new_pos[0]*2] == " "	#checks that new_pos is valid tile
				path = find_path( map, new_pos, enemy.pos)
				@east = @east + enemy_cost_function(path, enemy)
			end
			
			#@west
			new_pos = [position[0]-1, position[1]]
			if map[new_pos[1]*(@sz+1)+new_pos[0]*2] == " "
				path = find_path( map, new_pos, enemy.pos)
				@west = @west + enemy_cost_function( path, enemy)
			end
			#@south
			new_pos = [position[0], position[1]+1]
			if map[new_pos[1]*(@sz+1)+new_pos[0]*2] == " "
				path = find_path(map, new_pos, enemy.pos)
				@south = @south + enemy_cost_function(path, enemy)
			end
			#@north
			new_pos = [position[0], position[1]-1]
			if map[new_pos[1]*(@sz+1)+new_pos[0]*2] == " "
				path = find_path(map, new_pos, enemy.pos)
				@north = @north + enemy_cost_function(path, enemy)
			end
		end
	end
	
	def find_path map, my_pos, mine_pos
	x = mine_pos[0] 
	y = mine_pos[1]
	map[y*(@sz+1)+x*2] = "X"
	map[y*(@sz+1)+x*2+1] = "X"

	m = TileMap::Map.new(map, my_pos, mine_pos, @hero_no) 	
	results = TileMap.a_star_search(m)
	Thread.current[:output] = results
  
	end
	
	def add_mine mine_path, position
		first_pos = mine_path[1]
		if first_pos[0] > position[0]
			@east = @east + mine_cost_function(mine_path.length)
		elsif first_pos[0] < position[0]
			@west = @west + mine_cost_function(mine_path.length)
		end
		
		if first_pos[1]>position[1]
			@south = @south + mine_cost_function(mine_path.length)
		elsif first_pos[1]<position[1]
			@north = @north + mine_cost_function(mine_path.length)
		end
		
	end
	
	def add_tavern tavern_path, position
		first_pos = tavern_path[1]
		if first_pos[0] > position[0]
			@east = @east + tavern_cost_function(tavern_path.length)
		elsif first_pos[0] < position[0]
			@west = @west + tavern_cost_function(tavern_path.length)
		end
		
		if first_pos[1]>position[1]
			@south = @south + tavern_cost_function(tavern_path.length)
		elsif first_pos[1]<position[1]
			@north = @north + tavern_cost_function(tavern_path.length)
		end
		
	end
	
	def enemy_cost_function path, enemy
		hw = 20
		offset = 5
		
		health_diff = @life - enemy.life
		wealth_diff = enemy.mine_count - @mine_count
		result = (1/path.length)*(health_diff*hw+wealth_diff-offset)
		
		return result
	end
	
	def mine_cost_function dist
		result = (@total_mines/(@mine_count+1))*(1/dist.to_f)*(@life)
		puts "mine cost; " + result.to_s
		return result
	end
	
	def tavern_cost_function dist
		tw = 10.0
		result = tw*@mine_count*(15.0/@life) -0.1* (dist/((5.0/@life.to_f)+@mine_count.to_f))
		puts "tav cost " + result.to_s
		if result < 0
			return 0
		else
		
			return result
		end
	end

end