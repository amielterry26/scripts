# This will be a script to generate random and secure passwords.

import random
import string

length = random.randint(8, 15)
password = ''.join(random.choices(string.punctuation + string.hexdigits, k=length))

print(password)
print(f"Your password is {length} characters.")

