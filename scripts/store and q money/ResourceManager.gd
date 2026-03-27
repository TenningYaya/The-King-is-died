extends Node

signal special_currency_changed(new_amount)

var _special_currency: int = 0

func add_currency(amount: int) -> void:
	if amount <= 0:
		return
		
	_special_currency += amount
	special_currency_changed.emit(_special_currency)
	
	print("[ResourceManager] +", amount, " | current = ", _special_currency)

func spend_currency(amount: int) -> bool:
	if amount <= 0:
		return true
		
	if _special_currency >= amount:
		_special_currency -= amount
		special_currency_changed.emit(_special_currency)
		
		print("[ResourceManager] -", amount, " | current = ", _special_currency)
		return true
	
	print("[ResourceManager] spend failed. Need ", amount, ", current = ", _special_currency)
	return false

func set_currency(amount: int) -> void:
	_special_currency = max(amount, 0)
	special_currency_changed.emit(_special_currency)
	
	print("[ResourceManager] set = ", _special_currency)

func get_currency() -> int:
	return _special_currency
