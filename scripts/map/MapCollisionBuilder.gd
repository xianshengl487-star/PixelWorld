extends RefCounted
class_name MapCollisionBuilder
## MapCollisionBuilder.gd — 地图碰撞体生成器
## 为障碍瓦片创建 StaticBody2D 碰撞体

# 不可通行的瓦片类型
const BLOCKING_TILES: Array = [2, 3, 4, 5]  # TREE, WATER, HOUSE, MOUNTAIN


## 为地图数据创建碰撞体
## @param map_data: Dictionary — { tiles, walkable, width, height }
## @param tile_size: int — 瓦片像素尺寸
## @param parent_node: Node2D — 碰撞体的父节点
## @return int — 创建的碰撞体数量
func build_collisions(map_data: Dictionary, tile_size: int, parent_node: Node2D) -> int:
	var tiles = map_data.get("tiles", [])
	var count: int = 0
	
	if tiles.size() == 0:
		return 0
	
	var height = tiles.size()
	var width = 0
	if height > 0:
		width = tiles[0].size()
	
	for y in range(height):
		for x in range(width):
			var tile_type = tiles[y][x]
			if tile_type in BLOCKING_TILES:
				var body = StaticBody2D.new()
				body.position = Vector2(
					x * tile_size + tile_size / 2.0,
					y * tile_size + tile_size / 2.0
				)
				
				var shape = CollisionShape2D.new()
				var rect_shape = RectangleShape2D.new()
				rect_shape.size = Vector2(tile_size, tile_size)
				shape.shape = rect_shape
				
				body.add_child(shape)
				parent_node.add_child(body)
				count += 1
	
	return count
