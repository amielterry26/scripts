# Logic
# You have to be further than 50 feet from the car.
# You must press the lock button twice to initiate remote start function

import random

clicks = random.randint(1, 3)
distance = random.randint(0, 250)


if clicks > 1:
    print(f"{clicks} clicks occurred, remote start has been initiated.")
    if distance < 50:
        print(f"You are {distance}ft from the car, remote start has been cancelled.")
    elif distance > 150:
        print(f"You are {distance}ft away, you are too far from the car.")
    else:
        print(f"You are {distance}ft away from the car, remote start successful.")
else:
    print(f"You clicked the lock button {clicks} time, at least 2 clicks are required. Try again.")

