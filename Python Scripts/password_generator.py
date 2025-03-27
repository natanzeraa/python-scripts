import random
import string
import argparse


parser = argparse.ArgumentParser(
    prog="Password Generator",
    description="This program generates random passwords based on user specifications.",
    epilog='Run this program by: python password_generator.py -L <password length> -N <min number amount> -S <min special chars amount>'

)

parser.add_argument('-L', '--length', type=int, required=True, help="Password length")
parser.add_argument('-N', '--number', type=int, required=False, default=0, help="Amount of numbers required for the password")
parser.add_argument('-S', '--special', type=int, required=False, default=0, help="Amount of special characters required for the password")

args = parser.parse_args()

numbers = string.digits
letters = list(string.ascii_letters)
special_chars = string.punctuation

password = []


if args.length >= 8:

    if args.number is not None and args.special is not None and (args.number + args.special) > args.length:
        print("A quantidade de números e caracteres especiais não pode exceder o comprimento da senha")
        exit(1)

    if args.number is not None and args.number >= args.length:
        print("A quantidade de números não pode exceder o comprimento da senha")
        exit(1)

    if args.special is not None and args.special >= args.length:
        print("A quantidade de caracteres especiais não pode exceder o comprimento da senha")
        exit(1)

    password.extend(random.choices(numbers, k=args.number))
    password.extend(random.choices(special_chars, k=args.special))

    remaining_length = args.length - len(password)
    password.extend(random.choices(letters, k=remaining_length))

    random.shuffle(password)
    result = ''.join(password)

    print(f"A senha gerada foi: {result}")
else:
    print("A senha deve ter no mínimo 8 caratéres")
    exit(1)
