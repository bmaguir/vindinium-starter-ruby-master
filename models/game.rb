class Game

  attr_accessor :state, :board, :heroes, :mines_locs, :heroes_locs, :taverns_locs, :life, :mine_count, :hero_no

  def initialize state
 
    self.state = state
    puts "Turn #{state['game']['turn'] / 4}"
    self.board = Board.new state['game']['board']
    self.mines_locs = {}
    self.heroes_locs = {}
    self.taverns_locs = []
    self.heroes = []
	self.life = state["hero"]["life"]
	self.mine_count =state['hero']['mineCount']
	self.hero_no = state["hero"]["id"].to_s

    state['game']['heroes'].each do |hero|
      self.heroes << Hero.new(hero)
    end

    self.board.tiles.each_with_index do |row, row_idx|

      row.each_with_index do |col, col_idx|
        # what kinda tile?
        obj = col 
        if obj.is_a? MineTile
          self.mines_locs[[row_idx, col_idx]] = obj.hero_id
		  #self.mines_locs[obj.hero_id] = [row_idx, col_idx]
        elsif obj.is_a? HeroTile
          #self.heroes_locs[[row_idx, col_idx]] = obj.hero_tile_id
		  self.heroes_locs[obj.hero_tile_id] = [row_idx, col_idx]
        elsif obj == TAVERN
          self.taverns_locs << [row_idx, col_idx]
        end

      end

    end

  end

end
