class_name EnemyData extends Resource

@export var health : int = 10
@export var damage : int = 5
@export var element : Element

enum Element
{
	Fire,
	Water,
	Earth,
	Thunder,
	Air,
	Ice
}
