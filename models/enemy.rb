class Enemy
attr_accessor :life, :mine_count, :pos

	def initialize life, mine_count, pos
		@life = life
		@mine_count = mine_count
		@pos = pos
	end

end