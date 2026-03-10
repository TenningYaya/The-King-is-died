# ResourceManager.gd (Autoload)
extends Node

signal special_currency_changed(new_amount)

var special_currency: int = 0:
	set(value):
		special_currency = value
		special_currency_changed.emit(special_currency)

func add_currency(amount: int):
	special_currency += amount

func spend_currency(amount: int) -> bool:
	if special_currency >= amount:
		special_currency -= amount
		return true # 购买成功
	return false # 钱不够
