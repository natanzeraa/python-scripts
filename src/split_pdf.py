import os
import fitz
import argparse


parse = argparse.ArgumentParser(
    prog="SPLIT PDF",
    description="Este programa divide seu PDF em várias páginas de acordo com o número disponível.",
    epilog='Run this program by: python spli_pdf.py -D <path to the pdf document>'
)

parse.add_argument('-D', '--document', required=True, type=str, help="Documento PDF que será divido")

args = parse.parse_args()

print(f"Documento recebido: {args.document}")

output_folder = "output"

os.makedirs(output_folder, exist_ok=True)

doc = fitz.open(args.document)

for i in range(len(doc)):
    new_pdf = fitz.open()
    new_pdf.insert_pdf(doc, from_page=i, to_page=i)
    output_file = os.path.join(output_folder, f"pagina_{i + 1}.pdf")
    new_pdf.save(output_file)
    new_pdf.close()

print(f"Processo concluído! PDFs salvos em '{output_folder}'")
