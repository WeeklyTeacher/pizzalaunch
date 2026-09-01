local CustomerDialogue = {}

local COMMON = {
	greeting = {
		"A hot cheese pizza would be perfect.",
		"I came in from the street because it smells amazing.",
	},
	waiting = {
		"I am ready when you are, chef.",
		"My table is clear for landing.",
	},
	happy = {
		"That landing was amazing. Thank you!",
		"Hot, cheesy, and right on target!",
	},
	wrong = {
		"Whoa! Close one. I am okay!",
		"Funny landing. Let us try that again.",
	},
	leaving = {
		"That was delicious. See you next shift!",
		"Thanks, chef. I will tell my friends!",
	},
}

local PERSONALITIES = {
	Mia = {
		greeting = "I am starving. Can you land one at my table?",
		waiting = "Extra cheese, please. I saved plenty of room.",
		happy = "Perfect! That pizza found the hungriest customer.",
		wrong = "My tummy says that one took a surprising detour.",
		leaving = "Full at last. I will be back tomorrow!",
	},
	Bo = {
		greeting = "That launcher looks wild, but I trust you!",
		waiting = "No rush. Give me your smoothest landing.",
		happy = "Cool shot, chef. That was buttery smooth.",
		wrong = "All good. Even pizza needs an adventure.",
		leaving = "Great vibes and great pizza. Later, chef!",
	},
	Ziggy = {
		greeting = "Send mine sky-high. I want the full show!",
		waiting = "I am watching the cannon. Make it soar!",
		happy = "Yes! Best flying-pizza moment ever!",
		wrong = "Whoa, that was exciting. One more try!",
		leaving = "What a show! I am bringing everyone next time.",
	},
	Pip = {
		greeting = "Extra crispy, please. I am counting on you!",
		waiting = "I can smell the crust from over here.",
		happy = "Crunchy edge, melty middle. Perfect!",
		wrong = "Almost! My napkin caught most of the drama.",
		leaving = "That crispy slice made my whole day.",
	},
	Nana = {
		greeting = "Take a steady aim, dear. I can wait.",
		waiting = "A careful landing is worth a little patience.",
		happy = "Lovely work. You have a real gift.",
		wrong = "No harm done, dear. Try once more.",
		leaving = "Warm pizza and kind service. Thank you.",
	},
	Max = {
		greeting = "Show me your cleanest restaurant-quality launch.",
		waiting = "I am judging the arc and the crust.",
		happy = "Excellent trajectory and excellent cheese coverage.",
		wrong = "Interesting technique. Let us call it experimental.",
		leaving = "Expert verdict: I would order that again.",
	},
	Lulu = {
		greeting = "Make mine fly funny. Pizza should be silly!",
		waiting = "I bet the cheese wiggles in the air.",
		happy = "That landing made me laugh and cheer!",
		wrong = "Ha! The pizza tried to sit somewhere else.",
		leaving = "My cheeks hurt from smiling. Bye, chef!",
	},
	Kai = {
		greeting = "I have my catching hands ready, chef!",
		waiting = "Table clear. Eyes up. Ready for pizza.",
		happy = "Caught it! That was an all-star delivery.",
		wrong = "Good dodge! Reset and send the next one.",
		leaving = "Great teamwork. Catch you next shift!",
	},
	Sunny = {
		greeting = "A bright, cheesy slice would make my day.",
		waiting = "I am ready for a little pizza sunshine.",
		happy = "That was a perfect ray of cheesy sunshine!",
		wrong = "Cloudy landing, but I am still smiling.",
		leaving = "Delicious! Have a sunny rest of your shift.",
	},
	Rex = {
		greeting = "I could eat a pizza-shaped comet right now!",
		waiting = "Big hunger, clear table, ready for impact.",
		happy = "Now that was a mighty pizza landing!",
		wrong = "Ha! That pizza nearly defeated me.",
		leaving = "Hunger conquered. Rex out!",
	},
	Bea = {
		greeting = "Does flying make pizza tastier? Let us test it.",
		waiting = "I am studying the launch angle very carefully.",
		happy = "Experiment complete: flying pizza is delicious!",
		wrong = "Unexpected result. We should test another pizza.",
		leaving = "I learned a lot, especially about cheese.",
	},
	Nico = {
		greeting = "My tummy is drumming. Please launch soon!",
		waiting = "I am trying to be patient, but it smells so good.",
		happy = "Finally! Worth every hungry second.",
		wrong = "Oh no! My tummy demands a quick retry.",
		leaving = "Tummy happy. Nico happy. Thanks, chef!",
	},
}

function CustomerDialogue.getPool(customerName: string, category: string): { string }
	local common = COMMON[category] or COMMON.waiting
	local profile = PERSONALITIES[customerName]
	local result = table.clone(common)
	if profile and profile[category] then
		table.insert(result, profile[category])
	end
	return result
end

function CustomerDialogue.get(customerName: string, category: string): string
	local pool = CustomerDialogue.getPool(customerName, category)
	return pool[math.random(1, #pool)]
end

function CustomerDialogue.hasCompleteProfile(customerName: string): boolean
	local profile = PERSONALITIES[customerName]
	if not profile then
		return false
	end
	for _, category in { "greeting", "waiting", "happy", "wrong", "leaving" } do
		if not profile[category] then
			return false
		end
	end
	return true
end

return CustomerDialogue
