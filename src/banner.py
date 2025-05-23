import pyfiglet
import argparse

parser = argparse.ArgumentParser(
    prog='Banner Generator',
    description='Generates ASCII Art for your scripts!',
    epilog='Run this program by: python banner.py -T "Your Banner Text"'
)

parser.add_argument('-T', '--text', type=str, required=True, help="Text to convert into ASCII Art")

args = parser.parse_args()

banner = pyfiglet.figlet_format(args.text)
print(banner)
