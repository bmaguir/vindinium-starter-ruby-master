require 'rubygems'
require 'priority_queue'

class String
  # Convenience method so we can iterate over characters easily

  def to_chars
    a = []
    each_byte do |b|
      a << b.chr
    end
    a
  end
end

module TileMap
  # Although start is a plains, its cost is 0

  START  = 0
  PLAINS = 1
  FOREST = 2
  MOUNTAIN = 3
  WATER = nil

  class TilePath < Array
    def initialize(map)
      @map = map
      super([@map.start])
    end

    def cost
      inject(0) {|sum, c| sum + @map.tile(*c) }
    end
  end

  class Map
    attr_reader :start, :goal

    # parse a string contining a tile map into a nested array

    def initialize(map_str, st, gl)
      @tiles = []
	  map_ar = map_str.split(/\n/)
      map_ar.each do |line|
        @tiles << []
		chars = []
        for i in (1.. line.length-3)
			if i % 2 == 0 
				next	#skips odd i
			end
			c = line[i] + line[i+1]
          @tiles.last << case c
                         when "@1"
                           START
                         when "  ", "xx"
                           PLAINS
                         #when "*"
                          # FOREST
                         when "@2","@3","@4"
                           MOUNTAIN
                         when "##", "$-", "[]", "--"
                           WATER
                         else
                           #raise "Invalid tile type"
						   WATER
                         end
          if '@1' == c
            #@start = [@tiles.last.length - 1, @tiles.length - 1]
			@start = st
          elsif 'xx' == c
            #@goal = [@tiles.last.length - 1, @tiles.length - 1]
			@goal = gl
          end
        end
      end
      unless @start && @goal
        raise "Either position or goal tile are not set"
      end
    end

	def get_tiles()
		return @tiles
	end
	
    def tile(x, y)
      @tiles[y][x]
    end

    def move_choices(x, y)
      if tile(x, y) == WATER
        raise "Illegal tile"
      end
      choices = []
	  (-1..1).each do |i|
		ypos = y + i
		if ypos >= 0 && ypos < @tiles.length
			new_position = [x, ypos]
			if new_position != [x, y] && tile(*new_position) != WATER
				choices << new_position
			end
		end
	  end
	  
	  	(-1..1).each do |i|
			xpos = x + i
			if xpos >= 0 && xpos < @tiles.length
				new_position = [xpos, y]
				if new_position != [x, y] && tile(*new_position) != WATER
					choices << new_position
				end
			end
		end
      choices
    end

    def self.manhattan(point1, point2)
      ((point2[0] - point1[0]) + (point2[1] - point1[1])).abs
    end
  end

  def self.a_star_search(map)
    # To store points we have already visited, so we don't repeat ourselves
    closed = []
    open = PriorityQueue.new
    # Start off the queue with one path, which will contain the start position
    open.push TilePath.new(map), 0
    while ! open.empty?
      # Get the path with the best cost to expand

      current_path = open.delete_min_return_key
      pos = current_path.last
      unless closed.include?(pos)
        if pos == map.goal
          return current_path
        end
        closed << pos
        # Create new paths and add them to the priority queue

        map.move_choices(*pos).each do |p|
          heuristic = Map.manhattan(p, map.goal)
          new_path = current_path.clone << p
          open.push(new_path, new_path.cost + heuristic)
        end
      end
    end
    raise "Cannot be solved"
  end
end

=begin

@m = TileMap::Map.new(File.read('vindinium_map.txt'), [5,5], [5,19], 40)
results = TileMap.a_star_search(@m)
puts results.map! {|pos| pos.join(",") }.join("  ")

r = []
for i in (0 .. results.length-1)
	r[i] = results[i].split(/,/)
end

t = @m.get_tiles
for i in (0 .. t.length-1)
	for j in (0 .. t[i].length)
		if t[i][j] == nil
			print "#"
		else
			for p in (0 .. results.length-1)
				if r[p][0].to_i == j && r[p][1].to_i == i
					t[i][j] = 8
				end
			end
			print t[i][j]
		end
	end
	puts
end

=end